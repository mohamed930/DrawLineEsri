//
//  testRouteViewController.swift
//  trackingEsri
//
//  Created by Mohamed Ali on 08/01/2023.
//

import UIKit
import ArcGIS

class testRouteViewController: UIViewController{

    @IBOutlet weak var mapView: AGSMapView!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupMap()

        addGraphics()

        navigationItem.rightBarButtonItem = directionsButton

    }

    private func setupMap() {

        mapView.touchDelegate = self

        mapView.map = AGSMap(basemapStyle: .arcGISNavigation)
        mapView.setViewpoint(
            AGSViewpoint(
                latitude: 34.05293,
                longitude: -118.24368,
                scale: 288_895
            )
        )
    }

    // MARK: - Route Graphics

    private let startGraphic: AGSGraphic = {
        let symbol = AGSSimpleMarkerSymbol(style: .circle, color: .white, size: 8)
        symbol.outline = AGSSimpleLineSymbol(style: .solid, color: .black, width: 1)
        let graphic = AGSGraphic(geometry: nil, symbol: symbol)
        return graphic
    }()

    private let endGraphic: AGSGraphic = {
        let symbol = AGSSimpleMarkerSymbol(style: .circle, color: .black, size: 8)
        symbol.outline = AGSSimpleLineSymbol(style: .solid, color: .black, width: 1)
        let graphic = AGSGraphic(geometry: nil, symbol: symbol)
        return graphic
    }()

    private let routeGraphic: AGSGraphic = {
        let symbol = AGSSimpleLineSymbol(style: .solid, color: .blue, width: 3)
        let graphic = AGSGraphic(geometry: nil, symbol: symbol)
        return graphic
    }()

    private func addGraphics() {
        let routeGraphics = AGSGraphicsOverlay()
        mapView.graphicsOverlays.add(routeGraphics)
        routeGraphics.graphics.addObjects(from: [routeGraphic, startGraphic, endGraphic])
    }

    // MARK: - Route Builder

    private enum RouteBuilderStatus {
        case none
        case selectedStart(AGSPoint)
        case selectedStartAndEnd(AGSPoint, AGSPoint)
        case routeSolved(AGSPoint, AGSPoint, AGSRoute)

        func nextStatus(with point: AGSPoint) -> RouteBuilderStatus {
            switch self {
            case .none:
                return .selectedStart(point)
            case .selectedStart(let start):
                return .selectedStartAndEnd(start, point)
            case .selectedStartAndEnd:
                return .selectedStart(point)
            case .routeSolved:
                return .selectedStart(point)
            }
        }

    }

    private var status: RouteBuilderStatus = .none {
        didSet {
            switch status {
            case .none:
                startGraphic.geometry = nil
                endGraphic.geometry = nil
                routeGraphic.geometry = nil
                directionsButton.isEnabled = false
            case .selectedStart(let start):
                startGraphic.geometry = start
                endGraphic.geometry = nil
                routeGraphic.geometry = nil
                directionsButton.isEnabled = false
            case .selectedStartAndEnd(let start, let end):
                startGraphic.geometry = start
                endGraphic.geometry = end
                routeGraphic.geometry = nil
                directionsButton.isEnabled = false
            case .routeSolved(let start, let end, let route):
                startGraphic.geometry = start
                endGraphic.geometry = end
                routeGraphic.geometry = route.routeGeometry
                directionsButton.isEnabled = true
            }
        }
    }

    // MARK: - Directions Button

    private lazy var directionsButton: UIBarButtonItem = {
        let button = UIBarButtonItem(title: "Show Directions", style: .plain, target: self, action: #selector(displayDirections))
        button.isEnabled = false
        return button
    }()

    @objc
    func displayDirections(_ sender: AnyObject) {
        guard case let .routeSolved(_, _, route) = status else { return }
        let directions = route.directionManeuvers.enumerated()
            .reduce(into: "\n") { $0 += "\($1.offset + 1). \($1.element.directionText).\n\n" }
        let alert = UIAlertController(title: "Directions", message: directions, preferredStyle: .alert)
        let okay = UIAlertAction(title: "Hide Directions", style: .default, handler: nil)
        alert.addAction(okay)
        present(alert, animated: true, completion: nil)
    }

    // MARK: - Route Task

    private let routeTask: AGSRouteTask = {
        let worldRoutingService = URL(string: "https://route-api.arcgis.com/arcgis/rest/services/World/Route/NAServer/Route_World")!
        return AGSRouteTask(url: worldRoutingService)
    }()

    private var currentSolveRouteOperation: AGSCancelable?

    private func solveRoute(start: AGSPoint, end: AGSPoint, completion: @escaping (Result<[AGSRoute], Error>) -> Void) {

        currentSolveRouteOperation?.cancel()

        currentSolveRouteOperation = routeTask.defaultRouteParameters { [weak self] (defaultParameters, error) in
            guard let self = self else { return }
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let params = defaultParameters else { return }
            params.returnDirections = true
            params.setStops([AGSStop(point: start), AGSStop(point: end)])

            self.currentSolveRouteOperation = self.routeTask.solveRoute(with: params) { (routeResult, error) in
                if let routes = routeResult?.routes {
                    completion(.success(routes))
                } else if let error = error {
                    completion(.failure(error))
                }
            }

        }

    }

}

// MARK: - GeoView Touch Delegate

extension testRouteViewController: AGSGeoViewTouchDelegate {

    func geoView(_ geoView: AGSGeoView, didTapAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {

        currentSolveRouteOperation?.cancel()

        status = status.nextStatus(with: mapPoint)

        if case let .selectedStartAndEnd(start, end) = status {
            solveRoute(start: start, end: end) { [weak self] (result) in
                guard let self = self else { return }
                switch result {
                case .failure(let error):
                    print(error.localizedDescription)
                    self.status = .none
                case .success(let routes):
                    if let route = routes.first {
                        self.status = .routeSolved(start, end, route)
                    } else {
                        self.status = .none
                    }
                }
            }
        }

    }

}
