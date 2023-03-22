//
//  BeerModel.swift
//  Gallery Watch App
//
//  Created by Mac-OBS-18 on 22/03/23.
//

import Foundation
// MARK: - Beer Model

struct Beer: Hashable, Codable, Identifiable {
    let price, name: String
    let rating: Rating
    let image: String
    let id: Int
}

struct Rating: Hashable, Codable {
    let average: Double
    let reviews: Int
}
