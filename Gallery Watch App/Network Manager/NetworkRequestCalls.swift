//
//  NetworkRequestCalls.swift
//  Gallery Watch App
//
//  Created by Mac-OBS-18 on 25/01/23.
//

import Foundation
import UIKit


public typealias Parameter = [String: String]
public typealias JSON = [String: Any]


final class GetBeerNetworkRequest: NetworkRequest {
    init() {
        
        super.init(.get, authorizationRequirement: .never)
        path = "beers/ale"

    }
}


