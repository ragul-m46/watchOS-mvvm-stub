//
//  ContentView.swift
//  Gallery Watch App
//
//  Created by Mac-OBS-18 on 12/01/23.
//

import SwiftUI

struct URLImage: View {
    
    @State var data: Data?
    var beer: [Beer]?
    let urlString: String
    
    var body: some View {
        if let data = data, let beerImage = UIImage(data: data) {
            Image(uiImage: beerImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .cornerRadius(20)
                .frame(width: 80, height: 50)
                .foregroundColor(.accentColor)
        }
        else {
            Image(systemName: "photo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .cornerRadius(20)
                .frame(width: 80, height: 50)
                .foregroundColor(.gray)
                .onAppear{
                    fetchData()
                }
        }
    }
    private func fetchData() {
        guard let url = URL(string: urlString) else {
            return
        }
        let task = URLSession.shared.dataTask(with: url) { data, _, _ in
            self.data = data
        }
        task.resume()
    }
}


struct ContentView: View {
    
    @StateObject var viewModel = ViewModel()
    
    var body: some View {
        NavigationView {
            List(viewModel.beers) { beer in
                    HStack {
                        URLImage(urlString: beer.image)
                        
                        Text(beer.name)
                            .multilineTextAlignment(.leading)
                }
                
            }
            .navigationTitle("Beers 🍻")
            .onAppear{
                viewModel.getBeerDetails()
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
