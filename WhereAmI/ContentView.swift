//
//  ContentView.swift
//  WhereAmI
//
//  Created by exey on 24.06.2024.
//

import SwiftUI

struct ContentView: View {
    
    @StateObject var geoMLModel: GeoMLModel = .init()
    
    var body: some View {
        List {
            ForEach(geoMLModel.images) { data in
                HStack {
                    Image(data.name)
                        .resizable()
                        .frame(width: 300, height: 300)
                        .scaledToFit()
                        .clipped()
                    Divider()
                    Text(data.label)
                        .font(.title3)
                }
            }
            .onAppear() {
                geoMLModel.detect()
            }
        }
    }
}

#Preview {
    ContentView()
}
