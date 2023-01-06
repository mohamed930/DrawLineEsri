//
//  userModel.swift
//  trackingEsri
//
//  Created by Mohamed Ali on 04/01/2023.
//

import Foundation

struct userModel: Codable {
    let uid: String
    let carColor: String
    let carType:  String
    let driverName: String
    let licenceNumber: String
    let password: String
    let telephone: String
}
