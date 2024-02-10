//
//  MapViewController.swift
//  BiMapApp
//
//  Created by Kyrylo Derkach on 17.09.2023.
//

import Foundation
import UIKit
import MapKit
import GoogleMaps
import CoreLocation
import GooglePlaces

class MyMapViewController: UIViewController {
    // outlets
    @IBOutlet weak var interfaceView: UIView!
    @IBOutlet weak var mapContainerView: UIView!
    @IBOutlet weak var searchLocationTextField: UITextField!
    @IBOutlet weak var mapProviderSwitch: UISegmentedControl!
    @IBOutlet weak var mapTypeSwitch: UISegmentedControl!
    @IBOutlet weak var toUserLocationButton: UIButton!
    
    // MapKit
    private var mapKitMapView: MKMapView!
    var mapKitPointAnnotation: MKPointAnnotation = MKPointAnnotation()
    var mapKitOverlay: MKOverlay = MKPolyline()
    
    // GMS
    @IBOutlet internal var googleMapsMapView: GMSMapView!
    var googleMapsMarker: GMSMarker = GMSMarker()
    var googleMapsUserMarker: GMSMarker = GMSMarker()
    private var placesClient: GMSPlacesClient!
    private var googleMapsPolyline: GMSPolyline = GMSPolyline()
    
    // CoreLocation
    var geocoder = CLGeocoder()
    var searchTimer: Timer?
    private let locationManager = CLLocationManager()
    var userLocation: CLLocation?
    
    var currentMap = Provider.MapKit
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // user location
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        userLocation = locationManager.location
        
        // MapKit init
        mapKitMapView = MKMapView(frame: mapContainerView.frame)
        mapKitMapView.delegate = self
        mapContainerView.addSubview(mapKitMapView)
        mapKitMapView.showsUserLocation = true
        
        // GMS init
        googleMapsMapView.delegate = self
        placesClient = GMSPlacesClient.shared()
        initGoogleMapsUserMarker()
        
