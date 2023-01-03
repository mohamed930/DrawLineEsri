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
        hexColorCode = picker.color.hexStringFromColor()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
    
    @IBAction func SignupOperation() {
        CheckLicienceNumber()
    }
    
    
    func CheckLicienceNumber() {
        firebase.SetRefernce(ref: Database.database().reference().child("users"))
        
        firebase.observeDataWithoutListnerWithCondition(k: "licenceNumber", v: carlicenceNumber.text!) { [weak self] snapshot in
            guard let self = self else { return }
            
            if snapshot.exists() {
                let alert = UIAlertController(title: "تنبيه", message: "رقم الرخصه مستخدم بالفعل", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "تمت", style: .cancel))
                self.present(alert, animated: true)
            }
            else {
                self.CreateAccount()
                
            }
        }
    }
    
    func CreateAccount() {
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
    

}
