//
//  drawLineViewController.swift
//  trackingEsri
//
//  Created by Mohamed Ali on 01/03/2023.
//

import UIKit
import ArcGIS

class drawLineViewController: UIViewController {
    
    var esriSdk: Esri!
    var stops = Array<AGSPoint>()
    
    var timer = Timer()
    static var count = 0
    var Gpoints = Array<[String:Any]>()

    override func viewDidLoad() {
        super.viewDidLoad()

        ShowMap()
        // AddStops()
        // AddLine()
        
        self.timer = Timer.scheduledTimer(withTimeInterval: 7, repeats: true, block: { [weak self] _ in
            
            let test = [
                  [
                    "altitude": 22,
                    "getDateTime": "2023-02-28T17:04:04",
                    "gsM_signal_strength": 19,
                    "latitude": 31.056902,
                    "longitude": 31.401104,
                    "messageTime": "2023-02-28T17:08:46.291246",
                    "number_of_satellites": 10,
                    "odometer": 1802651,
                    "speed": 0
                  ],
                  [
                    "altitude": 22,
                    "getDateTime": "2023-02-28T17:010:04",
                    "gsM_signal_strength": 19,
                    "latitude": 31.057106,
                    "longitude": 31.401386,
                    "messageTime": "2023-02-28T17:19:46.291246",
                    "number_of_satellites": 10,
                    "odometer": 1802651,
                    "speed": 20
                  ],
                  [
                    "altitude": 22,
                    "getDateTime": "2023-02-28T17:010:04",
                    "gsM_signal_strength": 19,
                    "latitude": 31.058594,
                    "longitude": 31.402620,
                    "messageTime": "2023-02-28T17:18:46.291246",
                    "number_of_satellites": 10,
                    "odometer": 1802651,
                    "speed": 50
                  ]
            ] as! [[String:Any]]
            
            self?.updateMap(points: test)
        })
    }
    
    func ShowMap() {
        esriSdk = Esri(mapView: self.view as! AGSMapView)
        esriSdk.showMap(lati: 31.05671, long: 31.40134)
        esriSdk.mapView?.touchDelegate = self
    }
    
    func AddStops() {
        // 31.056902, 31.401104
        stops = [AGSPoint(x: 31.401104, y: 31.056902, spatialReference: .wgs84()),AGSPoint(x: 31.385513, y: 31.044863, spatialReference: .wgs84())]

        esriSdk.AddPointOnMap(point: stops[0], attribute: ["title": "stop1"] as! [String: AnyObject])

        esriSdk.AddPointOnMap(point: stops[1], attribute: ["title": "stop2"] as! [String: AnyObject])
        
    }
    
    func AddLine() {
        esriSdk.AddLineManually(points: stops, color: .red)
    }
    
    func updateMap(points: [[String: Any]]){
        if (drawLineViewController.count >= points.count) {
          return;
        }
        
        
        if (Gpoints.count == 0) {
            esriSdk.AddPointOnMap(point: AGSPoint(x: points[drawLineViewController.count]["longitude"] as! Double, y: points[drawLineViewController.count]["latitude"] as! Double, spatialReference: .wgs84()), attribute: ["title": "speed \(points[drawLineViewController.count]["speed"]!)"] as! [String: AnyObject])
            
            Gpoints.insert(points[drawLineViewController.count], at: drawLineViewController.count)
            drawLineViewController.count += 1;
            return;
        }
        
        if (Gpoints.count != 0) {
            if (Gpoints[drawLineViewController.count - 1]["longitude"] as! Double != points[drawLineViewController.count]["longitude"] as! Double &&
                Gpoints[drawLineViewController.count - 1]["latitude"] as! Double != points[drawLineViewController.count]["latitude"] as! Double) {
                
                esriSdk.AddPointOnMap(point: AGSPoint(x: points[drawLineViewController.count]["longitude"] as! Double, y: points[drawLineViewController.count]["latitude"] as! Double, spatialReference: .wgs84()), attribute: ["title": "speed \(points[drawLineViewController.count]["speed"]!)"] as! [String: AnyObject])
                
                Gpoints.insert(points[drawLineViewController.count], at: drawLineViewController.count)
                
                let path = [
                    AGSPoint(x: points[drawLineViewController.count]["longitude"] as! Double, y: points[drawLineViewController.count]["latitude"] as! Double, spatialReference: .wgs84()),
                    AGSPoint(x: Gpoints[drawLineViewController.count - 1]["longitude"] as! Double, y: Gpoints[drawLineViewController.count - 1]["latitude"] as! Double, spatialReference: .wgs84())
                           ]
                
                esriSdk.AddLineManually(points: path, color: .red)
                drawLineViewController.count += 1
                return
            }
        }
    }

}

extension drawLineViewController: AGSGeoViewTouchDelegate {
    func geoView(_ geoView: AGSGeoView, didTapAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        // Normalize point.
        geoView.identify(esriSdk.getGraphicsOverlay(), screenPoint: screenPoint, tolerance: 12, returnPopupsOnly: false) { [weak self] result in
            guard let self = self else { return }
                        
            guard let point = result.graphics.first else {
                guard let view = self.view as? AGSMapView else { return }
                view.callout.dismiss()
                return
            }
            
            self.esriSdk.ShowCalloutForPoint(graphic: point, point: mapPoint)
        }
    }
}
