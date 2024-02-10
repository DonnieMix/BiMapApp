//
//  GoogleDirectionsModels.swift
//  BiMapApp
//
//  Created by Kyrylo Derkach on 18.09.2023.
//

import Foundation

// JSON Route getter
struct RouteResponse: Codable {
    let routes: [Route]?
}
struct Route: Codable {
    let overview_polyline: Polyline?
}
struct Polyline: Codable {
    let points: String?
}

// JSON PlaceID getter
struct GeocodingResponse: Codable {
    let results: [GeocodingResult]
}
struct GeocodingResult: Codable {
    let place_id: String
}
