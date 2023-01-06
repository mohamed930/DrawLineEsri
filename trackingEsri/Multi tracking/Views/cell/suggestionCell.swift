//
//  suggestionCell.swift
//  trackingEsri
//
//  Created by Mohamed Ali on 06/01/2023.
//

import UIKit
import CoreLocation

class suggestionCell: UITableViewCell {
    
    @IBOutlet weak var locationImageView:UIImageView!
    @IBOutlet weak var locationDistanceLabel:UILabel!
    
    @IBOutlet weak var driverNameLabel:UILabel!
    @IBOutlet weak var carTypeLabel:UILabel!
    @IBOutlet weak var carColorImageView:UIImageView!
    
    @IBOutlet weak var deaitalsButton:UIButton!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func ConfigureCell(ob: vehiclesModel, currenctlati: Double, currentlong: Double) {
        let currentpoint = CLLocation(latitude: currenctlati, longitude: currentlong)
        let target       = CLLocation(latitude: ob.latitude, longitude: ob.longitude)
        
        
        let distanceInMeters = currentpoint.distance(from: target)
        
        locationDistanceLabel.text = "\(convertToArabic(numberStr: "\(distanceInMeters / 100)")) كم"
        
        driverNameLabel.text = "اسم السائق: \(ob.driverName)"
        
        carTypeLabel.text = "نوع السياره: \(ob.cartype)"
        
        carColorImageView.tintColor = UIColor().hexStringToUIColor(hex: ob.carColor)
    }
    
    private func convertToArabic(numberStr: String) -> String {
        let numberD = Double(numberStr)
        let doubleNumber = String(format: "%.2f", numberD!)
        
        let str = doubleNumber.convertedDigitsToLocale(Locale(identifier: "FA"))
        
        print(doubleNumber)
        
        return str
    }
    
}
