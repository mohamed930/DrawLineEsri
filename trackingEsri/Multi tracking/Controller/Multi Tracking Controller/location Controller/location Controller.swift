//
//  location Controller.swift
//  trackingEsri
//
//  Created by Mohamed Ali on 06/01/2023.
//

import UIKit
import CoreLocation
import ArcGIS
import FirebaseDatabase

extension TrackCarViewController: CLLocationManagerDelegate {
    
    // MARK: TODO: This Method For Configure Location.
    func ConfigureLocation() {
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.allowsBackgroundLocationUpdates = false
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()
    }
    // -------------------------------------------
    
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let l = locations[locations.count - 1]
        if l.horizontalAccuracy > 0 {
            print("Long = \(l.coordinate.longitude) latitude = \(l.coordinate.latitude)")
            
            currentlatitude  = l.coordinate.latitude
            currentlongitude = l.coordinate.longitude
            
            locationManager.stopUpdatingLocation()
            locationManager = nil
            
            let user = loadLocaluserData()
            
            let point = AGSPoint(x: l.coordinate.longitude, y: l.coordinate.latitude, spatialReference: .wgs84())
            let data = ["driveName": user!.driverName, "carType": user!.carName, "telephone": user!.telephone] as! [String: AnyObject]
            
            esrisdk.AddPointOnMap(point: point, attribute: data)
            AddPointToDatabase(lati: l.coordinate.latitude, long: l.coordinate.longitude)
        }
    }
    
    //Write the didFailWithError method here:
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error.localizedDescription)
    }
    
    func AddPointToDatabase(lati: Double, long: Double) {
        
        let user = loadLocaluserData()
        
        firebase.SetRefernce(ref: Database.database().reference().child("vehicles").child(user!.uid))
        
        let vehicleData = [
                            "uuid" : user!.uid,
                            "driverName": user!.driverName,
                            "telephone" : user!.telephone,
                            "cartype"   : user!.carName,
                            "carColor": user!.colorName,
                            "latitude"  : lati,
                            "longitude" : long
                          ] as! [String: Any]
        
        firebase.write(value: vehicleData, complention: {})
    }
}
