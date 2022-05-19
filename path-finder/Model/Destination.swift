//
//  Destination.swift
//  path-finder
//
//  Created by Eyüp Pastırmacı on 20.05.2022.
//

import Foundation

class Destination {
    let description: String
    let latitude, longitude: Double
    
    init (description: String, latitude: Double, longitude: Double) {
        self.description = description
        self.latitude = latitude
        self.longitude = longitude
    }
}
