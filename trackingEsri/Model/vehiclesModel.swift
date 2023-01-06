//
//  vehiclesModel.swift
//  trackingEsri
//
//  Created by Mohamed Ali on 06/01/2023.
//

import Foundation

struct vehiclesModel: Codable {
    let cartype, driverName: String
    let latitude, longitude: Double
    let telephone, uuid: String
}
