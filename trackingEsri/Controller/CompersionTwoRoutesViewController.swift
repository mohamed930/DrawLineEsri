//
//  CompersionTwoRoutesViewController.swift
//  trackingEsri
//
//  Created by Mohamed Ali on 15/12/2022.
//

import UIKit
import ArcGIS

class CompersionTwoRoutesViewController: UIViewController {
    
    @IBOutlet weak var mapView: AGSMapView!
    
    var esri: Esri!

    override func viewDidLoad() {
        super.viewDidLoad()

        esri = Esri(mapView: mapView)
        
        esri.showMap(lati: 31.256904, long: 32.291706)
        mapView.touchDelegate = self
        AddStartPoint()
        AddEndPoint()
        esri.getDefaultParameters()
        
    }
    
    func AddStartPoint() {
        esri.AddPointOnMap(point: AGSPoint(x: 32.288795, y: 31.263519, spatialReference: .wgs84()), attribute: ["title": "Car 1","Address": "portsaid,forseasons"] as! [String: AnyObject])
    }
    
    func AddEndPoint() {
        esri.AddPointOnMap(point: AGSPoint(x: 32.294476, y: 31.260259, spatialReference: .wgs84()),attribute: ["title": "Car 2","Address": "portsaid,lord"] as! [String: AnyObject])
    }
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