        configureTextField()
    }
    
    func initGoogleMapsUserMarker() {
        if let userLocation = userLocation {
            googleMapsUserMarker.position = CLLocationCoordinate2D(latitude: userLocation.coordinate.latitude, longitude: userLocation.coordinate.longitude)
            googleMapsUserMarker.title = "Your Location"
            googleMapsUserMarker.icon = UIImage(systemName: "location.north.fill")
            googleMapsUserMarker.map = googleMapsMapView
        }
    }
    
    func configureTextField() {
        searchLocationTextField.layer.cornerRadius = searchLocationTextField.frame.size.height / 2
        searchLocationTextField.clipsToBounds = true
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(UIInputViewController.dismissKeyboard))
        mapContainerView.addGestureRecognizer(tap)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
    }
    
    @IBAction func mapProviderSwitched(_ sender: UISegmentedControl) {
        if sender.selectedSegmentIndex == 0 {
            googleMapsMapView.isHidden = true
            mapContainerView.addSubview(mapKitMapView)
            mapTypeSwitched(mapTypeSwitch)
            currentMap = .MapKit
        } else {
            mapKitMapView.removeFromSuperview()
            googleMapsMapView.isHidden = false
            mapTypeSwitched(mapTypeSwitch)
            currentMap = .GMS
        }
        textFieldDidChange(searchLocationTextField)
    }
    
    @IBAction func mapTypeSwitched(_ sender: UISegmentedControl) {
        if mapProviderSwitch.selectedSegmentIndex == 0 {
            guard let mapType = MKMapType(rawValue: UInt(mapTypeSwitch.selectedSegmentIndex)) else { return }
            mapKitMapView.mapType = mapType
        } else {
            switch sender.selectedSegmentIndex {
            case 0:
                googleMapsMapView.mapType = .normal
            case 1:
                googleMapsMapView.mapType = .satellite
            default:
                googleMapsMapView.mapType = .hybrid
            }
        }
    }
    
    @IBAction func toUserLocationAction(_ sender: UIButton) {
        userLocation = locationManager.location
        guard let userLocation = userLocation else {
            let alertController = UIAlertController(title: "Location permission restricted", message: "Please go to\nSettings > Privacy & Security > Location Services\nand turn on the location permission", preferredStyle: .alert)

            let settingsAction = UIAlertAction(title: "Go to settings", style: .default) { (_) -> Void in
                guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                    return
                }
                if UIApplication.shared.canOpenURL(settingsUrl) {
                    UIApplication.shared.open(settingsUrl, completionHandler: nil)
                 }
            }
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)

            alertController.addAction(cancelAction)
            alertController.addAction(settingsAction)
            
            if [.notDetermined, .restricted, .denied].contains(locationManager.authorizationStatus) {
                    self.present(alertController, animated: true, completion: nil)
            }
            return
        }
        // Remove comments to do it separately on current map only
        //if currentMap == .MapKit {
            self.mapKitMapView.camera = MKMapCamera(lookingAtCenter: userLocation.coordinate, fromEyeCoordinate: userLocation.coordinate, eyeAltitude: 1500)
            self.mapKitMapView.setCenter(userLocation.coordinate, animated: true)
        //} else {
            guard let coordinate = self.userLocation?.coordinate else { return }
            let location = GMSCameraPosition.camera(withLatitude: coordinate.latitude, longitude: coordinate.longitude, zoom: 17.0)
            self.googleMapsMapView.animate(to: location)
            if self.googleMapsUserMarker.map == nil {
                initGoogleMapsUserMarker()
            }
        //}
    }
    
    func displayAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(okAction)
        DispatchQueue.main.async {
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    @objc func keyboardWillShow(_ notification: Notification) {
        searchLocationTextField.layer.cornerRadius = searchLocationTextField.frame.size.height / 4
        googleMapsMapView.settings.consumesGesturesInView = false
    }
    
    @objc func dismissKeyboard() {
        searchLocationTextField.endEditing(true)
        searchLocationTextField.layer.cornerRadius = searchLocationTextField.frame.size.height / 2
        googleMapsMapView.settings.consumesGesturesInView = true
    }
    
    @IBAction func textFieldDidChange(_ sender: UITextField) {
        searchTimer?.invalidate()
        
        if let searchText = sender.text, !searchText.isEmpty {
            if self.currentMap == .MapKit {
                searchTimer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(performMapKitSearch), userInfo: nil, repeats: false)
            } else {
                searchTimer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(performGoogleMapsSearch), userInfo: nil, repeats: false)
            }
        }
    }
    
    @objc func performMapKitSearch() {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchLocationTextField.text
        request.region = mapKitMapView.region
            
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            if let _ = error {
                self.displayAlert(title: "Couldn't find location", message: "Seems like your location doesn't exist on maps")
                return
            }
            if let response = response, response.mapItems.count < 5 {
                let placemarks = response.mapItems.map { $0.placemark }
                guard let placemark = placemarks.first,
                      let location = placemark.location
                else {
                    self.displayAlert(title: "Couldn't find location", message: "Seems like your location doesn't exist on maps")
                    return
                }
                self.mapKitMapView.removeAnnotation(self.mapKitPointAnnotation)
                self.mapKitPointAnnotation = MKPointAnnotation()
                self.mapKitPointAnnotation.coordinate = location.coordinate
                self.mapKitPointAnnotation.title = placemark.name
                self.mapKitPointAnnotation.subtitle = placemark.title
                self.mapKitMapView.addAnnotation(self.mapKitPointAnnotation)
                
                if let userLocation = self.userLocation {
                    let sourcePlacemark = MKPlacemark(coordinate: userLocation.coordinate)
                    let destinationPlacemark = MKPlacemark(coordinate: self.mapKitPointAnnotation.coordinate)
                    
                    let sourceMapItem = MKMapItem(placemark: sourcePlacemark)
                    let destinationMapItem = MKMapItem(placemark: destinationPlacemark)
                    
                    let sourcePoint = MKMapPoint(sourcePlacemark.coordinate)
                    let destinationPoint = MKMapPoint(destinationPlacemark.coordinate)
                    let rect = MKMapRect(x: min(sourcePoint.x, destinationPoint.x), y: min(sourcePoint.y, destinationPoint.y), width: abs(sourcePoint.x - destinationPoint.x), height: abs(sourcePoint.y - destinationPoint.y))
                    let edgePadding = UIEdgeInsets(top: 50.0, left: 50.0, bottom: 50.0, right: 50.0)
                    let visibleRect = self.mapKitMapView.mapRectThatFits(rect, edgePadding: edgePadding)
                    self.mapKitMapView.setVisibleMapRect(visibleRect, animated: true)
                    
                    let directionsRequest = MKDirections.Request()
                    directionsRequest.source = sourceMapItem
                    directionsRequest.destination = destinationMapItem
                    directionsRequest.transportType = .automobile
                    
                    let directions = MKDirections(request: directionsRequest)
                    directions.calculate { response, error in
                        if let response = response, let route = response.routes.first {
                            self.mapKitMapView.removeOverlay(self.mapKitOverlay)
                            self.mapKitOverlay = route.polyline
                            self.mapKitMapView.addOverlay(self.mapKitOverlay, level: .aboveRoads)
                        } else {
                            self.displayAlert(title: "Couldn't find route", message: "There is no way we can reach the destination by car :(")
                        }
                    }
                } else {
                    self.mapKitMapView.setCenter(location.coordinate, animated: true)
                }
            } else {
                self.displayAlert(title: "Couldn't find location", message: "There are too many results, provide more detailed location")
            }
        }
    }
    
    @objc func performGoogleMapsSearch() {
        let filter = GMSAutocompleteFilter()
        filter.types = ["address"]
        let visibleRegion = googleMapsMapView.projection.visibleRegion()
        let southwest = visibleRegion.nearLeft
        let northeast = visibleRegion.farRight
        filter.locationBias = GMSPlaceRectangularLocationOption(northeast, southwest)
        guard let searchText = searchLocationTextField.text else { return }
        placesClient.findAutocompletePredictions(fromQuery: searchText, filter: filter, sessionToken: GMSAutocompleteSessionToken.init()) { predictions, error in
            if let _ = error {
                self.displayAlert(title: "Couldn't find location", message: "Seems like your location doesn't exist on maps")
                return
            }
            
            guard let predictions = predictions else {
                self.displayAlert(title: "Couldn't find location", message: "Seems like your location doesn't exist on maps")
                return
            }
            
            if predictions.count < 5 {
                guard let prediction = predictions.first else {
                    self.displayAlert(title: "Couldn't find location", message: "Seems like your location doesn't exist on maps")
                    return
                }
                let fields: GMSPlaceField = GMSPlaceField(rawValue: UInt64(UInt(GMSPlaceField.name.rawValue) | UInt(GMSPlaceField.placeID.rawValue) | UInt(GMSPlaceField.coordinate.rawValue)))
                self.placesClient.fetchPlace(fromPlaceID: prediction.placeID, placeFields: fields, sessionToken: GMSAutocompleteSessionToken.init()) { (place, error) in
                    if let _ = error {
                        self.displayAlert(title: "Couldn't find location", message: "Seems like your location doesn't exist on maps")
                        return
                    }
                    
                    if let place = place {
                        self.googleMapsMarker.map = nil
                        let coordinates = place.coordinate
                        self.googleMapsMarker = GMSMarker(position: coordinates)
                        self.googleMapsMarker.title = place.name
                        self.googleMapsMarker.map = self.googleMapsMapView
                        
                        if let userLocation = self.userLocation {
                            let bounds = GMSCoordinateBounds(coordinate: userLocation.coordinate, coordinate: coordinates)
                            let cameraUpdate = GMSCameraUpdate.fit(bounds)
                            self.googleMapsMapView.animate(with: cameraUpdate)
                            
                            GoogleDirections.placeID(latitude: userLocation.coordinate.latitude, longitude: userLocation.coordinate.longitude) { origin in
                                guard let origin = origin else {
                                    self.displayAlert(title: "Oops...", message: "There was a problem of getting your location")
                                    return
                                }
                                let destination = prediction.placeID
                                GoogleDirections.directions(from: origin, to: destination) { route in
                                    guard let route = route else {
                                        self.displayAlert(title: "Couldn't find route", message: "There is no way we can reach the destination by car :(")
                                        return
                                    }
                                    self.googleMapsPolyline.map = nil
                                    let polyline = GoogleDirections.createPolyline(for: route)
                                    guard let polyline = polyline else { return }
                                    self.googleMapsPolyline = polyline
                                    self.googleMapsPolyline.strokeWidth = 3.0
                                    self.googleMapsPolyline.strokeColor = .blue
                                    self.googleMapsPolyline.map = self.googleMapsMapView
                                }
                            }
                        } else {
                            let location = GMSCameraPosition.camera(withLatitude: coordinates.latitude, longitude: coordinates.longitude, zoom: 17.0)
                            self.googleMapsMapView.animate(to: location)
                        }
                    }
                }
            } else {
                self.displayAlert(title: "Couldn't find location", message: "There are too many results, provide more detailed location")
            }
        }
    }
}
