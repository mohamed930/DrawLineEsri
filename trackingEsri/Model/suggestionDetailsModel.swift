//
//  suggestionDetailsModel.swift
//  trackingEsri
//
//  Created by Mohamed Ali on 07/01/2023.
//

import Foundation

struct suggestionDetailsResponse: Codable {
    let candidates: [Candidate]
}

// MARK: - Candidate
struct Candidate: Codable {
    let address: String
    let location: Location
    let attributes: Attributes
}

struct Attributes: Codable {
    let matchAddr, type, placeAddr: String

    enum CodingKeys: String, CodingKey {
        case matchAddr = "Match_addr"
        case type = "Type"
        case placeAddr = "Place_addr"
    }
}

struct Location: Codable {
    let x, y: Double
}
