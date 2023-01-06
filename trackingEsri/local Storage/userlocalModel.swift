//
//  userModel.swift
//  trackingEsri
//
//  Created by Mohamed Ali on 05/01/2023.
//

import Foundation


struct UserlocalModel: Codable, Storeable {
    let uid: String
    let telephone: String
    let driverName: String
    let carName: String
    let liecenceNumber: String
    let password: String
    let colorName: String
    
    var storeData: Data? {
        let encoder = JSONEncoder()
        let encoded = try? encoder.encode(self)
        return encoded
    }
    
    init(telephone: String,driverName: String, carName: String, liecenceNumber: String, password: String,uid: String,colorName: String) {
        self.uid = uid
        self.telephone = telephone
        self.driverName = driverName
        self.carName = carName
        self.liecenceNumber = liecenceNumber
        self.password = password
        self.colorName = colorName
    }
    
    init?(storeData: Data?) {
        guard let storeData = storeData else { return nil }
        let decoder = JSONDecoder()
        guard let decoded = try? decoder.decode(UserlocalModel.self, from: storeData) else { return nil }
        self = decoded
    }
}
