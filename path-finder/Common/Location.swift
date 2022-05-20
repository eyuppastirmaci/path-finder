//
//  Location.swift
//  path-finder
//
//  Created by Eyüp Pastırmacı on 20.05.2022.
//

import Foundation
import CoreLocation

class Location {
    
    static func getUserCoordinates() -> (latitude: Double, longitude: Double) {
        /* Gets and returns the user's current location values. */
        
        let locManager = CLLocationManager()
        let authorizationStatus: CLAuthorizationStatus
        
        var currentLocation : CLLocation!
        var sourceLat = 0.0
        var sourceLng = 0.0
        
        locManager.requestWhenInUseAuthorization()
        
        if #available(iOS 14, *) {
            authorizationStatus = locManager.authorizationStatus
        } else {
            authorizationStatus = CLLocationManager.authorizationStatus()
        }

        switch authorizationStatus {
            case .restricted, .denied:
            return (latitude: -91.0, longitude: -181.0)
            default:
                 currentLocation = locManager.location
                 sourceLat = currentLocation.coordinate.latitude
                 sourceLng = currentLocation.coordinate.longitude
        }
        
        return (latitude: sourceLat, longitude: sourceLng)
    }
}
