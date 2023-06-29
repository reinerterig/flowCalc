//
//  ViewController.swift
//  flowCalc
//
//  Created by reinert wasserman on 20/6/2023.
//

import UIKit
import AcaiaSDK
import SwiftUI
import Charts
import SnapKit

var scaleWeight: String = "0"
var scaleTime: String = "0"

class ViewController: UIViewController {
    
   

    override func viewDidLoad() {
        super.viewDidLoad()
        AcaiaManager.shared().enableBackgroundRecovery = true
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        nextVC()
        _addAcaiaEventsObserver()
            }
    
    
   func nextVC(){
//       if AcaiaManager.shared().connectedScale != nil{
           performSegue(withIdentifier: "segueChartVC", sender: self)
//       } else {
//           performSegue(withIdentifier: "segueConnectToScaleVC", sender: self)
//       }
        
    }
    
    
}

extension ViewController {

    private func _addAcaiaEventsObserver() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(_onConnect(noti:)),
                                               name: .init(rawValue: AcaiaScaleDidConnected),
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(_onDisconnect(noti:)),
                                               name: .init(rawValue: AcaiaScaleDidDisconnected),
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(_onWeight(noti:)),
                                               name: .init(rawValue: AcaiaScaleWeight),
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(_onTimer(noti:)),
                                               name: .init(rawValue: AcaiaScaleTimer),
                                               object: nil)
    }
    
    private func _removeAcaiaEventsObserver() {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: Acaia events
// This should be first IMO
extension ViewController {
 
    @objc private func _onConnect(noti: NSNotification) {
            }
    @objc private func _onFailed(noti: NSNotification) {
        
    }
    
    @objc private func _onDisconnect(noti: NSNotification) {
       
    }
    
    @objc private func _onWeight(noti: NSNotification) {
        let unit = noti.userInfo![AcaiaScaleUserInfoKeyUnit]! as! NSNumber
        let weight = noti.userInfo![AcaiaScaleUserInfoKeyWeight]! as! Float
    
        if unit.intValue == AcaiaScaleWeightUnit.gram.rawValue {
            scaleWeight = String(format: "%.1f", weight)
        } else {
            scaleWeight = String(format: "%.4f", weight)
        }
       // print(String(format: "%.1f g", weight))
       // print(Double(scaleWeight))
        
    }
    
    @objc private func _onTimer(noti: NSNotification) {
        guard let time = noti.userInfo?[AcaiaScaleUserInfoKeyTimer] as? Int else { return }
        scaleTime = String(format: "%02d:%02d", time/60, time%60)
        print(String(format: "%02d", 82%60))
    }
}





