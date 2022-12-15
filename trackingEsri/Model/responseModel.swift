//
//  responseModel.swift
//  trackingEsri
//
//  Created by Mohamed Ali on 15/12/2022.
//

import Foundation

struct responseModel: Codable {
    var name: String
    var location: locationModel
}

struct locationModel: Codable {
    var lati: Double
    var long: Double
}
