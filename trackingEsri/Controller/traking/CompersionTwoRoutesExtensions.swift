//
//  CompersionTwoRoutesExtensions.swift
//  trackingEsri
//
//  Created by Mohamed Ali on 15/12/2022.
//

import UIKit
import CoreLocation
import FirebaseDatabase

extension CompersionTwoRoutesViewController: CLLocationManagerDelegate {
    
    //Write the didUpdateLocations method here:
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            let l = locations[locations.count - 1]
            if l.horizontalAccuracy > 0 {
                
                self.t = Task.detached {
                    print("Long = \(l.coordinate.longitude) latitude = \(l.coordinate.latitude)")
                    await self.SaveTheStepHistory(lati: l.coordinate.longitude, long: l.coordinate.latitude)
                    
                    // update UI with the new location in firebase.
                    let value = ["lati": l.coordinate.latitude, "long": l.coordinate.longitude] as! [String: Any]
                    await self.updateLocationInFireBase(value: value)
                    
                    let currentpoint = CLLocation(latitude: l.coordinate.latitude, longitude: l.coordinate.longitude)
                    let target =  await CLLocation(latitude: self.targetLocation.y, longitude: self.targetLocation.x)
                    
                    let distanceInMeters = currentpoint.distance(from: target)
                    
                    if(distanceInMeters <= 20 || distanceInMeters <= 5) {
                        // if destnace less then 20 metre show the End button in UI.
                        DispatchQueue.main.async {
                            self.loadUI()
                        }
                        
                    }
                    else {
                        await self.printDistance(distanceMetere: distanceInMeters)
                    }
                    
                }
            }
        }
        
    }
    
    func printDistance(distanceMetere: Double) {
         self.testDistanceLabel.text = "Distance: " + String(distanceMetere)
    }
    
    func SaveTheStepHistory(lati: Double, long: Double) {
        historypoints.append(locationModel(lati: lati, long: long))
    }
    
    func loadUI() {
        endButtonView.isHidden = false
        rateView.isHidden = true
        testView.isHidden = true
    }
    
    @IBAction func EndTripButtonAction (_ sender: Any) {
        // first stop the task
        t.cancel()
        
        // second stop location tracking
        self.locationManager.stopUpdatingLocation()
        self.locationManager.delegate = nil
        
        // third Load the Rate of trip
        calculateRateOfTrip()
    }
    
    func calculateRateOfTrip() {
        endButtonView.isHidden = true
        rateView.isHidden = false
        testView.isHidden = true
        
        let interaction = historypoints.filter { element in
            bestRoute.contains(where: {$0.lati == element.lati && $0.long == element.long})
        }
        
        let precentage = Double(interaction.count/bestRoute.count) * 100
        
        switch precentage {
        case 0:
            arrOfImgs.forEach { img in
                img.image = UIImage(named: "GrayStar")
            }
            break
        case 10:
            arrOfImgs.forEach { img in
                img.image = UIImage(named: "GrayStar")
            }
            break
        case 20:
            arrOfImgs.forEach { img in
                img.image = UIImage(named: "GrayStar")
            }
            break
        case 30:
            arrOfImgs[0].image = UIImage(named: "GoldStar")
            for i in 1..<arrOfImgs.count {
                arrOfImgs[i].image = UIImage(named: "GrayStar")
            }
            break
        case 40:
            arrOfImgs[0].image = UIImage(named: "GoldStar")
            for i in 1..<arrOfImgs.count {
                arrOfImgs[i].image = UIImage(named: "GrayStar")
            }
            break
        case 50:
            arrOfImgs[0].image = UIImage(named: "GoldStar")
            arrOfImgs[1].image = UIImage(named: "GoldStar")
            arrOfImgs[2].image = UIImage(named: "GoldStar")
            for i in 3..<arrOfImgs.count {
                arrOfImgs[i].image = UIImage(named: "GrayStar")
            }
            break
        case 60:
            arrOfImgs[0].image = UIImage(named: "GoldStar")
            arrOfImgs[1].image = UIImage(named: "GoldStar")
            arrOfImgs[2].image = UIImage(named: "GoldStar")
            for i in 3..<arrOfImgs.count {
                arrOfImgs[i].image = UIImage(named: "GrayStar")
            }
            break
        case 70:
            arrOfImgs[0].image = UIImage(named: "GoldStar")
            arrOfImgs[1].image = UIImage(named: "GoldStar")
            arrOfImgs[2].image = UIImage(named: "GoldStar")
            for i in 3..<arrOfImgs.count {
                arrOfImgs[i].image = UIImage(named: "GrayStar")
            }
            break
        case 80:
            for i in 0..<4 {
                arrOfImgs[i].image = UIImage(named: "GoldStar")
            }
            arrOfImgs[4].image = UIImage(named: "GrayStar")
            arrOfImgs[5].image = UIImage(named: "GrayStar")
            break
        case 90:
            for i in 0..<4 {
                arrOfImgs[i].image = UIImage(named: "GoldStar")
            }
            arrOfImgs[4].image = UIImage(named: "GrayStar")
            arrOfImgs[5].image = UIImage(named: "GrayStar")
            break
        case 100:
            arrOfImgs.forEach { img in
                img.image = UIImage(named: "GoldStar")
            }
            break
        default:
            print("None of the obove")
        }
        
        
    }
    
    func updateLocationInFireBase(value: [String:Any]) {
        Database.database().reference()
            .child("points").child("0").child("vehicals").child("location").updateChildValues(value){
               (error:Error?, ref:DatabaseReference) in
               if error != nil {
                 print("Error")
               }
               
           }
    }
    
    
    //Write the didFailWithError method here:
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error.localizedDescription)
    }
}
