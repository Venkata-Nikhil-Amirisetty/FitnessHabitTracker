//
//  LocationManager.swift
//  FitnessHabitTracker
//
//  Created by Nikhil Av on 4/20/25.
//

import Foundation
import CoreLocation
import Combine

class LocationManager: NSObject, ObservableObject {
    static let shared = LocationManager()
    private let locationManager = CLLocationManager()
    
    @Published var location: CLLocation?
    @Published var isAuthorized = false
    @Published var locationStatus: CLAuthorizationStatus?
    @Published var lastKnownLocation: CLLocation?
    @Published var city: String = ""
    @Published var country: String = ""
    @Published var isUpdatingLocation = false
    @Published var authorizationDenied = false
    
    private let geocoder = CLGeocoder()
    private var locationTimeoutWork: DispatchWorkItem?
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters // Lower accuracy is fine for weather
        locationManager.distanceFilter = 1000 // Update location when user moves 1km
        
        // Try to load the last known location from UserDefaults first
        if let savedLocationData = UserDefaults.standard.data(forKey: "lastKnownLocation") {
            if let savedLocation = try? NSKeyedUnarchiver.unarchivedObject(ofClass: CLLocation.self, from: savedLocationData) {
                self.lastKnownLocation = savedLocation
                // Also update city/country based on this cached location
                updateLocationInfo(for: savedLocation)
            }
        }
        
        checkAuthorization()
    }
    
    func requestLocation() {
        isUpdatingLocation = true
        
        // Check authorization first
        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            // Proceed with location request
            break
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
            return
        case .denied, .restricted:
            isUpdatingLocation = false
            authorizationDenied = true
            return
        @unknown default:
            break
        }
        
        // Cancel any existing timeout
        locationTimeoutWork?.cancel()
        
        // Request a one-time location update
        locationManager.requestLocation()
        
        // Set a timeout
        let timeoutWork = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            
            if self.isUpdatingLocation {
                // If we timed out, use the last known location
                if let lastLocation = self.lastKnownLocation {
                    DispatchQueue.main.async {
                        // If we haven't received a new location, use the last known one
                        if self.isUpdatingLocation {
                            self.location = lastLocation
                            self.isUpdatingLocation = false
                        }
                    }
                } else {
                    // If no last known location, start continuous updates
                    self.startUpdatingLocation()
                    
                    // And set a final timeout
                    DispatchQueue.main.asyncAfter(deadline: .now() + 10) { [weak self] in
                        self?.stopUpdatingLocation()
                    }
                }
            }
        }
        
        locationTimeoutWork = timeoutWork
        DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: timeoutWork)
    }
    
    func startUpdatingLocation() {
        isUpdatingLocation = true
        locationManager.startUpdatingLocation()
    }
    
    func stopUpdatingLocation() {
        isUpdatingLocation = false
        locationManager.stopUpdatingLocation()
    }
    
    func ensureLocationUpdates() {
        if location == nil && !isUpdatingLocation {
            startUpdatingLocation()
        }
    }
    
    private func checkAuthorization() {
        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            isAuthorized = true
            authorizationDenied = false
            locationStatus = locationManager.authorizationStatus
            
            // Request location immediately if authorized
            locationManager.requestLocation()
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
            locationStatus = .notDetermined
            authorizationDenied = false
        case .denied, .restricted:
            isAuthorized = false
            authorizationDenied = true
            locationStatus = locationManager.authorizationStatus
        @unknown default:
            isAuthorized = false
            authorizationDenied = false
            locationStatus = .notDetermined
        }
    }
    
    private func updateLocationInfo(for location: CLLocation) {
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Geocoding error: \(error.localizedDescription)")
                return
            }
            
            if let placemark = placemarks?.first {
                DispatchQueue.main.async {
                    self.city = placemark.locality ?? ""
                    self.country = placemark.country ?? ""
                }
            }
        }
    }
    
    private func saveLastLocation() {
        guard let lastLocation = lastKnownLocation else { return }
        
        do {
            let locationData = try NSKeyedArchiver.archivedData(withRootObject: lastLocation, requiringSecureCoding: true)
            UserDefaults.standard.set(locationData, forKey: "lastKnownLocation")
        } catch {
            print("Error saving location: \(error.localizedDescription)")
        }
    }
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        checkAuthorization()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        // Only update if location is recent
        let locationAge = location.timestamp.timeIntervalSinceNow
        if abs(locationAge) < 300 {
            DispatchQueue.main.async {
                self.location = location
                self.lastKnownLocation = location
                self.isUpdatingLocation = false
                
                // Save the location
                self.saveLastLocation()
            }
            
            // Update city and country info
            updateLocationInfo(for: location)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed with error: \(error.localizedDescription)")
        
        // If we have a last known location, use it as a fallback
        if let lastLocation = lastKnownLocation {
            DispatchQueue.main.async {
                // Only update if we're still waiting for a location
                if self.isUpdatingLocation {
                    self.location = lastLocation
                    self.isUpdatingLocation = false
                }
            }
        } else {
            // If no fallback, just stop updating
            DispatchQueue.main.async {
                self.isUpdatingLocation = false
            }
        }
    }
}
