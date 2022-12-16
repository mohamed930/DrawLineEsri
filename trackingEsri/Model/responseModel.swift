//
//  responseModel.swift
//  trackingEsri
//
//  Created by Mohamed Ali on 15/12/2022.
//

import Foundation

struct responseModel: Codable {
    var bestRoute: [locationModel]
    var target: pointDataModel
    var vehicals: pointDataModel
}

struct pointDataModel: Codable {
    var name: String
    var location: locationModel
}

struct locationModel: Codable {
    var lati: Double
    var long: Double
}
