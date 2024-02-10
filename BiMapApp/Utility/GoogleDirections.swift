//
//  GoogleDirections.swift
//  BiMapApp
//
//  Created by Kyrylo Derkach on 18.09.2023.
//

import Foundation
import CoreLocation
import GoogleMaps

class GoogleDirections {
    
    // Should be hidden further
    private static let apiKey = "AIzaSyBsbX0zw6P9kNRWLgY7d32io3dPKB411ZE"
    
    private static func fetchPlaceIDFromCoordinates(latitude: Double, longitude: Double, completion: @escaping (String?, Error?) -> Void) {
        
        let urlString = "https://maps.googleapis.com/maps/api/geocode/json?latlng=\(latitude),\(longitude)&key=\(apiKey)"
        
        guard let url = URL(string: urlString) else {
            completion(nil, NSError(domain: "Invalid URL", code: 0, userInfo: nil))
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                completion(nil, error)
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let geocodingResponse = try decoder.decode(GeocodingResponse.self, from: data)
                if let placeID = geocodingResponse.results.first?.place_id {
                    completion(placeID, nil)
                } else {
                    completion(nil, NSError(domain: "No such place found", code: 0, userInfo: nil))
                }
            } catch {
                completion(nil, error)
            }
        }
        
        task.resume()
    }
    
    private static func fetchDirections(from originPlaceID: String, to destinationPlaceID: String, completion: @escaping (Route?, Error?) -> Void) {
        
        let urlString = "https://maps.googleapis.com/maps/api/directions/json?origin=\(originPlaceID)&destination=\(destinationPlaceID)&key=\(apiKey)"
        guard let url = URL(string: urlString) else {
            completion(nil, NSError(domain: "Invalid URL", code: 0, userInfo: nil))
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                completion(nil, error)
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let routeResponse = try decoder.decode(RouteResponse.self, from: data)
                if let route = routeResponse.routes?.first {
                    completion(route, nil)
                } else {
                    completion(nil, NSError(domain: "No route found", code: 0, userInfo: nil))
                }
            } catch {
                completion(nil, error)
            }
        }
        
        task.resume()
    }
    
    static func placeID(latitude: Double, longitude: Double, completion: @escaping (String?) -> Void) {
        fetchPlaceIDFromCoordinates(latitude: latitude, longitude: longitude) { userPlaceID, error in
            if let userPlaceID = userPlaceID {
                completion(userPlaceID)
            } else if let error = error {
                print("Error: \(error.localizedDescription)")
                completion(nil)
            } else {
                print("Failed to obtain placeID")
                completion(nil)
            }
        }
    }
    
    static func directions(from originPlaceID: String, to destinationPlaceID: String, completion: @escaping (Route?) -> Void) {
        fetchDirections(from: "place_id:\(originPlaceID)", to: "place_id:\(destinationPlaceID)") { route, err in
            if let err = err {
                print("Error getting directions: \(err.localizedDescription)")
                completion(nil)
            } else if let route = route {
                completion(route)
            }
        }
    }
    
    static func createPolyline(for route: Route?) -> GMSPolyline? {
        guard let route = route else { return nil }
        guard let encodedPolyline = route.overview_polyline?.points else { return nil }
        
        if let path = GMSPath(fromEncodedPath: encodedPolyline) {
            let polyline = GMSPolyline(path: path)
            polyline.strokeWidth = 3.0
            polyline.strokeColor = .blue
            return polyline
        }
        
        return nil
    }
    
}
