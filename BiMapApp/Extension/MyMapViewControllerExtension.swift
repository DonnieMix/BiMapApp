//
//  MyMapViewController.swift
//  BiMapApp
//
//  Created by Kyrylo Derkach on 18.09.2023.
//

import Foundation
import GoogleMaps
import MapKit

extension MyMapViewController: GMSMapViewDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if [.denied, .notDetermined, .restricted].contains(manager.authorizationStatus) {
            googleMapsMarker.map = nil
            return
        }
        guard let userLocation = userLocation else { return }
        googleMapsUserMarker.position = CLLocationCoordinate2D(latitude: userLocation.coordinate.latitude, longitude: userLocation.coordinate.longitude)
        googleMapsUserMarker.title = "Your Location"
        googleMapsUserMarker.icon = UIImage(systemName: "location.north.fill")
        googleMapsUserMarker.map = googleMapsMapView
    }
}
extension MyMapViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKPolyline {
            let renderer = MKPolylineRenderer(overlay: overlay)
            renderer.strokeColor = UIColor.blue
            renderer.lineWidth = 3.0
            return renderer
        }
        return MKOverlayRenderer(overlay: overlay)
    }
}
extension MyMapViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            userLocation = location
            guard let userLocation = userLocation else { return }
            googleMapsUserMarker.position = CLLocationCoordinate2D(latitude: userLocation.coordinate.latitude, longitude: userLocation.coordinate.longitude)
        }
    }
}
