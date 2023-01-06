//
//  CompersionTwoRoutesExtensions.swift
//  trackingEsri
//
//  Created by Mohamed Ali on 15/12/2022.
//

import UIKit
import CoreLocation
import FirebaseDatabase
import ArcGIS

extension CompersionTwoRoutesViewController: CLLocationManagerDelegate {
    
    //Write the didUpdateLocations method here:
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        var distanceInMeters = 0.0
        
        DispatchQueue.background(delay: 5.0, background: { [weak self] in
            // do something in background
            guard let self = self else { return }
            let l = locations[locations.count - 1]
            if l.horizontalAccuracy > 0 {
                
                print("Long = \(l.coordinate.longitude) latitude = \(l.coordinate.latitude)")
                self.SaveTheStepHistory(lati: l.coordinate.latitude, long: l.coordinate.longitude)
                
                let value = ["lati": l.coordinate.latitude, "long": l.coordinate.longitude] as! [String: Any]
                self.updateLocationInFireBase(value: value)
                
                let currentpoint = CLLocation(latitude: l.coordinate.latitude, longitude: l.coordinate.longitude)
                let target =       CLLocation(latitude: self.targetLocation.y, longitude: self.targetLocation.x)
                
                
                distanceInMeters = currentpoint.distance(from: target)
            }
        }, completion: { [weak self] in
            // when background job finishes
            guard let self = self else { return }
            if (distanceInMeters <= 20 || distanceInMeters <= 5) {
                // if destnace less then 20 metre show the End button in UI.
                self.loadUI()
                
            }
            else {
                 self.printDistance(distanceMetere: distanceInMeters)
            }
            
        })
        
    }
    
    func loadUI() {
        if !flage {
            endButtonView.isHidden = false
            rateView.isHidden = true
            testView.isHidden = true
        }
        else {
            if locationManager != nil {
                locationManager = nil
                // locationManager.stopUpdatingLocation()
                endButtonView.isHidden = true
            }
        }
        
    }
    
    @IBAction func EndTripButtonAction (_ sender: Any) {
        // first stop the task
        flage = true
        
        
        //calculateRateOfTrip()
        var points = Array<AGSPoint>()
        for i in historypoints {
            points.append(AGSPoint(x: i.long, y: i.lati, spatialReference: .wgs84()))
        }
        esri.AddLineManually(points: points,color: .blue)
        
        var best = Array<AGSPoint>()
        for i in bestRoute {
            best.append(AGSPoint(x: i.long, y: i.lati, spatialReference: .wgs84()))
        }
        esri.AddLineManually(points: best, color: .green)
        
        esri.routeGraphicsOverlay.graphics.removeAllObjects()
        
    }
    
    func printDistance(distanceMetere: Double) {
        testView.isHidden = false
        endButtonView.isHidden = true
        testDistanceLabel.text = "Distance: " + String(distanceMetere)
    }
    
    func SaveTheStepHistory(lati: Double, long: Double) {
        historypoints.append(locationModel(lati: lati, long: long))
    }
    
    func calculateRateOfTrip() {
        rateView.isHidden = false
        endButtonView.isHidden = true
        testView.isHidden = true
        
        for i in bestRoute {
            print("locationModel(lati: \(i.lati),long: \(i.long)),")
        }
        
        let interaction = historypoints.filter { element in
            bestRoute.contains(where: {$0.lati == element.lati && $0.long == element.long})
        }
        
        let precentage = Double(interaction.count/bestRoute.count) * 100
        
        rateTripLabel.text = "تقيم الرحله : " + String(precentage) + "%"
        
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
