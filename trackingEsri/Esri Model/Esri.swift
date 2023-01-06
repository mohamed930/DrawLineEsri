//
//  Esri.swift
//  trackingEsri
//
//  Created by Mohamed Ali on 15/12/2022.
//

import ArcGIS
import Foundation

class Esri {
    
    let mapView: AGSMapView!
    private var graphicsOverlay = AGSGraphicsOverlay()
    private var routeParameters: AGSRouteParameters!
    var routeTask = AGSRouteTask(url: URL(string: "https://route-api.arcgis.com/arcgis/rest/services/World/Route/NAServer/Route_World")!)
    var generatedRoute: AGSRoute!
    var routeGraphicsOverlay = AGSGraphicsOverlay()
    public var points = Array<AGSPoint>()
    
    init(mapView: AGSMapView) {
        self.mapView = mapView
    }
    
    func getGraphocsOverlay() -> AGSGraphicsOverlay {
        return graphicsOverlay
    }
    
    func showMap(lati: Double, long: Double) {
        // Create an instance of a map with ESRI topographic basemap.
        mapView.map = AGSMap(basemapStyle: .arcGISNavigation)
        // mapView.touchDelegate = self

        // Add the graphics overlay.
        mapView.graphicsOverlays.add(graphicsOverlay)
        mapView.graphicsOverlays.add(routeGraphicsOverlay)
        
        // Zoom to a specific extent.
        mapView.setViewpoint(AGSViewpoint(center: AGSPoint(x: long, y: lati, spatialReference: .wgs84()), scale: 5e4))
    }
    
    func AddPointOnMap(point: AGSPoint,attribute: [String: AnyObject]) {
        // Normalize point.
        let normalizedPoint = AGSGeometryEngine.normalizeCentralMeridian(of: point) as! AGSPoint
        
        points.append(normalizedPoint)

        let graphic = graphicForPoint(normalizedPoint, Attribute: attribute)
        graphicsOverlay.graphics.add(graphic)
        
        graphicsOverlay.isVisible = true
        mapView.setViewpointGeometry(graphicsOverlay.extent, padding: 30, completion: nil)
    }
    
    func ShowCalloutForPoint(graphic: AGSGraphic,point: AGSPoint) {
        // Hide the callout.
        mapView.callout.dismiss()
        
        self.showCalloutForGraphic(graphic, tapLocation: point)
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
                
                self.ShowLine()
            }
        }
    }
    
    func UpdatePoint(location: locationModel, key: String, value: String) {
        if let graphic = (graphicsOverlay.graphics as? [AGSGraphic])?.first(where: {
            ($0.attributes[key] as? String) == value
        }) {
            // Move the graphic
            graphic.geometry = AGSPoint(x: location.long, y: location.lati, spatialReference: .wgs84())
            points[1] = AGSPoint(x: location.long, y: location.lati, spatialReference: .wgs84())
            
//                // Or remove the graphic
//                overlay.graphics.remove(graphic)
        }
    }
    
    // MARK: TODO: Method returns a graphic object for the specified point and attributes.
    private func graphicForPoint(_ point: AGSPoint,Attribute: [String: AnyObject]) -> AGSGraphic {
        let markerImage = UIImage(named: "carpine")!
        let symbol = AGSPictureMarkerSymbol(image: markerImage)
        symbol.leaderOffsetY = markerImage.size.height / 2
        symbol.offsetY = markerImage.size.height / 2
        let graphic = AGSGraphic(geometry: point, symbol: symbol, attributes: Attribute)
        return graphic
    }
    // -------------------------------------------
    
    // MARK: TODO: Show callout for the graphic.
    private func showCalloutForGraphic(_ graphic: AGSGraphic,tapLocation: AGSPoint) {
        let cityString = graphic.attributes["title"] as? String ?? ""
       // let addressString = graphic.attributes["Address"] as? String ?? ""
        
        mapView.callout.title = cityString
        // mapView.callout.detail = addressString
        
        mapView.callout.isAccessoryButtonHidden = true
        mapView.callout.show(for: graphic, tapLocation: tapLocation, animated: true)
    }
    // -------------------------------------------
    
    // method provides a line symbol for the route graphic
    private func routeSymbol() -> AGSSimpleLineSymbol {
        let symbol = AGSSimpleLineSymbol(style: .solid, color: .red, width: 5)
        return symbol
    }
    // -------------------------------------------
    
    
    private func ShowLine() {
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
        let stop1 = AGSStop(point: points[0])
        stop1.name = "Origin"
        let stop2 = AGSStop(point: points[1])
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
    
    func AddLineManually(points: [AGSPoint],color: UIColor) {
        let polyline = AGSPolyline(
                    points: points
                )
        
        let polylineSymbol = AGSSimpleLineSymbol(style: .solid, color: color, width: 3.0)
        
        let polylineGraphic = AGSGraphic(geometry: polyline, symbol: polylineSymbol)
        
        graphicsOverlay.graphics.add(polylineGraphic)
    }
}
