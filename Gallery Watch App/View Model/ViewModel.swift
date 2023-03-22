//
//  ViewModel.swift
//  Gallery Watch App
//
//  Created by Mac-OBS-18 on 24/01/23.
//

import SwiftUI

class ViewModel: ObservableObject {
    
    @Published var beers: [Beer] = []

// MARK: - Network Request
    
     func getBeerDetails() {
        let request = GetBeerNetworkRequest.init()
        NetworkManager.execute(request: request, responseType: [Beer].self) { (result) in
            switch result {
            case .failure(let error):
                print(error)
            case .success(let data):
                self.beers = data
            }
        }
    }
}

