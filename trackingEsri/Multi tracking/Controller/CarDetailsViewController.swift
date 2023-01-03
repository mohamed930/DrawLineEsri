//
//  CarDetailsViewController.swift
//  trackingEsri
//
//  Created by Mohamed Ali on 03/01/2023.
//

import UIKit
import Colorful
import FirebaseDatabase

class CarDetailsViewController: UIViewController {
    
    @IBOutlet weak var carDriverLabel:UITextField!
    @IBOutlet weak var carlicenceNumber:UITextField!
    @IBOutlet weak var cartype:UITextField!
    @IBOutlet weak var colorPicker: ColorPicker!
    
    
    var data: [String: Any]!
    var colorSpace: HRColorSpace = .sRGB
    var hexColorCode = ""
    var firebase = Firebase()

    override func viewDidLoad() {
        super.viewDidLoad()

        colorPicker.addTarget(self, action: #selector(self.handleColorChanged(picker:)), for: .valueChanged)
        colorPicker.set(color: UIColor(displayP3Red: 1.0, green: 1.0, blue: 0, alpha: 1), colorSpace: colorSpace)
        handleColorChanged(picker: colorPicker)
    }
    
    @objc func handleColorChanged(picker: ColorPicker) {
        hexColorCode = hexStringFromColor(color: picker.color)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
    
    @IBAction func SignupOperation() {
        let uuid = UUID().uuidString
        firebase.SetRefernce(ref: Database.database().reference().child("users").child(uuid))
        
        data["driverName"] = carDriverLabel.text!
        data["licenceNumber"] = carlicenceNumber.text!
        data["carType"] = cartype.text!
        data["carColor"] = hexColorCode
        
        firebase.write(value: data) { [weak self] in
            guard let self = self else { return }
            
            let alert = UIAlertController(title: "تنبيه", message: "تمت اضافة بيانات السائق بنجاح", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "تمت", style: .cancel))
            self.present(alert, animated: true)
        }
    }
    
    
    func hexStringFromColor(color: UIColor) -> String {
        let components = color.cgColor.components
        let r: CGFloat = components?[0] ?? 0.0
        let g: CGFloat = components?[1] ?? 0.0
        let b: CGFloat = components?[2] ?? 0.0

        let hexString = String.init(format: "#%02lX%02lX%02lX", lroundf(Float(r * 255)), lroundf(Float(g * 255)), lroundf(Float(b * 255)))
        
        return hexString
     }
    

}
