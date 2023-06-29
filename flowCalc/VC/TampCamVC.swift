//
//  TampCamVC.swift
//  flowCalc
//
//  Created by reinert wasserman on 29/6/2023.
//

import UIKit

class TampCamVC: UIViewController {
    
    var tampImage: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)

        }

        override func viewWillDisappear(_ animated: Bool) {
            super.viewWillDisappear(animated)

        }
    
    
    override func viewDidAppear(_ animated: Bool) {
        
        if tampImage == nil {
            let picker = UIImagePickerController()
            picker.sourceType = .camera
            picker.delegate = self
            present(picker, animated: true)
        } else if tampImage != nil {
            performSegue(withIdentifier: "imageToChart", sender: self)
        }
    }

    

}

extension TampCamVC: UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        guard let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else{
            return
        }
        tampImage = image
       }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        print("Preparing Seque")
        if segue.identifier == "imageToChart",
           let destinationVC = segue.destination as? ChartVC,
           let senderVC = sender as? TampCamVC {
            destinationVC.receivedImage = senderVC.tampImage
        }
    }

}


