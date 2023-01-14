//
//  NavigationModel.swift
//  trackingEsri
//
//  Created by Mohamed Ali on 13/01/2023.
//

import UIKit
import ArcGIS

class NavigationModel {
    private var navigateBarButtonItem: UIBarButtonItem!
    private var resetBarButtonItem: UIBarButtonItem!
    private var recenterBarButtonItem: UIBarButtonItem!
    private var mapView: AGSMapView!
    private var statusLabel: UILabel!
    
    // The route task to solve the route between stops, using the online routing service.
    private let routeTask = AGSRouteTask(url: URL(string: "https://route-api.arcgis.com/arcgis/rest/services/World/Route/NAServer/Route_World")!)
    // The route result solved by the route task.
    private var routeResult: AGSRouteResult!
    // The route tracker for navigation. Use delegate methods to update tracking status.
    private var routeTracker: AGSRouteTracker!
    // A list to keep track of directions solved by the route task.
    private var directionsList: [AGSDirectionManeuver] = []

    // The original view point that can be reset later on.
    private var defaultViewPoint: AGSViewpoint?
    // The initial location for the solved route.
    private var initialLocation: AGSLocation!
    
    private var stops: [stoppointsModel]!
    
    private var AGSRouteTrackerDelegate: AGSRouteTrackerDelegate!
    private var AGSLocationChangeHandlerDelegate: AGSLocationChangeHandlerDelegate!
    
    
    // The graphic (with a dashed line symbol) to represent the route ahead.
    private var routeAheadGraphic: AGSGraphic!
    // The graphic to represent the route that's been traveled (initially empty).
    private var routeTraveledGraphic: AGSGraphic!
    // A formatter to format a time value into human readable string.
    private let timeFormatter: DateComponentsFormatter = {
       let formatter = DateComponentsFormatter()
       formatter.allowedUnits = [.hour, .minute, .second]
       formatter.unitsStyle = .full
       return formatter
   }()
    
    
    // An AVSpeechSynthesizer for text to speech.
    private let speechSynthesizer = AVSpeechSynthesizer()
    
    
    init(mapView: AGSMapView, navigateBarButtonItem: UIBarButtonItem, resetBarButtonItem: UIBarButtonItem, recenterBarButtonItem: UIBarButtonItem,statusLabel: UILabel,stops: [stoppointsModel],AGSRouteTrackerDelegate: AGSRouteTrackerDelegate,AGSLocationChangeHandlerDelegate: AGSLocationChangeHandlerDelegate) {
        
        self.mapView = mapView
        
        self.navigateBarButtonItem = navigateBarButtonItem
        self.resetBarButtonItem = resetBarButtonItem
        self.recenterBarButtonItem = recenterBarButtonItem
        self.statusLabel = statusLabel
        
        self.stops = stops
        
        self.AGSRouteTrackerDelegate = AGSRouteTrackerDelegate
        self.AGSLocationChangeHandlerDelegate = AGSLocationChangeHandlerDelegate
    }
    
    func SetRoutesUI(aheadStyleType: AGSSimpleLineSymbolStyle, aheadcolor: UIColor, aheadwidth: CGFloat, traveledStyle: AGSSimpleLineSymbolStyle, traveledColor: UIColor) {
        
        self.mapView.graphicsOverlays.removeAllObjects()
        
        routeAheadGraphic = AGSGraphic(geometry: nil, symbol: AGSSimpleLineSymbol(style: .dash, color: .systemPurple, width: aheadwidth))
        
        routeTraveledGraphic = AGSGraphic(geometry: nil, symbol: AGSSimpleLineSymbol(style: traveledStyle, color: traveledColor, width: aheadwidth))
        
        self.mapView.graphicsOverlays.add(makeRouteOverlay())
    }
    
    func ShowRouteLine() {
        // Avoid the overlap between the status label and the map content.
        mapView.contentInset.top = CGFloat(statusLabel.numberOfLines) * statusLabel.font.lineHeight

        // Solve the route as map loads.
        routeTask.defaultRouteParameters { [weak self] (params: AGSRouteParameters?, error: Error?) in
            guard let self = self else { return }
            if let params = params {
                // Explicitly set values for parameters.
                params.returnDirections = true
                params.returnStops = true
                params.returnRoutes = true
                params.outputSpatialReference = .wgs84()
                params.setStops(self.makeStops())
                self.routeTask.solveRoute(with: params) { [weak self] (result, error) in
                    if let result = result {
                        self?.didSolveRoute(with: .success(result))
                    } else if let error = error {
                        self?.didSolveRoute(with: .failure(error))
                    }
                }
            } else if error != nil {
                self.setStatus(message: "Failed to get route parameters.")
            }
        }
    }
    
