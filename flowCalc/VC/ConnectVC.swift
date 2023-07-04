import UIKit
import CoreBluetooth
import AcaiaSDK

class ConnectVC: UITableViewController {
    private var timerForConnectTimeOut: Timer?
    private var arduinoPeripherals = [CBPeripheral]()
    private var acaiaScales = [AcaiaScale]()
    private var arduinoConnected = false
    private var acaiaConnected = false

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(startScan), for: .valueChanged)
        self.refreshControl = refreshControl

        NotificationCenter.default.addObserver(self, selector: #selector(reloadTableView), name: Notification.Name("reloadTableView"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didConnect), name: NSNotification.Name(AcaiaScaleDidConnected), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didFinishScan), name: NSNotification.Name(AcaiaScaleDidFinishScan), object: nil)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startScan()
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2 // One for Arduino, one for Acaia
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return BrevilleManager.shared.peripherals.count
        case 1: return AcaiaManager.shared().scaleList.count
        default: return 0
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        switch indexPath.section {
        case 0:
            let peripheral = Array(BrevilleManager.shared.peripherals.values)[indexPath.row]
            cell.textLabel?.text = peripheral.name
            if !arduinoConnected {
                BrevilleManager.shared.connectToPeripheral(peripheral)
                arduinoConnected = true
            }
        case 1:
            let scale = AcaiaManager.shared().scaleList[indexPath.row]
            cell.textLabel?.text = scale.name
            if !acaiaConnected {
                scale.connect()
                timerForConnectTimeOut = Timer.scheduledTimer(timeInterval: 10.0,
                                                              target: self,
                                                              selector: #selector(connectTimeOut(_:)),
                                                              userInfo: nil,
                                                              repeats: false)
                acaiaConnected = true
            }
        default:
            break
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case 0:
            let peripheral = Array(BrevilleManager.shared.peripherals.values)[indexPath.row]
            BrevilleManager.shared.connectToPeripheral(peripheral)
            arduinoConnected = true
        case 1:
            let scale = AcaiaManager.shared().scaleList[indexPath.row]
            scale.connect()
            timerForConnectTimeOut = Timer.scheduledTimer(timeInterval: 10.0,
                                                          target: self,
                                                          selector: #selector(connectTimeOut(_:)),
                                                          userInfo: nil,
                                                          repeats: false)
            acaiaConnected = true
        default:
            break
        }
    }

    @objc func startScan() {
        BrevilleManager.shared.startScan(t:0.5)
        AcaiaManager.shared().startScan(0.5)
        self.refreshControl?.endRefreshing()
    }

    @objc func reloadTableView() {
        tableView.reloadData()
    }

    @objc private func didConnect(notification: NSNotification) {
        timerForConnectTimeOut?.invalidate()
        timerForConnectTimeOut = nil
        if arduinoConnected && acaiaConnected {
            performSegue(withIdentifier: "toPreShotData", sender: self)
        }
    }

    @objc private func didFinishScan(notification: NSNotification) {
        tableView.reloadData()
    }

    @objc private func connectTimeOut(_ timer: Timer) {
        AcaiaManager.shared().startScan(0.1)
        let alert = UIAlertController(title: nil, message: "Connect timeout", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .cancel))
        present(alert, animated: true)
    }
}
