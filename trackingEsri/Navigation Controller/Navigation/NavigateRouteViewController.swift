//
//  NavigateRouteViewController.swift
//  trackingEsri
//
//  Created by Mohamed Ali on 25/12/2022.
//

import UIKit
import AVFoundation
import ArcGIS

class NavigateRouteViewController: UIViewController {
    
    // MARK: Storyboard views

    // The label to display navigation status.
    @IBOutlet var statusLabel: UILabel!
    // The button to start navigation.
    @IBOutlet var navigateBarButtonItem: UIBarButtonItem!
    // The button to reset navigation.
    @IBOutlet var resetBarButtonItem: UIBarButtonItem!
    // The button to recenter the map to navigation pan mode.
    @IBOutlet var recenterBarButtonItem: UIBarButtonItem!
    // The map view managed by the view controller.
    @IBOutlet var mapView: AGSMapView! {
        didSet {
            mapView.map = AGSMap(basemapStyle: .arcGISNavigation)
            mapView.graphicsOverlays.add(makeRouteOverlay())
        }
    }
    
    // MARK: Instance properties

    // The route task to solve the route between stops, using the online routing service.
    let routeTask = AGSRouteTask(url: URL(string: "https://route-api.arcgis.com/arcgis/rest/services/World/Route/NAServer/Route_World")!)
    // The route result solved by the route task.
    var routeResult: AGSRouteResult!
    // The route tracker for navigation. Use delegate methods to update tracking status.
    var routeTracker: AGSRouteTracker!
    // A list to keep track of directions solved by the route task.
    var directionsList: [AGSDirectionManeuver] = []

    // The original view point that can be reset later on.
    var defaultViewPoint: AGSViewpoint?
    // The initial location for the solved route.
    var initialLocation: AGSLocation!

    // The graphic (with a dashed line symbol) to represent the route ahead.
    let routeAheadGraphic = AGSGraphic(geometry: nil, symbol: AGSSimpleLineSymbol(style: .dash, color: .systemPurple, width: 5))
    // The graphic to represent the route that's been traveled (initially empty).
    let routeTraveledGraphic = AGSGraphic(geometry: nil, symbol: AGSSimpleLineSymbol(style: .solid, color: .systemBlue, width: 3))
    // A formatter to format a time value into human readable string.
    let timeFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .full
        return formatter
    }()
    // An AVSpeechSynthesizer for text to speech.
    let speechSynthesizer = AVSpeechSynthesizer()
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Only reset when the route is successfully solved.
        if routeResult != nil {
            reset()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

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
    
    // Create the stops for the navigation.
    //
    // - Returns: An array of `AGSStop` objects.
    func makeStops() -> [AGSStop] {
        // 31.263520, 32.306828
        let stop1 = AGSStop(point: AGSPoint(x: 32.320587, y: 31.244030, spatialReference: .wgs84()))
        stop1.name = "car start"
        let stop2 = AGSStop(point: AGSPoint(x: 32.306828, y: 31.263520, spatialReference: .wgs84()))
        stop2.name = "supermarket"
        
        return [stop1, stop2]
    }
    
    // MARK: Instance methods

    // A wrapper function for operations after the route is solved by an `AGSRouteTask`.
    //
    // - Parameter routeResult: The result from `AGSRouteTask.solveRoute(with:completion:)`.
    func didSolveRoute(with routeResult: Result<AGSRouteResult, Error>) {
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
    func setNavigation(with routeResult: AGSRouteResult) {
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
    func makeRouteTracker(result: AGSRouteResult) -> AGSRouteTracker {
        let tracker = AGSRouteTracker(routeResult: result, routeIndex: 0, skipCoincidentStops: true)!
        tracker.delegate = self
        tracker.voiceGuidanceUnitSystem = Locale.current.usesMetricSystem ? .metric : .imperial
        return tracker
    }
    
    // Make the simulated data source for this demo.
    //
    // - Parameter route: An `AGSRoute` object whose geometry is used to configure the data source.
    // - Returns: An `AGSSimulatedLocationDataSource` object.
    func makeDataSource(route: AGSRoute) -> AGSSimulatedLocationDataSource {
        let densifiedRoute = AGSGeometryEngine.geodeticDensifyGeometry(route.routeGeometry!, maxSegmentLength: 50.0, lengthUnit: .meters(), curveType: .geodesic) as! AGSPolyline
        // The mock data source to demo the navigation. Use delegate methods to update locations for the tracker.
        let mockDataSource = AGSSimulatedLocationDataSource()
        mockDataSource.setLocationsWith(densifiedRoute)
        mockDataSource.locationChangeHandlerDelegate = self
        return mockDataSource
    }
    
    // Update the viewpoint so that it reflects the original viewpoint when the example is loaded.
    //
    // - Parameter result: An `AGSGeometry` object used to update the view point.
    func updateViewpoint(geometry: AGSGeometry) {
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
    
    func updateRouteGraphics(remaining: AGSGeometry?, traversed: AGSGeometry? = nil) {
        routeAheadGraphic.geometry = remaining
        routeTraveledGraphic.geometry = traversed
    }
    
    // MARK: UI

    func setStatus(message: String) {
        statusLabel.text = message
    }
    
    
    // Make a graphics overlay with graphics.
    //
    // - Returns: An `AGSGraphicsOverlay` object.
    func makeRouteOverlay() -> AGSGraphicsOverlay {
        // The graphics overlay for the polygon and points.
        let graphicsOverlay = AGSGraphicsOverlay()
        let stopSymbol = AGSSimpleMarkerSymbol(style: .diamond, color: .orange, size: 20)
        let stopGraphics = makeStops().map { AGSGraphic(geometry: $0.geometry, symbol: stopSymbol) }
        let routeGraphics = [routeAheadGraphic, routeTraveledGraphic]
        // Add graphics to the graphics overlay.
        graphicsOverlay.graphics.addObjects(from: routeGraphics + stopGraphics)
        return graphicsOverlay
    }
    

    // MARK: Actions

    /// Called in response to the "Navigate" button being tapped.
    @IBAction func startNavigation() {
        navigateBarButtonItem.isEnabled = false
        resetBarButtonItem.isEnabled = true
        // Start the location data source and location display.
        mapView.locationDisplay.start()
    }
    
    // Called in response to the "Reset" button being tapped.
    @IBAction func reset() {
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

    // Called in response to the "Recenter" button being tapped.
    @IBAction func recenter() {
        mapView.locationDisplay.autoPanMode = .navigation
        recenterBarButtonItem.isEnabled = false
        mapView.locationDisplay.autoPanModeChangedHandler = { [weak self] _ in
            DispatchQueue.main.async {
                self?.recenterBarButtonItem.isEnabled = true
            }
            self?.mapView.locationDisplay.autoPanModeChangedHandler = nil
        }
    }


    
}
