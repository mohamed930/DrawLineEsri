//
//  suggestionModel.swift
//  trackingEsri
//
//  Created by Mohamed Ali on 07/01/2023.
//

import Foundation

struct suggestionResponse: Codable {
    let suggestions: [suggestionModel]
}

struct suggestionModel: Codable {
    let text: String
    let magicKey: String
}
