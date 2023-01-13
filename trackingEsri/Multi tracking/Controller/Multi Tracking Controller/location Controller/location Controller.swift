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
        
    func ShowUserLocation() {
        self.map.locationDisplay.start {[weak self] error in
            guard let self = self else {return}
            if let error = error {
                print(error.localizedDescription)
                return
            }
            self.map.locationDisplay.autoPanMode = .recenter
            
        }
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
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let l = locations[locations.count - 1]
        if l.horizontalAccuracy > 0 {
            print("Long = \(l.coordinate.longitude) latitude = \(l.coordinate.latitude)")
            
            currentlatitude  = l.coordinate.latitude
            currentlongitude = l.coordinate.longitude
            
            locationManager.stopUpdatingLocation()
            locationManager = nil
            
            let point = AGSPoint(x: l.coordinate.longitude, y: l.coordinate.latitude, spatialReference: .wgs84())
            
           // esrisdk.AddPointOnMap(point: point, attribute: data)
            esrisdk.points.append(point)
        }
    }
    
    //Write the didFailWithError method here:
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error.localizedDescription)
    }
}
