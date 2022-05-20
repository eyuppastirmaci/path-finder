//
//  Map.swift
//  path-finder
//
//  Created by Eyüp Pastırmacı on 20.05.2022.
//

import Foundation
import UIKit
import GoogleMaps
import Alamofire
import SwiftyJSON

class Map {
    
    static func drawRoute(destinationLatitude: Double, destinationLongitude: Double, mapView: GMSMapView) {
        /* Draw route path ono the google maps. */
        
        mapView.clear()
        
        let userCoordinates = Location.getUserCoordinates()
        
        let destinationLat = destinationLatitude
        let destinationLng = destinationLongitude
        
        let sourceLocation = "\(userCoordinates.latitude),\(userCoordinates.longitude)"
        let destinationLocation = "\(destinationLat),\(destinationLng)"
       
        let url = "https://maps.googleapis.com/maps/api/directions/json?origin=\(sourceLocation)&destination=\(destinationLocation)&mode=driving&key=\(Keys.GOOGLE_API_KEY)"
        
        AF.request(url).responseJSON { (response) in
            guard let data = response.data else {
                print("Can't connect to googleapi.")
                return
            }
            
            do {
                let jsonData = try JSON(data: data)
                let routes = jsonData["routes"].arrayValue
                
                for route in routes {
                    let overview_polyline = route["overview_polyline"].dictionary
                    let points = overview_polyline?["points"]?.string
                    let path = GMSPath.init(fromEncodedPath: points ?? "")
                    let polyline = GMSPolyline.init(path: path)
                    polyline.strokeColor = .blue
                    polyline.strokeWidth = 5
                    polyline.map = mapView
                }
                
            } catch let error {
               print("Couldn't draw path.")
            }
        }
        
        let sourceMarker = GMSMarker()
        sourceMarker.position = CLLocationCoordinate2D(latitude: userCoordinates.latitude, longitude: userCoordinates.longitude)
        sourceMarker.title = "Current Location"
        sourceMarker.map = mapView
        
        let destinationMarker = GMSMarker()
        destinationMarker.position = CLLocationCoordinate2D(latitude: destinationLat, longitude: destinationLng)
        destinationMarker.title = "Target Location"
        destinationMarker.map = mapView
        
        let camera = GMSCameraPosition(target: sourceMarker.position, zoom: 15)
        mapView.animate(to: camera)
    }
}
