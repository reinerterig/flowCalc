import Foundation
import CoreBluetooth

class BrevilleManager: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    static let shared = BrevilleManager()

    var manager: CBCentralManager!
    var peripherals: [UUID: CBPeripheral] = [:]
    var selectedPeripheral: CBPeripheral?
    var connectedService: CBService?
    
    // Characteristics
    var currentServoPositionCharacteristic: CBCharacteristic?
    var setServoPositionCharacteristic: CBCharacteristic?
    var servoResistanceCharacteristic: CBCharacteristic?
    var powerButtonCharacteristic: CBCharacteristic?
    var brewButtonCharacteristic: CBCharacteristic?
    
    // Properties
    var currentServoPosition: Float? {
        didSet {
            NotificationCenter.default.post(name: NSNotification.Name("CurrentServoPositionChanged"), object: nil, userInfo: ["value": currentServoPosition])
        }
    }
    var setServoPosition: Float?
    var servoResistance: Float?
    var powerButton: Bool?
    var brewButton: Bool?

    private override init() {
        super.init()
        manager = CBCentralManager(delegate: self, queue: nil)
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            startScan(t:0.5)
        } else {
            print("Bluetooth not available.")
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        peripherals[peripheral.identifier] = peripheral
        NotificationCenter.default.post(name: Notification.Name("reloadTableView"), object: nil)
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connected!")
        peripheral.delegate = self
        peripheral.discoverServices(nil)
        NotificationCenter.default.post(name: NSNotification.Name("ArduinoDidConnect"), object: nil)
    }

    func startScan(t: Double) {
        peripherals.removeAll()
        let services = [CBUUID(string: "19B10000-E8F2-537E-4F6C-D104768A1214")]
        manager.scanForPeripherals(withServices: services, options: nil)
        Timer.scheduledTimer(withTimeInterval: t, repeats: false) { _ in
            self.manager.stopScan()
        }
    }


    func connectToPeripheral(_ peripheral: CBPeripheral) {
        selectedPeripheral = peripheral
        manager.connect(selectedPeripheral!, options: nil)
    }

    func disconnectPeripheral() {
        if let peripheral = selectedPeripheral {
            manager.cancelPeripheralConnection(peripheral)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }

        print("Discovered services for peripheral \(peripheral.identifier): \(services.map { $0.uuid })")

        for service in services {
            if service.uuid.uuidString == "19B10000-E8F2-537E-4F6C-D104768A1214" {
                connectedService = service
                peripheral.discoverCharacteristics(nil, for: service)
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        print("Discovered characteristics for service \(service.uuid): \(characteristics.map { $0.uuid })")
        
        for characteristic in characteristics {
            switch characteristic.uuid.uuidString {
            case "19B10010-E8F2-537E-4F6C-D104768A1214":
                currentServoPositionCharacteristic = characteristic
                peripheral.setNotifyValue(true, for: characteristic)
                
                // Read the initial value of the characteristic
                peripheral.readValue(for: characteristic)
                
            case "19B10011-E8F2-537E-4F6C-D104768A1214":
                setServoPositionCharacteristic = characteristic
            case "19B10012-E8F2-537E-4F6C-D104768A1214":
                servoResistanceCharacteristic = characteristic
            case "19B10013-E8F2-537E-4F6C-D104768A1214":
                powerButtonCharacteristic = characteristic
            case "19B10014-E8F2-537E-4F6C-D104768A1214":
                brewButtonCharacteristic = characteristic
            default:
                break
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("Failed to read characteristic value: \(error)")
            return
        }
        
        switch characteristic {
        case currentServoPositionCharacteristic:
            if let valueData = characteristic.value {
                let servoPosition = valueData.withUnsafeBytes { $0.load(as: Float.self) }
                currentServoPosition = servoPosition
                print("Current Servo Position: \(servoPosition)")
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "CurrentServoPositionChanged"), object: nil, userInfo: ["value": servoPosition])
            }
        case setServoPositionCharacteristic:
            if let value = characteristic.value {
                let intValue = value.withUnsafeBytes { $0.load(as: UInt32.self) }
                setServoPosition = Float(intValue) / 10.0
                print("Set Servo Position: \(setServoPosition!)")
            }
        case servoResistanceCharacteristic:
            if let value = characteristic.value {
                let intValue = value.withUnsafeBytes { $0.load(as: UInt32.self) }
                servoResistance = Float(intValue) / 10.0
                print("Servo Resistance: \(servoResistance!)")
            }

        case powerButtonCharacteristic:
            if let value = characteristic.value {
                powerButton = value.withUnsafeBytes { $0.load(as: Bool.self) }
                print("Power Button: \(powerButton!)")
            }
        default:
            break
        }
    }

    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if error != nil {
            print("Error changing notification state: \(error?.localizedDescription ?? "unknown error")")
        }
        
        // Exit if it's not the servo position characteristic
        guard characteristic.uuid.isEqual(currentServoPositionCharacteristic) else {
            return
        }
        
        if (characteristic.isNotifying) {
            print("Notification began on \(characteristic)")
        } else { // Notification has stopped
            // so disconnect from the peripheral
            print("Notification stopped on \(characteristic). Disconnecting")
            manager.cancelPeripheralConnection(peripheral)
        }
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if let error = error {
            print("Failed to disconnect: \(error)")
        } else {
            print("Disconnected!")
        }
    }

    func writeServoPosition(_ position: Float) {
        guard let characteristic = setServoPositionCharacteristic, let peripheral = selectedPeripheral else {
            print("No connected peripheral or set servo position characteristic.")
            return
        }

        var positionToSend = position
        let data = Data(bytes: &positionToSend, count: MemoryLayout<Float>.size)
        peripheral.writeValue(data, for: characteristic, type: .withResponse)
    }



    func writePowerButton(_ state: Bool) {
        guard let characteristic = powerButtonCharacteristic, let peripheral = selectedPeripheral else {
            print("No connected peripheral or power button characteristic.")
            return
        }
        
        var stateCopy = state
        let data = Data(bytes: &stateCopy, count: MemoryLayout<Bool>.size)
        peripheral.writeValue(data, for: characteristic, type: .withResponse)
    }

    func writeBrewButton(_ state: Bool) {
        guard let characteristic = brewButtonCharacteristic, let peripheral = selectedPeripheral else {
            print("No connected peripheral or brew button characteristic.")
            return
        }
        
        var stateCopy = state
        let data = Data(bytes: &stateCopy, count: MemoryLayout<Bool>.size)
        peripheral.writeValue(data, for: characteristic, type: .withResponse)
    }
}
