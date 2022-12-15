//
//  CompersionTwoRoutesViewController.swift
//  trackingEsri
//
//  Created by Mohamed Ali on 15/12/2022.
//

import UIKit
import ArcGIS
import FirebaseDatabase

class CompersionTwoRoutesViewController: UIViewController {
    
    @IBOutlet weak var mapView: AGSMapView!
    
    var esri: Esri!
    var firebase = Firebase()

    override func viewDidLoad() {
        super.viewDidLoad()

        esri = Esri(mapView: mapView)
        
        esri.showMap(lati: 31.256904, long: 32.291706)
        mapView.touchDelegate = self
        LoadPointsFromDatabase()
        
    }
    
    func LoadPointsFromDatabase() {
        firebase.SetRefernce(ref: Database.database().reference().child("points").child("target"))
        
        firebase.observerDataWithoutListner { [weak self] snapshot in
            
            guard let self = self else {return}
            
            guard snapshot.exists() else {return}
            
            guard let value = snapshot.value else {return}
            
            guard let jsonData = try? JSONSerialization.data(withJSONObject: value, options: []) else {return}
            
            guard let responseObj = try? JSONDecoder().decode(responseModel.self, from: jsonData) else {return}
            
            self.esri.AddPointOnMap(point: AGSPoint(x: responseObj.location.long, y: responseObj.location.lati, spatialReference: .wgs84()), attribute: ["title": responseObj.name] as! [String: AnyObject])
            
            self.LoadCarsFromDataBase()
        }
    }
    
    func LoadCarsFromDataBase() {
        firebase.SetRefernce(ref: Database.database().reference().child("points").child("vehicals"))
        
        firebase.observeDataWithListner { [weak self] snapshot in
            guard let self = self else {return}
            
            guard snapshot.exists() else {return}
            
            guard let value = snapshot.value else {return}
            
            guard let jsonData    = try? JSONSerialization.data(withJSONObject: value, options: []) else {return}
            
            guard let responseObj = try? JSONDecoder().decode(responseModel.self, from: jsonData) else {return}
            
            if (self.esri.points.count == 1) {
                self.esri.AddPointOnMap(point: AGSPoint(x: responseObj.location.long, y: responseObj.location.lati, spatialReference: .wgs84()), attribute: ["title": responseObj.name] as! [String: AnyObject])
            }
            else {
                print("Update point")
                self.esri.UpdatePoint(pointNumber: "one", location: responseObj.location)
            }
            
            self.esri.getDefaultParameters()
            self.mapView.setViewpointCenter(self.esri.points[1], scale: 1750)
        }
    }
    
    /*func AddStartPoint() {
        esri.AddPointOnMap(point: AGSPoint(x: 32.288795, y: 31.263519, spatialReference: .wgs84()), attribute: ["title": "Supermarket","Address": "portsaid,forseasons"] as! [String: AnyObject])
    }
    
    func AddEndPoint() {
        esri.AddPointOnMap(point: AGSPoint(x: 32.294476, y: 31.260259, spatialReference: .wgs84()),attribute: ["title": "Car","Address": "portsaid,lord"] as! [String: AnyObject])
    }*/
}

extension CompersionTwoRoutesViewController: AGSGeoViewTouchDelegate {
    func geoView(_ geoView: AGSGeoView, didTapAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        // Normalize point.
        geoView.identify(esri.getGraphocsOverlay(), screenPoint: screenPoint, tolerance: 12, returnPopupsOnly: false) { [weak self] result in
            guard let self = self else { return }
                        
            guard let point = result.graphics.first else {
                self.mapView.callout.dismiss()
                return
            }
            
            self.esri.ShowCalloutForPoint(graphic: point, point: mapPoint)
        }
    }
}
