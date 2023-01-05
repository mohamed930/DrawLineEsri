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
    let storage: LocalStorageProtocol = LocalStorage()

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
    
    @IBAction func BackButtonAction() {
        dismiss(animated: true)
    }
    
    
    func CheckLicienceNumber() {
        firebase.SetRefernce(ref: Database.database().reference().child("users"))
        
        firebase.observeDataWithoutListnerWithCondition(k: "licenceNumber", v: carlicenceNumber.text!) { [weak self] snapshot in
            guard let self = self else { return }
            
            if snapshot.exists() {
                let alert = UIAlertController(title: "تنبيه", message: "رقم الرخصه مستخدم بالفعل", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "تمت", style: .cancel))
                self.present(alert, animated: true)
                
                self.carlicenceNumber.text = ""
                self.carlicenceNumber.becomeFirstResponder()
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
            
            let userlocalmodel = UserlocalModel(telephone: self.data["telephone"] as! String, driverName: self.data["driverName"] as! String, carName: self.data["carType"] as! String, liecenceNumber: self.data["licenceNumber"] as! String, password: self.data["password"] as! String)
            
            self.storage.writeStoreable(key: LocalStorageKeys.user, value: userlocalmodel)
            
            let nextVc = self.storyboard?.instantiateViewController(withIdentifier: "TrackCarViewController") as! TrackCarViewController
            
            nextVc.modalPresentationStyle = .fullScreen
            
            self.present(nextVc, animated: true)
        }
    }
    

}
