//
//  updateViewController.swift
//  trackingEsri
//
//  Created by Mohamed Ali on 15/12/2022.
//

import UIKit
import FirebaseDatabase

class updateViewController: UIViewController {
    
    @IBOutlet weak var latiTextFeild:UITextField!
    @IBOutlet weak var longTextField:UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func updateLocation(_ sender: Any) {
        let value = ["lati": Double(self.latiTextFeild.text!)!, "long": Double(self.longTextField.text!)!] as! [String: Any]
        
        Database.database().reference()
            .child("points").child("vehicals").child("location").updateChildValues(value){
                   (error:Error?, ref:DatabaseReference) in
                   if error != nil {
                     print("Error")
                   }
                   else {
                       let alert = UIAlertController(title: "Success", message: "updated Successfull", preferredStyle: .alert)
                       alert.addAction(UIAlertAction(title: "Ok", style: .default))
                       
                       self.present(alert, animated: true)
                   }
               }
    }

}
