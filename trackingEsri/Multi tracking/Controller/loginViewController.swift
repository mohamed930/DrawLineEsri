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
        /*guard let login = BCryptSwift.verifyPassword(passwordTextField.text!, matchesHash: hashedpassword) else {
            print("Failed in login")
            return
        }
        
        if login {
            print("login is success")
        }
        else {
            print("login isn't success")
        }*/
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
