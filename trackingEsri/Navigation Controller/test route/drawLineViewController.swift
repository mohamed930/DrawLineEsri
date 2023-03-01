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

    override func viewDidLoad() {
        super.viewDidLoad()

        ShowMap()
        AddStops()
        AddLine()
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
