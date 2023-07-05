//
//  ServoCalVC.swift
//  flowCalc
//
//  Created by reinert wasserman on 4/7/2023.
//

import UIKit
import AcaiaSDK

class ServoCalVC: ViewController {
    
    
    var flowrate: Double = 0
    var knobMax: Float!
    var knobMin: Float!
    var maxSaved: Bool = false
    var minSaved: Bool = false
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateServoPosition), name: NSNotification.Name(rawValue: "CurrentServoPositionChanged"), object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(updateSmoothedFlowRate), name: NSNotification.Name(rawValue: "SmoothedFlowRateChanged"), object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(_onWeight),
                                               name: .init(rawValue: AcaiaScaleWeight),
                                               object: nil)

    }
    
    @objc func updateSmoothedFlowRate(notification: NSNotification) {
        if let userInfo = notification.userInfo, let rate = userInfo["value"] as? Double {
            flowrate = rate
//            print("Smoothed Flow Rate: \(rate)")
            flowLabel.text = String(rate)
            // update your table here
        }
    }
    
    @objc private func _onWeight(notification: NSNotification) {
        let weight = notification.userInfo![AcaiaScaleUserInfoKeyWeight]! as! Float
    
        if weight > 4 && maxSaved != true {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1){
//                self.findMaxflow()
            }
        }
        
        
    }
    
    
    func findMaxflow() {
        let flow = flowrate
        let currentPosition = BrevilleManager.shared.currentServoPosition ?? 0.0
        let newPosition = currentPosition + 5.0
        BrevilleManager.shared.writeServoPosition(newPosition)
        
        if flow < 40 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                if self.maxSaved != true{
                    self.increaseServoPosition()
                    print(String(self.maxSaved))
                }
            }
        } else {
            maxSaved = true
            print(String(maxSaved))
        }
        
    }
    
    
    
    @objc func updateServoPosition(notification: NSNotification) {
        if let userInfo = notification.userInfo, let servoPosition = userInfo["value"] as? Float {
            print("Current Servo Position: \(servoPosition)")
            ServoPostion.text = String(servoPosition)
            if minSaved == false{
                let value = String(servoPosition)
                MinLabel.text = "Max: " + value
            }
            if maxSaved == false{
                let value = String(BrevilleManager.shared.currentServoPosition!)
                MaxLabel.text = "Max: " + value
            }
        }
    }
    
    @IBOutlet weak var ServoPostion: UILabel!
    @IBOutlet weak var MaxLabel: UILabel!
    
    @IBOutlet weak var flowLabel: UILabel!
    @IBOutlet weak var MinLabel: UILabel!
    
    @IBAction func onUp(_ sender: UIButton) {
        increaseServoPosition()
    }
    
    func increaseServoPosition() {
        let currentPosition = BrevilleManager.shared.currentServoPosition ?? 0.0
        let newPosition = currentPosition + 5
        BrevilleManager.shared.writeServoPosition(newPosition)
        
        if newPosition < 180 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.increaseServoPosition()
            }
        }
        
    }

    
    
    @IBAction func onDown(_ sender: UIButton) {
        decreaseServoPosition()
    }

    func decreaseServoPosition() {
        let currentPosition = BrevilleManager.shared.currentServoPosition ?? 0.0
        let newPosition = currentPosition - 5
        BrevilleManager.shared.writeServoPosition(newPosition)
        
        if newPosition > 30 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.decreaseServoPosition()
            }
        }
        
    }
    @IBAction func onSaveMax(_ sender: UIButton) {
        if maxSaved != true {
            maxSaved = true
        } else {
            maxSaved = false
        }
    }
    
    @IBAction func onSaveMin(_ sender: UIButton) {
        if minSaved != true {
            minSaved = true
        } else {
            minSaved = false
        }
    }
}


