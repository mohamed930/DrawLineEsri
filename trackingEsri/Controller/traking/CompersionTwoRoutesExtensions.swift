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
                    
                    // update UI with the new location in firebase.
                    let value = ["lati": l.coordinate.latitude, "long": l.coordinate.longitude] as! [String: Any]
                    await self.updateLocationInFireBase(value: value)
                }
                
                /*Task.detached {
                    // update UI with the new location
                    let l = locationModel(lati: l.coordinate.latitude, long: l.coordinate.longitude)
                    await self.esri.UpdatePoint(pointNumber: "two", location: l)
                }*/
                
            }
        }
        
    }
    
    func updateLocationInFireBase(value: [String:Any]) {
        Database.database().reference()
        .child("points").child("vehicals").child("location").updateChildValues(value){
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
