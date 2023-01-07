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
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if searchBar.searchTextField.text!.contains(",") {
            SearchDetailsPlaceAndShowOnMap(suggestId: suggestionList[selectedIndexPath].magicKey)
        }
        else {
            searchBar.searchTextField.resignFirstResponder()
            suggestionView.isHidden = !suggestionView.isHidden
        }
    }
    
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        suggestionView.isHidden = !suggestionView.isHidden
        loadAllCars()
        
        return true
    }
    
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
        else {
            suggestionView.isHidden = false
            suggestionTableView.reloadData()
        }
    }
    
    
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
    
    @objc func ShowtitleButton (_ sender:UIButton) {
        let myIndexPath = NSIndexPath(row: sender.tag, section: 0)
        
        if (searchBar.searchTextField.text == "") {
            searchBar.searchTextField.text = carsList[myIndexPath.row].driverName
        }
        else {
            searchBar.searchTextField.text = suggestionList[myIndexPath.row].text
        }
                    
        
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        if searchBar.searchTextField.text == "" {
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
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if searchBar.searchTextField.text != "" {
            selectedIndexPath = indexPath.row
            let suggestId = suggestionList[selectedIndexPath].magicKey
            searchBar.searchTextField.text = suggestionList[selectedIndexPath].text
            SearchDetailsPlaceAndShowOnMap(suggestId: suggestId)
        }
        else {
            
        }
    }
    
    
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
                
                let graphic = self.esrisdk.getGraphicsOverlay()
                if graphic.graphics.count == 2 {
                    graphic.graphics.removeLastObject()
                    self.esrisdk.setGraphicsOverlay(graphicsOverlay: graphic)
                    self.esrisdk.points.removeLast()
                }
                
                self.esrisdk.AddPointOnMap(point: AGSPoint(x: responseObj.candidates[0].location.x, y: responseObj.candidates[0].location.y, spatialReference: .wgs84()), attribute: attr)
                
                self.esrisdk.getDefaultParameters()
                
            }
            else {
                print("error in fetching")
            }
        }
    }
}
