//
//  TrackCarViewController.swift
//  trackingEsri
//
//  Created by Mohamed Ali on 05/01/2023.
//

import UIKit
import ArcGIS

class TrackCarViewController: UIViewController {
    
    @IBOutlet weak var map: AGSMapView!
    @IBOutlet weak var searchBar:UISearchBar!
    
    @IBOutlet weak var suggestionView: UIView!
    @IBOutlet weak var suggestionTableView: UITableView!
    
    @IBOutlet weak var routesView:UIView!
    @IBOutlet weak var routesLabel:UILabel!
    @IBOutlet weak var navigationBar:UIToolbar!
    @IBOutlet var navigateBarButtonItem: UIBarButtonItem!
    @IBOutlet var resetBarButtonItem: UIBarButtonItem!
    @IBOutlet var recenterBarButtonItem: UIBarButtonItem!
    
    let storage: LocalStorageProtocol = LocalStorage()
    var esrisdk: Esri!
    var locationManager: CLLocationManager!
    var firebase = Firebase()
    var carsList = Array<vehiclesModel>()
    var suggestionList = Array<suggestionModel>()
    let api_link = "https://geocode-api.arcgis.com/arcgis/rest/services/World/GeocodeServer/suggest"
    let api_details_link = "https://geocode.arcgis.com/arcgis/rest/services/World/GeocodeServer/findAddressCandidates"
    
    let cellIdentifier  = "Cell"
    let cellNibFileName = "carsuggestionCell"
    let placecellIdentifier  = "SuggestCell"
    let placecellNibFileName = "placeNameSuggestionCell"
    var currentlatitude  = 0.0
    var currentlongitude = 0.0
    var selectedIndexPath = 0
    var userLocation: locationModel!
    var Navi: NavigationModel!
    
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

    override func viewDidLoad() {
        super.viewDidLoad()
        
        SetMessageToUser()
        loadMap()
        ShowUserLocation()
        ConfigureLocation()
        MakeSearchBarRtl()
        ResgestertableView()
        NavigationAction()
    }
    
    func loadLocaluserData() -> UserlocalModel? {
        let userData: UserlocalModel? = storage.valueStoreable(key: LocalStorageKeys.user)
        return userData
    }
    
    func SetMessageToUser() {
        let user = loadLocaluserData()
        
        self.navigationItem.title = "اهلا يا \(user!.driverName)"
    }
    
    func loadMap() {
        esrisdk = Esri(mapView: map)
        
        esrisdk.showMap(lati: 31.2565, long: 32.2841)
    }
    
    func MakeSearchBarRtl() {
        UISearchBar.appearance().semanticContentAttribute = .forceRightToLeft
        UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).textAlignment = .right
        searchBar.delegate = self
    }
    
    func ResgestertableView() {
        suggestionTableView.dataSource = self
        suggestionTableView.delegate   = self
        
        suggestionTableView.register(UINib(nibName: cellNibFileName, bundle: nil), forCellReuseIdentifier: cellIdentifier)
        suggestionTableView.register(UINib(nibName: placecellNibFileName, bundle: nil), forCellReuseIdentifier: placecellIdentifier)
    }
    
    func NavigationAction() {
        navigationBar.isHidden = true
        routesView.isHidden   = true
        routesView.layer.cornerRadius = 7
        routesView.layer.masksToBounds = true
    }
    
    @IBAction func navigationButtonAction(_ sender: Any) {
        routesView.isHidden = false
        Navi.startNavigation()
    }
    
    @IBAction func stopNavigationButtonAction(_ sender: Any) {
        routesView.isHidden = true
        Navi.reset()
    }
    
    @IBAction func recenterButtonAction(_ sender: Any) {
        Navi.recenter()
    }
}