    func reset() {
        // Stop the speech, if there is any.
        speechSynthesizer.stopSpeaking(at: .immediate)
        // Reset to the starting location for location display.
        mapView.locationDisplay.dataSource.didUpdate(initialLocation)
        // Stop the location display as well as datasource generation, if reset before the end is reached.
        mapView.locationDisplay.stop()
        mapView.locationDisplay.autoPanModeChangedHandler = nil
        mapView.locationDisplay.autoPanMode = .off
        directionsList.removeAll()
        setStatus(message: "Directions are shown here.")

        // Reset the navigation.
        setNavigation(with: routeResult)
        // Reset buttons state.
        resetBarButtonItem.isEnabled = false
        navigateBarButtonItem.isEnabled = true
    }
    
    func startNavigation() {
        navigateBarButtonItem.isEnabled = false
        resetBarButtonItem.isEnabled = true
        // Start the location data source and location display.
        mapView.locationDisplay.start()
    }
    
    func recenter() {
       mapView.locationDisplay.autoPanMode = .navigation
       recenterBarButtonItem.isEnabled = false
       mapView.locationDisplay.autoPanModeChangedHandler = { [weak self] _ in
           DispatchQueue.main.async {
               self?.recenterBarButtonItem.isEnabled = true
           }
           self?.mapView.locationDisplay.autoPanModeChangedHandler = nil
       }
    }
    
    // Create the stops for the navigation.
    //
    // - Returns: An array of `AGSStop` objects.
    func makeStops() -> [AGSStop] {
        let stop1 = stops[0].point
        stop1.name = stops[0].name
        let stop2 = stops[1].point
        stop2.name = stops[1].name
        
        return [stop1, stop2]
    }
    
    func updateTrackingStatusDisplay(routeTracker: AGSRouteTracker, status: AGSTrackingStatus) {
        var statusText: String
        switch status.destinationStatus {
        case .notReached, .approaching:
            let distanceRemaining = status.routeProgress.remainingDistance.displayText + " " + status.routeProgress.remainingDistance.displayTextUnits.abbreviation
            let timeRemaining = timeFormatter.string(from: TimeInterval(status.routeProgress.remainingTime * 60))!
            statusText = """
            Distance remaining: \(distanceRemaining)
            Time remaining: \(timeRemaining)
            """
            if status.currentManeuverIndex + 1 < directionsList.count {
                let nextDirection = directionsList[status.currentManeuverIndex + 1].directionText
                statusText.append("\nNext direction: \(nextDirection)")
            }
        case .reached:
            if status.remainingDestinationCount > 1 {
                statusText = "Intermediate stop reached, continue to next stop."
                routeTracker.switchToNextDestination()
            } else {
                statusText = "Final destination reached."
                mapView.locationDisplay.stop()
            }
        default:
            return
        }
        
        updateRouteGraphics(remaining: status.routeProgress.remainingGeometry, traversed: status.routeProgress.traversedGeometry)
        setStatus(message: statusText)
    }
    
    
    func hadnleLocationChange(location: AGSLocation) {
        // Update the tracker location with the new location from the simulated data source.
        routeTracker?.trackLocation(location) { [weak self] error in
            guard let self = self else { return }
            if let error = error {
                // Display error message and stop further route tracking if it
                // fails due to data format, licensing issue, etc.
                self.setStatus(message: error.localizedDescription)
                self.routeTracker = nil
            }
        }
    }
    
    
    // MARK: Instance methods
    // A wrapper function for operations after the route is solved by an `AGSRouteTask`.
    //
    // - Parameter routeResult: The result from `AGSRouteTask.solveRoute(with:completion:)`.
    private func didSolveRoute(with routeResult: Result<AGSRouteResult, Error>) {
        switch routeResult {
        case .success(let routeResult):
            self.routeResult = routeResult
            setNavigation(with: routeResult)
            navigateBarButtonItem.isEnabled = true
        case .failure(_):
            // presentAlert(error: error)
            setStatus(message: "Failed to solve route.")
            navigateBarButtonItem.isEnabled = false
        }
    }
    
