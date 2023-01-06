//
//  Search And Suggestion Controller.swift
//  trackingEsri
//
//  Created by Mohamed Ali on 06/01/2023.
//

import UIKit
import FirebaseDatabase

extension TrackCarViewController: UISearchBarDelegate , UITableViewDataSource, UITableViewDelegate {
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        suggestionView.isHidden = !suggestionView.isHidden
        searchBar.searchTextField.resignFirstResponder()
    }
    
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        suggestionView.isHidden = !suggestionView.isHidden
        loadAllCars()
        
        return true
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
        return carsList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: suggestionCell = tableView.dequeueReusableCell(withIdentifier:  cellIdentifier, for: indexPath) as! suggestionCell
        
        cell.ConfigureCell(ob: carsList[indexPath.row], currenctlati: currentlatitude, currentlong: currentlongitude)
        
        cell.deaitalsButton.tag = indexPath.row
                    cell.deaitalsButton.addTarget(self,
                    action: #selector(ShowtitleButton),
                    for: .touchUpInside)
        
        return cell
    }
    
    @objc func ShowtitleButton (_ sender:UIButton) {
        let myIndexPath = NSIndexPath(row: sender.tag, section: 0)
                    
        searchBar.searchTextField.text = carsList[myIndexPath.row].driverName
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return CGFloat(120)
    }
    
}
