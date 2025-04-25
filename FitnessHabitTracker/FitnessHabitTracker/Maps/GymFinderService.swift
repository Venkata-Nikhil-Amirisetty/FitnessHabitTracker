//
//  GymFinderService.swift
//  FitnessHabitTracker
//
//  Updated with search radius functionality
//

import Foundation
import CoreLocation
import MapKit
import Combine
import SwiftUI

class GymFinderService: ObservableObject {
    static let shared = GymFinderService()
    
    @Published var nearbyGyms: [Gym] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var lastUpdated: Date?
    
    // Make searchRadius a published property so it can be updated from the UI
    @Published var searchRadius: CLLocationDistance = 5000 // 5 kilometers (default)
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        // Subscribe to location changes
        LocationManager.shared.$location
            .sink { [weak self] location in
                if let location = location {
                    self?.fetchNearbyGyms(location: location)
                }
            }
            .store(in: &cancellables)
    }
    
    // Method to update search radius
    func updateSearchRadius(_ radiusInKm: Double) {
        // Convert kilometers to meters
        searchRadius = radiusInKm * 1000
        
        // Refresh gyms with the new search radius if we have a location
        if let location = LocationManager.shared.location {
            fetchNearbyGyms(location: location)
        }
    }
    
    func fetchNearbyGyms(location: CLLocation) {
        isLoading = true
        errorMessage = nil
        
        // Create a search request
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = "gym fitness"
        request.region = MKCoordinateRegion(
            center: location.coordinate,
            latitudinalMeters: searchRadius * 2, // Using searchRadius property
            longitudinalMeters: searchRadius * 2
        )
        
        // Perform the search
        let search = MKLocalSearch(request: request)
        search.start { [weak self] response, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    return
                }
                
                guard let response = response else {
                    self.errorMessage = "No results found"
                    return
                }
                
                self.processSearchResults(items: response.mapItems, userLocation: location)
            }
        }
    }
    
    private func processSearchResults(items: [MKMapItem], userLocation: CLLocation) {
        // Convert MKMapItems to our Gym model
        var gyms = items.map { mapItem -> Gym in
            let location = mapItem.placemark.location ?? CLLocation(
                latitude: mapItem.placemark.coordinate.latitude,
                longitude: mapItem.placemark.coordinate.longitude
            )
            
            // Calculate distance from user
            let distance = userLocation.distance(from: location)
            
            // Check if the business is likely open (we'd need to use MKMapItem.openingHours in
            // an actual implementation, but it's not available in older iOS versions)
            // For this example, we'll use a simple time-based approach
            let isOpen: Bool? = {
                let hour = Calendar.current.component(.hour, from: Date())
                // Most gyms are open from 6 AM to 10 PM
                return (hour >= 6 && hour < 22) ? true : nil
            }()
            
            return Gym(
                id: UUID().uuidString,
                name: mapItem.name ?? "Unknown Gym",
                address: addressFromPlacemark(mapItem.placemark),
                coordinate: mapItem.placemark.coordinate,
                distance: distance,
                phoneNumber: mapItem.phoneNumber,
                url: mapItem.url,
                isOpen: isOpen
            )
        }
        
        // IMPORTANT: Filter results to only include gyms within the specified radius
        gyms = gyms.filter { $0.distance <= self.searchRadius }
        
        // Sort by distance
        self.nearbyGyms = gyms.sorted(by: { $0.distance < $1.distance })
        self.lastUpdated = Date()
        
        print("Found \(gyms.count) nearby gyms within \(self.searchRadius/1000) km")
    }
    
    private func addressFromPlacemark(_ placemark: MKPlacemark) -> String {
        // Format the address
        var addressComponents: [String] = []
        
        if let thoroughfare = placemark.thoroughfare {
            addressComponents.append(thoroughfare)
        }
        
        if let subThoroughfare = placemark.subThoroughfare {
            // Insert at beginning if it's a number
            if let _ = Int(subThoroughfare) {
                if !addressComponents.isEmpty {
                    addressComponents[0] = subThoroughfare + " " + addressComponents[0]
                } else {
                    addressComponents.append(subThoroughfare)
                }
            } else {
                addressComponents.append(subThoroughfare)
            }
        }
        
        if let locality = placemark.locality {
            addressComponents.append(locality)
        }
        
        if let administrativeArea = placemark.administrativeArea {
            addressComponents.append(administrativeArea)
        }
        
        if let postalCode = placemark.postalCode {
            addressComponents.append(postalCode)
        }
        
        return addressComponents.joined(separator: ", ")
    }
    
    func refreshGyms() {
        if let location = LocationManager.shared.location {
            fetchNearbyGyms(location: location)
        } else {
            // Request a new location if we don't have one
            LocationManager.shared.requestLocation()
        }
    }
}

// MARK: - Gym Model
struct Gym: Identifiable {
    let id: String
    let name: String
    let address: String
    let coordinate: CLLocationCoordinate2D
    let distance: CLLocationDistance
    let phoneNumber: String?
    let url: URL?
    let isOpen: Bool?
    
    // Computed properties for display
    var formattedDistance: String {
        if distance < 1000 {
            return String(format: "%.0f m", distance)
        } else {
            return String(format: "%.1f km", distance / 1000)
        }
    }
    
    var statusText: String {
        if let isOpen = isOpen {
            return isOpen ? "Open Now" : "Closed"
        }
        return "Hours Unknown"
    }
    
    var statusColor: SwiftUI.Color {
        if let isOpen = isOpen {
            return isOpen ? .green : .red
        }
        return .gray
    }
}
