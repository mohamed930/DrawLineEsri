//
//  suggestionCell.swift
//  trackingEsri
//
//  Created by Mohamed Ali on 06/01/2023.
//

import UIKit
import CoreLocation
import Lottie

class carsuggestionCell: UITableViewCell {
    
    @IBOutlet weak var locationImageView:AnimationView!
    @IBOutlet weak var locationDistanceLabel:UILabel!
    
    @IBOutlet weak var driverNameLabel:UILabel!
    @IBOutlet weak var carTypeLabel:UILabel!
    @IBOutlet weak var carColorImageView:UIImageView!
    
    @IBOutlet weak var deaitalsButton:UIButton!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        LoadAnimation()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    private func LoadAnimation() {
        // 1. Set animation content mode
        locationImageView.contentMode = .scaleAspectFill
          
        // 2. Set animation loop mode
        locationImageView.loopMode = .loop
          
        // 3. Adjust animation speed
        locationImageView.animationSpeed = 0.5
          
        // 4. Play animation
        locationImageView.play()
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
        
        return str
    }
    
}
