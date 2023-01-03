//
//  CarDetailsViewController.swift
//  trackingEsri
//
//  Created by Mohamed Ali on 03/01/2023.
//

import UIKit
import Colorful

class CarDetailsViewController: UIViewController {
    
    @IBOutlet weak var carDriverLabel:UITextField!
    @IBOutlet weak var carlicenceNumber:UITextField!
    @IBOutlet weak var cartype:UITextField!
    @IBOutlet weak var colorPicker: ColorPicker!
    @IBOutlet weak var colorName: UILabel!
    
    
    var data: [String: Any]!
    var colorSpace: HRColorSpace = .sRGB

    override func viewDidLoad() {
        super.viewDidLoad()

        colorPicker.addTarget(self, action: #selector(self.handleColorChanged(picker:)), for: .valueChanged)
        colorPicker.set(color: UIColor(displayP3Red: 1.0, green: 1.0, blue: 0, alpha: 1), colorSpace: colorSpace)
        handleColorChanged(picker: colorPicker)
    }
    
    @objc func handleColorChanged(picker: ColorPicker) {
        colorName.text = picker.color
    }

}
