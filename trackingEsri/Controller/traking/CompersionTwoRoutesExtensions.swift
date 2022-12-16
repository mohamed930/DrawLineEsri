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
                
                Task.detached {
                    print("Long = \(l.coordinate.longitude) latitude = \(l.coordinate.latitude)")
                    await self.SaveTheStepHistory(lati: l.coordinate.longitude, long: l.coordinate.latitude)
                    
                    // update UI with the new location in firebase.
                    let value = ["lati": l.coordinate.latitude, "long": l.coordinate.longitude] as! [String: Any]
                    await self.updateLocationInFireBase(value: value)
                    
                    let currentpoint = CLLocation(latitude: l.coordinate.latitude, longitude: l.coordinate.longitude)
                    let target =  await CLLocation(latitude: self.targetLocation.y, longitude: self.targetLocation.x)
                    
                    let distanceInMeters = target.distance(from: currentpoint)
                    
                    if(distanceInMeters <= 0.0124274) {
                        // if destnace less then 20 metre show the End button in UI.
                        await self.loadUI()
                    }
                }
            }
        }
        
    }
    
    func SaveTheStepHistory(lati: Double, long: Double) {
        historypoints.append(locationModel(lati: lati, long: long))
    }
    
    func loadUI() {
        endButtonView.isHidden = false
        rateView.isHidden = true
    }
    
    @IBAction func EndTripButtonAction (_ sender: Any) {
        // first stop location tracking
        self.locationManager.stopUpdatingLocation()
        self.locationManager.delegate = nil
        
        // Second Load the trip Trip
        calculateRateOfTrip()
    }
    
    func calculateRateOfTrip() {
        endButtonView.isHidden = true
        rateView.isHidden = false
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
