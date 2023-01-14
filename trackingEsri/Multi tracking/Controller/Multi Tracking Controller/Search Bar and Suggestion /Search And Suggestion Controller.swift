//
//  Search And Suggestion Controller.swift
//  trackingEsri
//
//  Created by Mohamed Ali on 06/01/2023.
//

import UIKit
import FirebaseDatabase
import Alamofire
import ArcGIS

extension TrackCarViewController: UISearchBarDelegate , UITableViewDataSource, UITableViewDelegate {
    
    // MARK: TODO: This Method For Handle SearchButton In Keypad.
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if searchBar.searchTextField.text!.contains(",") {
            SearchDetailsPlaceAndShowOnMap(suggestId: suggestionList[selectedIndexPath].magicKey)
        }
        else {
            ListenToCarMoving(carId: carsList[selectedIndexPath].uuid)
        }
    }
    // -------------------------------------------
    
    
    // MARK: TODO: This Method Recognize user beging the search show all car suggestion near him
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        suggestionView.isHidden = !suggestionView.isHidden
        loadAllCars()
        
        return true
    }
    // -------------------------------------------
    
    
    
    // MARK: TODO: This Method for when user start typing give him some suggestion from Esri API.
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        // load Suggesstions from Esri Api.
        if searchBar.searchTextField.text != "" {
            let params = [
                            "text": searchBar.searchTextField.text!,
                            "f": "json",
                            "token": esrisdk.getApiKey(),
                            "countryCode": "EGY"
                         ]
            
            AF.request(api_link, method: .get, parameters: params).response { [weak self] response in
                
                guard let self = self else { return }
                
                guard let statusCode = response.response?.statusCode else { return }
                
                if statusCode == 200 {
                    guard let theJSONData =  response.data else { return }
                    guard let responseObj = try? JSONDecoder().decode(suggestionResponse.self, from: theJSONData) else { return }
                    
                    self.suggestionList = responseObj.suggestions
                    self.suggestionTableView.reloadData()
                }
                else {
                    print("error in fetching")
                }
                
            }
        }
        // Return to show the car suggestion
        else {
            suggestionView.isHidden = false
            suggestionTableView.reloadData()
        }
    }
    // -------------------------------------------
    
    
    // MARK: TODO: This Method For Load all car from firebase and show it to user in tableView.
    func loadAllCars() {
        
        let user = loadLocaluserData()
        carsList.removeAll()
        
        firebase.SetRefernce(ref: Database.database().reference().child("vehicles"))
        firebase.observerDataWithoutListner { [weak self] snapshot in
            
            guard let self = self else { return }
            
            guard let value = snapshot.value as? Dictionary<String,Any> else {
                print("Error in fetch")
                return
            }
            
            var dictArr = [[String:Any]]()
            for i in value.values {
                dictArr.append(i as! [String:Any])
            }
            
            let jsonData = dictArr.toJSONString().data(using: String.Encoding.utf8)
            
            guard let responseObj = try? JSONDecoder().decode([vehiclesModel].self, from: jsonData!) else {
                print("Error in Decode")
                return}
            
            for i in responseObj {
                if i.uuid != user!.uid {
                    self.carsList.append(i)
                }
            }
            
            self.suggestionTableView.reloadData()
        }
    }
    // -------------------------------------------
    
    
    
    // MARK: TODO: This Mwthod for Load items in table based on searchBar status.
    // -------------------------------------------
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchBar.searchTextField.text == "" {
            return carsList.count
        }
        else {
            return suggestionList.count
        }
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if searchBar.searchTextField.text == "" {
            let cell: carsuggestionCell = tableView.dequeueReusableCell(withIdentifier:  cellIdentifier, for: indexPath) as! carsuggestionCell
            
            if carsList.count == 0 {
                return cell
            }
            
            cell.ConfigureCell(ob: carsList[indexPath.row], currenctlati: currentlatitude, currentlong: currentlongitude)
            
            cell.deaitalsButton.tag = indexPath.row
                        cell.deaitalsButton.addTarget(self,
                        action: #selector(ShowtitleButton),
                        for: .touchUpInside)
            
            return cell
        }
        else {
            let cell: placeNameSuggestionCell = tableView.dequeueReusableCell(withIdentifier:  placecellIdentifier, for: indexPath) as! placeNameSuggestionCell
            
            cell.ConfigureCell(ob: suggestionList[indexPath.row])
            
            cell.copyTextButton.tag = indexPath.row
                        cell.copyTextButton.addTarget(self,
                        action: #selector(ShowtitleButton),
                        for: .touchUpInside)
            
            return cell
        }
        
    }
    // -------------------------------------------
    
    
    // MARK: TODO: This Method For Action the show title button in custom Cell.
    @objc func ShowtitleButton (_ sender:UIButton) {
        let myIndexPath = NSIndexPath(row: sender.tag, section: 0)
        
        selectedIndexPath = myIndexPath.row
        
        if ((suggestionTableView.cellForRow(at: myIndexPath as IndexPath) as? carsuggestionCell) != nil) {
            searchBar.searchTextField.text = carsList[myIndexPath.row].driverName
        }
        else {
            searchBar.searchTextField.text = suggestionList[myIndexPath.row].text
        }
    }
    // -------------------------------------------
    
    
    
    // MARK: TODO: This Method For Show button to call the captin of car if user want it.
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        if (tableView.cellForRow(at: indexPath) as? carsuggestionCell) != nil {
            let contextItem = UIContextualAction(style: .normal, title: "") { [weak self]  (contextualAction, view, boolValue) in
                //Code I want to do here
                guard let self = self else { return }
                
                if let url = NSURL(string: "tel://\(self.carsList[indexPath.row].telephone)"), UIApplication.shared.canOpenURL(url as URL) {
                    UIApplication.shared.open(url as URL, options: [:], completionHandler: nil)
                }
                
                boolValue(false)
                
            }
             
            contextItem.image = UIImage(systemName: "phone.fill")
             
            contextItem.backgroundColor = .black
             
            let swipeActions = UISwipeActionsConfiguration(actions: [contextItem])
             
            return swipeActions
        }
        else {
            return nil
        }
    }
    // -------------------------------------------
    
    
    
    
    // MARK: TODO: This Method For tableView to handle the cell tapped in tableView
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        // in case the searchBar have place name show the place in map as an static place
        if ((suggestionTableView.cellForRow(at: indexPath) as? placeNameSuggestionCell) != nil) {
            selectedIndexPath = indexPath.row
            let suggestId = suggestionList[selectedIndexPath].magicKey
            searchBar.searchTextField.text = suggestionList[selectedIndexPath].text
            SearchDetailsPlaceAndShowOnMap(suggestId: suggestId)
        }
        // in case the searchBar have car captine show the car in map as an dynamic place
        else {
            selectedIndexPath = indexPath.row
            let id = carsList[selectedIndexPath].uuid
            
            searchBar.searchTextField.text = carsList[selectedIndexPath].driverName
            ListenToCarMoving(carId: id)
        }
    }
    // -------------------------------------------
    
    
    
    
    // MARK: TODO: This Place load the place point in the map and show the route between of them
    func SearchDetailsPlaceAndShowOnMap(suggestId: String) {
        searchBar.searchTextField.resignFirstResponder()
        suggestionView.isHidden = !suggestionView.isHidden
        
        let params = [
                        "magicKey": suggestId,
                        "outFields": "Match_addr,Type,Place_addr",
                        "f": "json",
                        "token": esrisdk.getApiKey()
                     ]
        
        AF.request(api_details_link, method: .get, parameters: params).response { [weak self] response in
            guard let self = self else { return }
            
            guard let statusCode = response.response?.statusCode else { return }
            
            if statusCode == 200 {
                guard let theJSONData =  response.data else { return }
                guard let responseObj = try? JSONDecoder().decode(suggestionDetailsResponse.self, from: theJSONData) else { return }
                
                let attr = [
                            "address": responseObj.candidates[0].attributes.matchAddr,
                            "Type": responseObj.candidates[0].attributes.type,
                            "Place_addr": responseObj.candidates[0].attributes.placeAddr
                           ] as! [String:AnyObject]
                
                
                if self.esrisdk.points.count == 2 {
                    let graphic = self.esrisdk.getGraphicsOverlay()
                    graphic.graphics.removeLastObject()
                    self.esrisdk.setGraphicsOverlay(graphicsOverlay: graphic)
                    self.esrisdk.points.removeLast()
                }
                
                
                self.esrisdk.AddPointOnMap(point: AGSPoint(x: responseObj.candidates[0].location.x, y: responseObj.candidates[0].location.y, spatialReference: .wgs84()), attribute: attr)
                
                self.navigationBar.isHidden = false
                
                self.LoadRoute(detinationPlace: locationModel(lati: responseObj.candidates[0].location.y, long: responseObj.candidates[0].location.x),detinationName: responseObj.candidates[0].attributes.placeAddr)
                
            }
            else {
                print("error in fetching")
            }
        }
    }
    // -------------------------------------------
    
    
    
    
    // MARK: TODO: This Method Add Listner To car and track it on the map.
    func ListenToCarMoving(carId: String) {
        
        suggestionView.isHidden = !suggestionView.isHidden
        searchBar.searchTextField.resignFirstResponder()
        
        firebase.SetRefernce(ref: Database.database().reference().child("vehicles").child(carId))
        
        firebase.observeDataWithListner { [weak self] snapshot in
            guard let self = self else { return }
            
            guard let value = snapshot.value else {
                print("Error in fetch")
                return
            }
            
            guard let jsonData = try? JSONSerialization.data(withJSONObject: value, options: []) else { return }
            
            guard let responseObj = try? JSONDecoder().decode(vehiclesModel.self, from: jsonData) else {
                print("Error in Decode")
                return}
            
            print("driverName: \(responseObj.driverName) , location: (\(responseObj.latitude),\(responseObj.longitude)")
            

            if self.esrisdk.points.count == 2 {
                let ngraphic = self.esrisdk.getGraphicsOverlay()
                ngraphic.graphics.removeLastObject()
                self.esrisdk.setGraphicsOverlay(graphicsOverlay: ngraphic)
                self.esrisdk.points.removeLast()
            }
            
            let data = ["driveName": responseObj.driverName, "carType": responseObj.cartype, "telephone": responseObj.telephone] as! [String: AnyObject]
            

            self.esrisdk.AddPointOnMap(point: AGSPoint(x: responseObj.longitude, y: responseObj.latitude, spatialReference: .wgs84()), attribute: data)
            
            self.navigationBar.isHidden = false
            
            self.LoadRoute(detinationPlace: locationModel(lati: responseObj.latitude, long: responseObj.longitude),detinationName: responseObj.driverName)
            
        }
    }
    // -------------------------------------------
    
    func LoadRoute(detinationPlace: locationModel,detinationName: String) {
        let stops = [stoppointsModel(
                                        point: AGSStop(point: AGSPoint(x: userLocation.long, y: userLocation.lati, spatialReference: .wgs84())),
                                        name: "your location"
                                    ),
                     stoppointsModel(
                                        point: AGSStop(point: AGSPoint(x: detinationPlace.long, y: detinationPlace.lati, spatialReference: .wgs84())),
                                        name: detinationName
                                    )
                    ]
        
        
        Navi = NavigationModel(
                                   mapView: map,
                                   navigateBarButtonItem: navigateBarButtonItem,
                                   resetBarButtonItem: resetBarButtonItem,
                                   recenterBarButtonItem: recenterBarButtonItem,
                                   statusLabel: routesLabel,
                                   stops: stops,
                                   AGSRouteTrackerDelegate: self,
                                   AGSLocationChangeHandlerDelegate: self
                                  )
        
        
        Navi.SetRoutesUI(aheadStyleType: .solid, aheadcolor: .blue, aheadwidth: 5, traveledStyle: .solid, traveledColor: .red)
        
        Navi.ShowRouteLine()
    }
}
