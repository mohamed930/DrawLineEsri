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

    override func viewDidLoad() {
        super.viewDidLoad()
        
        SetMessageToUser()
        loadMap()
        ShowUserLocation()
        ConfigureLocation()
        MakeSearchBarRtl()
        ResgestertableView()
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
}
