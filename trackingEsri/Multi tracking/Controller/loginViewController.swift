//
//  Car1TrackingViewController.swift
//  trackingEsri
//
//  Created by Mohamed Ali on 03/01/2023.
//

import UIKit
import BCryptSwift
import FirebaseDatabase

class loginViewController: UIViewController {
    
    @IBOutlet weak var titleLabel:UILabel!
    
    @IBOutlet weak var telephoneTextField:UITextField!
    @IBOutlet weak var passwordTextField:UITextField!
    
    @IBOutlet weak var loginButton:UIButton!
    @IBOutlet weak var singupButton:UIButton!
    
    var flag = false
    var firebase = Firebase()
    let storage: LocalStorageProtocol = LocalStorage()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func loginAction (_ sender: Any) {
        if !flag {
            loginOperation()
        }
        else {
            signupOperation()
        }
    }
    
    @IBAction func SignupButtonAction (_ sender: Any) {
        if !flag {
            titleLabel.text = "انشئ حساب"
            loginButton.setTitle("سجل الحساب", for: .normal)
            singupButton.setTitle("الديك حساب بالفعل سجل دخول", for: .normal)
            flag = !flag
            
        }
        else {
            titleLabel.text = "تسجيل الدخول"
            loginButton.setTitle("تسجيل الدخول", for: .normal)
            singupButton.setTitle("ليس لديك حساب سجل حساب الآن؟", for: .normal)
            flag = !flag
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
    
    func loginOperation() {
        firebase.SetRefernce(ref: Database.database().reference().child("users"))
        
        firebase.observeDataWithoutListnerWithCondition(k: "telephone", v: telephoneTextField.text!) { [weak self] snapshot in
            guard let self = self else { return }
            
            if snapshot.exists() {
                guard let value = snapshot.value as? Dictionary<String,Any> else {return}
                
                guard let data = value.first?.value else { return }
                
                guard let jsonData = try? JSONSerialization.data(withJSONObject: data, options: []) else {
                    print("Error in JSON Serialization")
                    return}

                guard let responseObj = try? JSONDecoder().decode(userModel.self, from: jsonData) else {
                    print("Error in Decode")
                    return}
                
                guard let login = BCryptSwift.verifyPassword(self.passwordTextField.text!, matchesHash: responseObj.password) else {
                    print("Failed in login")
                    return
                }

                if login {
                    
                    // write complex object
                    let user = UserlocalModel(telephone: self.telephoneTextField.text!, driverName: responseObj.driverName, carName: responseObj.carType, liecenceNumber: responseObj.licenceNumber, password: responseObj.password, uid: responseObj.uid, colorName: responseObj.carColor)
                    self.storage.writeStoreable(key: LocalStorageKeys.user, value: user)
                    
                    let nextVc = self.storyboard?.instantiateViewController(withIdentifier: "TrackCarViewController")
                    
                    nextVc!.modalPresentationStyle = .fullScreen
                    
                    self.present(nextVc!, animated: true)
                }
                else {
                    let alert = UIAlertController(title: "تنبيه", message: "رقم الهاتف او كلمة المرور غير صحيحه", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "تمت", style: .cancel))
                    self.present(alert, animated: true)
                    
                    self.passwordTextField.text = ""
                    self.passwordTextField.becomeFirstResponder()
                }
            }
            else {
                let alert = UIAlertController(title: "تنبيه", message: "رقم الهاتف او كلمة المرور غير صحيحه", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "تمت", style: .cancel))
                self.present(alert, animated: true)
                
                self.passwordTextField.text = ""
                self.passwordTextField.becomeFirstResponder()
            }
        }
    }
    
    // MARK: TODO: This Method For Signup Method
    func signupOperation() {
        CheckTelephoneNumber()
    }
    // -------------------------------------------
    
    func CheckTelephoneNumber() {
        firebase.SetRefernce(ref: Database.database().reference().child("users"))
        
        firebase.observeDataWithoutListnerWithCondition(k: "telephone", v: telephoneTextField.text!) { [weak self] snapshot in
            guard let self = self else { return }
            
            if snapshot.exists() {
                let alert = UIAlertController(title: "تنبيه", message: "رقم الهاتف مستخدم بالفعل", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "تمت", style: .cancel))
                self.present(alert, animated: true)
                
                self.passwordTextField.text = ""
                self.passwordTextField.becomeFirstResponder()
            }
            else {
                guard let telephone = self.telephoneTextField.text else { return }
                guard let password  = self.passwordTextField.text else { return }
                
                let numberOfRound = BCryptSwift.generateSaltWithNumberOfRounds(5)
                
                guard let hashedpassword = BCryptSwift.hashPassword(password, withSalt: numberOfRound) else {
                    print("Error in hashing")
                    return
                }
                
                
                let nextVc = self.storyboard?.instantiateViewController(withIdentifier: "CarDetailsViewController") as! CarDetailsViewController
                nextVc.data = ["telephone": telephone, "password": hashedpassword]
                nextVc.modalPresentationStyle = .fullScreen
                
                self.present(nextVc, animated: true)
            }
        }
    }

}