    // Set route tracker, data source and location display with a solved route result.
    //
    // - Parameter routeResult: An `AGSRouteResult` object.
    private func setNavigation(with routeResult: AGSRouteResult) {
        // Set the route tracker
        routeTracker = makeRouteTracker(result: routeResult)

        // Set the mock location data source.
        let firstRoute = routeResult.routes.first!
        directionsList = firstRoute.directionManeuvers
        let mockDataSource = makeDataSource(route: firstRoute)
        
        initialLocation = mockDataSource.locations?.first
        // Create a route tracker location data source to snap the location display to the route.
        let routeTrackerLocationDataSource = AGSRouteTrackerLocationDataSource(routeTracker: routeTracker, locationDataSource: mockDataSource)

        // Set location display.
        mapView.locationDisplay.dataSource = routeTrackerLocationDataSource
        recenter()

        // Update graphics and viewpoint.
        let firstRouteGeometry = firstRoute.routeGeometry!
        updateRouteGraphics(remaining: firstRouteGeometry)
        updateViewpoint(geometry: firstRouteGeometry)
    }
    
    // Make a route tracker to provide navigation information.
    //
    // - Parameter result: An `AGSRouteResult` object used to configure the route tracker.
    // - Returns: An `AGSRouteTracker` object.
    private func makeRouteTracker(result: AGSRouteResult) -> AGSRouteTracker {
        let tracker = AGSRouteTracker(routeResult: result, routeIndex: 0, skipCoincidentStops: true)!
        tracker.delegate = AGSRouteTrackerDelegate
        tracker.voiceGuidanceUnitSystem = Locale.current.usesMetricSystem ? .metric : .imperial
        return tracker
    }
    
    // Make the simulated data source for this demo.
    //
    // - Parameter route: An `AGSRoute` object whose geometry is used to configure the data source.
    // - Returns: An `AGSSimulatedLocationDataSource` object.
    private func makeDataSource(route: AGSRoute) -> AGSSimulatedLocationDataSource {
        let densifiedRoute = AGSGeometryEngine.geodeticDensifyGeometry(route.routeGeometry!, maxSegmentLength: 50.0, lengthUnit: .meters(), curveType: .geodesic) as! AGSPolyline
        // The mock data source to demo the navigation. Use delegate methods to update locations for the tracker.
        let mockDataSource = AGSSimulatedLocationDataSource()
        mockDataSource.setLocationsWith(densifiedRoute)
        mockDataSource.locationChangeHandlerDelegate = AGSLocationChangeHandlerDelegate
        return mockDataSource
    }
    
    // Update the viewpoint so that it reflects the original viewpoint when the example is loaded.
    //
    // - Parameter result: An `AGSGeometry` object used to update the view point.
    private func updateViewpoint(geometry: AGSGeometry) {
        // Show the resulting route on the map and save a reference to the route.
        if let viewPoint = defaultViewPoint {
            // Reset to initial view point with animation.
            mapView.setViewpoint(viewPoint, completion: nil)
        } else {
            mapView.setViewpointGeometry(geometry) { [weak self] _ in
                // Get the initial zoomed view point.
                self?.defaultViewPoint = self?.mapView.currentViewpoint(with: .centerAndScale)
            }
        }
    }
    
    private func updateRouteGraphics(remaining: AGSGeometry?, traversed: AGSGeometry? = nil) {
        routeAheadGraphic.geometry = remaining
        routeTraveledGraphic.geometry = traversed
    }
    
    // MARK: UI
    private func setStatus(message: String) {
        statusLabel.text = message
    }
    
    
    // Make a graphics overlay with graphics.
    //
    // - Returns: An `AGSGraphicsOverlay` object.
    private func makeRouteOverlay() -> AGSGraphicsOverlay {
        // The graphics overlay for the polygon and points.
        let graphicsOverlay = AGSGraphicsOverlay()
        // let stopSymbol = AGSSimpleMarkerSymbol(style: .diamond, color: .orange, size: 20)
        // let stopGraphics = makeStops().map { AGSGraphic(geometry: $0.geometry, symbol: .none) }
        let routeGraphics = [routeAheadGraphic, routeTraveledGraphic]
        // Add graphics to the graphics overlay.
        graphicsOverlay.graphics.addObjects(from: routeGraphics as [Any])
        return graphicsOverlay
    }
}
