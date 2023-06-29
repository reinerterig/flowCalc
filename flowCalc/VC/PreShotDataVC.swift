//
//  PreShotDataVC.swift
//  flowCalc
//
//  Created by reinert wasserman on 29/6/2023.
//

import UIKit

class PreShotDataVC: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate {
    
    
    @IBOutlet weak var dosePicker: UIPickerView!
    @IBOutlet weak var grindSizePicker: UIPickerView!
    @IBOutlet weak var rpmPicker: UIPickerView!
    @IBOutlet weak var preWetSwitch: UISwitch!
    
    var doseValues: [Double] = Array(stride(from: 0.0, to: 24.0, by: 0.1))
    var grindSizeValues: [Double] = Array(stride(from: 1.0, to: 40.0, by: 0.1))
    var rpmValues: [Int] = Array(stride(from: 600, to: 1800, by: 100))
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        dosePicker.dataSource = self
        dosePicker.delegate = self
        
        grindSizePicker.dataSource = self
        grindSizePicker.delegate = self
        
        rpmPicker.dataSource = self
        rpmPicker.delegate = self
        
        // Set default values
        Recipy.pre.dose         = 17
        Recipy.pre.grindSize    = 15
        Recipy.pre.rpm          = 1100
        Recipy.pre.preWet       = false
        
        // Update UI to reflect default values
        preWetSwitch.isOn = Recipy.pre.preWet!
        
        if let doseIndex = doseValues.firstIndex(where: { abs($0 - Recipy.pre.dose!) < 0.05 }) {
            dosePicker.selectRow(doseIndex, inComponent: 0, animated: false)
        }
        
        if let grindSizeIndex = grindSizeValues.firstIndex(where: { abs($0 - Recipy.pre.grindSize!) < 0.05 }) {
            grindSizePicker.selectRow(grindSizeIndex, inComponent: 0, animated: false)
        }
        
        if let rpmIndex = rpmValues.firstIndex(of: Int(Recipy.pre.rpm!)) {
            rpmPicker.selectRow(rpmIndex, inComponent: 0, animated: false)
        }
    }
    override func viewWillAppear(_ animated: Bool) {
        let delegate = UIApplication.shared.delegate as! AppDelegate
        delegate.orientationLock = .landscape
        
    }
    override func viewDidDisappear(_ animated: Bool) {
        
        let delegate = UIApplication.shared.delegate as! AppDelegate
        delegate.orientationLock = .all
        
    }
    
    // UIPickerView DataSource and Delegate methods
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if pickerView == dosePicker {
            return doseValues.count
        } else if pickerView == grindSizePicker {
            return grindSizeValues.count
        } else if pickerView == rpmPicker {
            return rpmValues.count
        }
        return 0
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if pickerView == dosePicker {
            return String(format: "%.1f", doseValues[row])
        } else if pickerView == grindSizePicker {
            return String(format: "%.1f", grindSizeValues[row])
        } else if pickerView == rpmPicker {
            return String(rpmValues[row])
        }
        return ""
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if pickerView == dosePicker {
                    Recipy.pre.dose = doseValues[row]
        } else if pickerView == grindSizePicker {
            Recipy.pre.grindSize = grindSizeValues[row]
        } else if pickerView == rpmPicker {
            Recipy.pre.rpm! = Double(rpmValues[row])
        }
    }
    @IBAction func onButtonNext(_ sender: UIButton) {
        performSegue(withIdentifier: "toTampCam", sender: self)
    }
    
    @IBAction func preWetSwitchChanged(_ sender: UISwitch) {
        Recipy.pre.preWet! = sender.isOn
    }
}
