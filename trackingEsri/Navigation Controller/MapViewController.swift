//
//  ViewController.swift
//  trackingEsri
//
//  Created by Mohamed Ali on 07/12/2022.
//

import UIKit
import ArcGIS



class MapViewController: UIViewController {
    
    @IBOutlet var mapView: AGSMapView!
    
    var routeTask: AGSRouteTask!
    var routeParameters: AGSRouteParameters!

    var stopGraphicsOverlay = AGSGraphicsOverlay()
    var routeGraphicsOverlay = AGSGraphicsOverlay()

    var stop1Geometry: AGSPoint!
    var stop2Geometry: AGSPoint!
    
    var generatedRoute: AGSRoute!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadMap(Zoomlati: 31.2565, Zoomlong: 32.2841)
    }
    
    func loadMap(Zoomlati: Double,Zoomlong: Double) {
        // initialize map with topographic basemap
        let map = AGSMap(basemapStyle: .arcGISTopographic)
        self.mapView.map = map
        
        // add graphicsOverlays to the map view
        mapView.graphicsOverlays.addObjects(from: [routeGraphicsOverlay, stopGraphicsOverlay])
        
        // zoom to viewpoint
        mapView.setViewpointCenter(AGSPoint(x: Zoomlong, y: Zoomlati, spatialReference: .wgs84()), scale: 1e5)
        
        // initialize route task
        routeTask = AGSRouteTask(url: URL(string: "https://route-api.arcgis.com/arcgis/rest/services/World/Route/NAServer/Route_World")!)
        
        // get default parameters
        getDefaultParameters()

    }
    
    // method to get the default parameters for the route task
    func getDefaultParameters() {
        routeTask.defaultRouteParameters { [weak self] (params: AGSRouteParameters?, error: Error?) in
            guard let self = self else { return }
            if let error = error {
                print(error)
            } else {
                // on completion store the parameters
                self.routeParameters = params
                
                // add stops point (target and destination)
                let target = pointModel(lati: 31.256904, long: 32.291706)
                let destination = pointModel(lati: 31.26271, long: 32.283307)
                self.addStops(point1: target, point2: destination)
                
                self.ShowLine()
            }
        }
    }
    
    // add hard coded stops to the map view
    func addStops(point1: pointModel, point2: pointModel) {
        self.stop1Geometry = AGSPoint(x: point1.long, y: point1.lati, spatialReference: .wgs84())
        self.stop2Geometry = AGSPoint(x: point2.long, y: point2.lati, spatialReference: .wgs84())

        let startStopGraphic = AGSGraphic(geometry: self.stop1Geometry, symbol: self.stopSymbol(withName: "Origin", textColor: .blue), attributes: nil)
        let endStopGraphic = AGSGraphic(geometry: self.stop2Geometry, symbol: self.stopSymbol(withName: "Destination", textColor: .red), attributes: nil)

        self.stopGraphicsOverlay.graphics.addObjects(from: [startStopGraphic, endStopGraphic])
    }

    // method provides a text symbol for stop with specified parameters
    func stopSymbol(withName name: String, textColor: UIColor) -> AGSTextSymbol {
        return AGSTextSymbol(text: name, color: textColor, size: 20, horizontalAlignment: .center, verticalAlignment: .middle)
    }

    // method provides a line symbol for the route graphic
    func routeSymbol() -> AGSSimpleLineSymbol {
        let symbol = AGSSimpleLineSymbol(style: .solid, color: .yellow, width: 5)
        return symbol
    }
    
    func ShowLine() {
        // route only if default parameters are fetched successfully
        if routeParameters == nil {
            print("Default route parameters not loaded")
        }

        // set parameters to return directions
        routeParameters.returnDirections = true

        // clear previous routes
        routeGraphicsOverlay.graphics.removeAllObjects()

        // clear previous stops
        routeParameters.clearStops()

        // set the stops
        let stop1 = AGSStop(point: self.stop1Geometry)
        stop1.name = "Origin"
        let stop2 = AGSStop(point: self.stop2Geometry)
        stop2.name = "Destination"
        routeParameters.setStops([stop1, stop2])

        self.routeTask.solveRoute(with: routeParameters) { [weak self] (routeResult: AGSRouteResult?, error: Error?) in
            guard let self = self else { return }
            if let error = error {
                print(error)
            } else if let route = routeResult?.routes.first {
                // show the resulting route on the map
                // also save a reference to the route object
                // in order to access directions
                self.generatedRoute = route
                let routeGraphic = AGSGraphic(geometry: self.generatedRoute.routeGeometry, symbol: self.routeSymbol(), attributes: nil)
                self.routeGraphicsOverlay.graphics.add(routeGraphic)
            }
        }

    }


}

