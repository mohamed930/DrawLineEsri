//
//  GeoCoderMapViewController.swift
//  trackingEsri
//
//  Created by Mohamed Ali on 08/12/2022.
//

import UIKit
import ArcGIS

class GeoCoderMapViewController: UIViewController {
    
    @IBOutlet weak var mapView: AGSMapView!
    
    private let locatorTask = AGSLocatorTask(url: URL(string: "https://geocode-api.arcgis.com/arcgis/rest/services/World/GeocodeServer")!)
    private var graphicsOverlay = AGSGraphicsOverlay()
    private var cancelable: AGSCancelable!
    
    override func viewDidLoad() {
        super.viewDidLoad()
   
        showMap(ZoomLati: 31.256904, ZoomLong: 32.291706)
    }
    
    func showMap(ZoomLati: Double, ZoomLong: Double) {
        // Create an instance of a map with ESRI topographic basemap.
        mapView.map = AGSMap(basemapStyle: .arcGISTopographic)
        mapView.touchDelegate = self

        // Add the graphics overlay.
        mapView.graphicsOverlays.add(self.graphicsOverlay)

        // Zoom to a specific extent.
        mapView.setViewpoint(AGSViewpoint(center: AGSPoint(x: ZoomLong, y: ZoomLati, spatialReference: .wgs84()), scale: 5e4))
    }
    
    private func reverseGeocode(_ point: AGSPoint) {
        // Cancel previous request.
        if cancelable != nil {
            cancelable.cancel()
        }

        // Hide the callout.
        mapView.callout.dismiss()

        // Remove already existing graphics.
        graphicsOverlay.graphics.removeAllObjects()

        // Normalize point.
        let normalizedPoint = AGSGeometryEngine.normalizeCentralMeridian(of: point) as! AGSPoint

        let graphic = graphicForPoint(normalizedPoint)
        self.graphicsOverlay.graphics.add(graphic)

        // Initialize parameters.
        let reverseGeocodeParameters = AGSReverseGeocodeParameters()
        reverseGeocodeParameters.maxResults = 1
        // Reverse geocode.
        self.cancelable = self.locatorTask.reverseGeocode(withLocation: normalizedPoint, parameters: reverseGeocodeParameters) { [weak self] (results: [AGSGeocodeResult]?, error: Error?) in
            guard let self = self else { return }
            if let error = error {
                // Present user canceled error.
                if (error as NSError).code != NSUserCancelledError {
                    print(error.localizedDescription)
                }
            } else if let result = results?.first {
                graphic.attributes.addEntries(from: result.attributes!)
                self.showCalloutForGraphic(graphic, tapLocation: normalizedPoint)
                return
            } else {
                print("No address found")
            }
            self.graphicsOverlay.graphics.remove(graphic)
        }
    }
    
    // Method returns a graphic object for the specified point and attributes.
    private func graphicForPoint(_ point: AGSPoint) -> AGSGraphic {
        let markerImage = UIImage(named: "redPin")!
        let symbol = AGSPictureMarkerSymbol(image: markerImage)
        symbol.leaderOffsetY = markerImage.size.height / 2
        symbol.offsetY = markerImage.size.height / 2
        let graphic = AGSGraphic(geometry: point, symbol: symbol, attributes: [String: AnyObject]())
        return graphic
    }
    
    // Show callout for the graphic.
    private func showCalloutForGraphic(_ graphic: AGSGraphic, tapLocation: AGSPoint) {
        // Get the attributes from the graphic and populates the title and detail for the callout.
        let cityString = graphic.attributes["City"] as? String ?? ""
        let addressString = graphic.attributes["Address"] as? String ?? ""
        let stateString = graphic.attributes["State"] as? String ?? ""
        self.mapView.callout.title = addressString
        self.mapView.callout.detail = "\(cityString) \(stateString)"
        self.mapView.callout.isAccessoryButtonHidden = true
        self.mapView.callout.show(for: graphic, tapLocation: tapLocation, animated: true)
    }
}

extension GeoCoderMapViewController: AGSGeoViewTouchDelegate {
    func geoView(_ geoView: AGSGeoView, didTapAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        reverseGeocode(mapPoint)
    }
}
