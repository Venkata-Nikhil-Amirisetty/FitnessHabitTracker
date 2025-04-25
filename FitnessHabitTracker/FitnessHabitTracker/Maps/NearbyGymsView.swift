//
//  NearbyGymsView.swift
//  FitnessHabitTracker
//
//  Updated with search radius functionality
//

import SwiftUI
import MapKit
import CoreLocation

struct NearbyGymsView: View {
    @StateObject private var gymFinderService = GymFinderService.shared
    @State private var showingMap = false
    @State private var selectedGym: Gym? = nil
    @State private var searchRadius: Double = 5.0 // km
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with search controls
                VStack(spacing: 12) {
                    HStack {
                        Text("Nearby Gyms")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        Button(action: {
                            gymFinderService.refreshGyms()
                        }) {
                            Image(systemName: "arrow.clockwise")
                                .font(.headline)
                                .padding(8)
                                .background(Color.blue.opacity(0.1))
                                .clipShape(Circle())
                        }
                        
                        Button(action: {
                            showingMap = true
                        }) {
                            Image(systemName: "map")
                                .font(.headline)
                                .padding(8)
                                .background(Color.green.opacity(0.1))
                                .clipShape(Circle())
                        }
                    }
                    .padding(.horizontal)
                    
                    // Search radius slider - now connected to the service
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Search Radius: \(Int(searchRadius)) km")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Slider(
                            value: $searchRadius,
                            in: 1...10,
                            step: 1
                        ) { editing in
                            // When editing ends, update the search radius in the service
                            if !editing {
                                gymFinderService.updateSearchRadius(searchRadius)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.top)
                .background(Color(UIColor.systemBackground))
                
                if gymFinderService.isLoading {
                    // Loading indicator
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(1.5)
                    Text("Finding nearby gyms...")
                        .font(.headline)
                        .padding(.top)
                    Spacer()
                } else if let errorMessage = gymFinderService.errorMessage {
                    // Error state
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 60))
                            .foregroundColor(.orange)
                        
                        Text("Error loading gyms")
                            .font(.headline)
                        
                        Text(errorMessage)
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                        
                        Button(action: {
                            gymFinderService.refreshGyms()
                        }) {
                            Text("Try Again")
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(10)
                        }
                    }
                    .padding()
                    Spacer()
                } else if gymFinderService.nearbyGyms.isEmpty {
                    // Empty state
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "dumbbell")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("No Gyms Found Nearby")
                            .font(.headline)
                        
                        Text("Try increasing the search radius or searching in a different area.")
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                        
                        Button(action: {
                            gymFinderService.refreshGyms()
                        }) {
                            Text("Search Again")
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(10)
                        }
                    }
                    .padding()
                    Spacer()
                } else {
                    // List of gyms
                    List {
                        ForEach(gymFinderService.nearbyGyms) { gym in
                            GymRow(gym: gym)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedGym = gym
                                }
                        }
                    }
                    .listStyle(PlainListStyle())
                    
                    // Last updated footer
                    if let lastUpdated = gymFinderService.lastUpdated {
                        Text("Last updated: \(timeAgoString(from: lastUpdated))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 8)
                            .background(Color(UIColor.systemBackground))
                            .shadow(color: Color.black.opacity(0.05), radius: 5, y: -3)
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingMap) {
                GymsMapView(gyms: gymFinderService.nearbyGyms)
            }
            .sheet(item: $selectedGym) { gym in
                GymDetailView(gym: gym)
            }
            .onAppear {
                // Initialize search radius with the service's value
                searchRadius = gymFinderService.searchRadius / 1000 // Convert meters to km
                
                // Request location when view appears
                LocationManager.shared.requestLocation()
            }
        }
    }
    
    private func timeAgoString(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct GymRow: View {
    var gym: Gym
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(gym.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(gym.address)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(gym.formattedDistance)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    HStack(spacing: 4) {
                        Circle()
                            .fill(gym.statusColor)
                            .frame(width: 8, height: 8)
                        
                        Text(gym.statusText)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            if let url = gym.url {
                Link(destination: url) {
                    HStack {
                        Image(systemName: "globe")
                            .font(.caption)
                            .foregroundColor(.blue)
                        
                        Text("Website")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }
}

struct GymsMapView: View {
    var gyms: [Gym]
    @State private var region: MKCoordinateRegion
    @State private var selectedGym: Gym?
    @Environment(\.presentationMode) var presentationMode
    
    init(gyms: [Gym]) {
        self.gyms = gyms
        
        // Calculate the initial region based on gyms or default to user location
        if let firstGym = gyms.first {
            _region = State(initialValue: MKCoordinateRegion(
                center: firstGym.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            ))
        } else if let userLocation = LocationManager.shared.location {
            _region = State(initialValue: MKCoordinateRegion(
                center: userLocation.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            ))
        } else {
            // Default to Boston area
            _region = State(initialValue: MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 42.3601, longitude: -71.0589),
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            ))
        }
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            Map(coordinateRegion: $region, showsUserLocation: true, annotationItems: gyms) { gym in
                MapAnnotation(coordinate: gym.coordinate) {
                    GymMapPin(gym: gym, isSelected: selectedGym?.id == gym.id)
                        .onTapGesture {
                            selectedGym = gym
                        }
                }
            }
            .ignoresSafeArea()
            
            VStack {
                // Header with close button
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.headline)
                            .padding(12)
                            .background(Color.white)
                            .clipShape(Circle())
                            .shadow(color: Color.black.opacity(0.15), radius: 3, x: 0, y: 2)
                    }
                    
                    Spacer()
                    
                    Text("Nearby Gyms")
                        .font(.headline)
                        .padding(8)
                        .padding(.horizontal, 8)
                        .background(Color.white)
                        .cornerRadius(20)
                        .shadow(color: Color.black.opacity(0.15), radius: 3, x: 0, y: 2)
                    
                    Spacer()
                    
                    Button(action: {
                        if let userLocation = LocationManager.shared.location {
                            region = MKCoordinateRegion(
                                center: userLocation.coordinate,
                                span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
                            )
                        }
                    }) {
                        Image(systemName: "location")
                            .font(.headline)
                            .padding(12)
                            .background(Color.white)
                            .clipShape(Circle())
                            .shadow(color: Color.black.opacity(0.15), radius: 3, x: 0, y: 2)
                    }
                }
                .padding()
                
                // Selected gym card
                if let selectedGym = selectedGym {
                    GymDetailCard(gym: selectedGym)
                        .padding(.horizontal)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .animation(.spring(), value: selectedGym.id)
                }
                
                Spacer()
            }
        }
    }
}

struct GymMapPin: View {
    var gym: Gym
    var isSelected: Bool
    
    var body: some View {
        ZStack {
            // Pin shadow
            Circle()
                .fill(Color.black.opacity(0.1))
                .frame(width: isSelected ? 44 : 36, height: isSelected ? 44 : 36)
                .offset(y: 1)
            
            // Pin background
            Circle()
                .fill(isSelected ? Color.blue : Color.white)
                .frame(width: isSelected ? 40 : 32, height: isSelected ? 40 : 32)
            
            // Pin icon
            Image(systemName: "dumbbell.fill")
                .font(.system(size: isSelected ? 20 : 16))
                .foregroundColor(isSelected ? .white : .blue)
        }
        .animation(.spring(response: 0.3), value: isSelected)
    }
}

struct GymDetailCard: View {
    var gym: Gym
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(gym.name)
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Text(gym.formattedDistance)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Status indicator
                HStack(spacing: 4) {
                    Circle()
                        .fill(gym.statusColor)
                        .frame(width: 8, height: 8)
                    
                    Text(gym.statusText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 12)
                .background(gym.statusColor.opacity(0.1))
                .cornerRadius(12)
            }
            
            // Address
            Text(gym.address)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // Action buttons
            HStack(spacing: 12) {
                Button(action: {
                    openInMaps(gym: gym)
                }) {
                    Label("Directions", systemImage: "location.fill")
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                
                if let phoneNumber = gym.phoneNumber, !phoneNumber.isEmpty {
                    Button(action: {
                        callPhoneNumber(phoneNumber)
                    }) {
                        Label("Call", systemImage: "phone.fill")
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity)
                            .background(Color.green)
                            .cornerRadius(10)
                    }
                }
                
                if let url = gym.url {
                    Button(action: {
                        UIApplication.shared.open(url)
                    }) {
                        Label("Website", systemImage: "globe")
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity)
                            .background(Color.orange)
                            .cornerRadius(10)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.systemBackground))
                .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
        )
    }
    
    private func openInMaps(gym: Gym) {
        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: gym.coordinate))
        mapItem.name = gym.name
        mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
    }
    
    private func callPhoneNumber(_ phoneNumber: String) {
        if let url = URL(string: "tel://\(phoneNumber.replacingOccurrences(of: " ", with: ""))") {
            UIApplication.shared.open(url)
        }
    }
}

struct GymDetailView: View {
    var gym: Gym
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text(gym.name)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    HStack(spacing: 4) {
                        Circle()
                            .fill(gym.statusColor)
                            .frame(width: 8, height: 8)
                        
                        Text(gym.statusText)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)
                
                // Map preview
                ZStack(alignment: .bottomTrailing) {
                    MapSnapshotView(coordinate: gym.coordinate)
                        .frame(height: 200)
                        .cornerRadius(16)
                    
                    Button(action: {
                        openInMaps(gym: gym)
                    }) {
                        Text("Get Directions")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.blue)
                            .cornerRadius(20)
                            .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                    }
                    .padding(.trailing, 16)
                    .padding(.bottom, 16)
                }
                .padding(.horizontal)
                
                // Information section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Information")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    // Address
                    HStack(alignment: .top) {
                        Image(systemName: "mappin.and.ellipse")
                            .foregroundColor(.red)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading) {
                            Text("Address")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Text(gym.address)
                                .font(.body)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Distance
                    HStack {
                        Image(systemName: "figure.walk")
                            .foregroundColor(.blue)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading) {
                            Text("Distance")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Text(gym.formattedDistance)
                                .font(.body)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Phone (if available)
                    if let phone = gym.phoneNumber, !phone.isEmpty {
                        Button(action: {
                            callPhoneNumber(phone)
                        }) {
                            HStack {
                                Image(systemName: "phone")
                                    .foregroundColor(.green)
                                    .frame(width: 24)
                                
                                VStack(alignment: .leading) {
                                    Text("Phone")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    
                                    Text(phone)
                                        .font(.body)
                                        .foregroundColor(.blue)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                                    .font(.caption)
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Website (if available)
                    if let url = gym.url {
                        Button(action: {
                            UIApplication.shared.open(url)
                        }) {
                            HStack {
                                Image(systemName: "globe")
                                    .foregroundColor(.blue)
                                    .frame(width: 24)
                                
                                VStack(alignment: .leading) {
                                    Text("Website")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    
                                    Text(url.absoluteString)
                                        .font(.body)
                                        .foregroundColor(.blue)
                                        .lineLimit(1)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                                    .font(.caption)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                Spacer(minLength: 40)
                
                // Action buttons
                VStack(spacing: 12) {
                    Button(action: {
                        openInMaps(gym: gym)
                    }) {
                        HStack {
                            Image(systemName: "location.fill")
                            Text("Get Directions")
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                    }
                    
                    if let phone = gym.phoneNumber, !phone.isEmpty {
                        Button(action: {
                            callPhoneNumber(phone)
                        }) {
                            HStack {
                                Image(systemName: "phone.fill")
                                Text("Call")
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .cornerRadius(12)
                        }
                    }
                }
                .padding()
            }
            .padding(.vertical)
        }
        .navigationTitle("Gym Details")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(trailing: Button(action: {
            presentationMode.wrappedValue.dismiss()
        }) {
            Image(systemName: "xmark.circle.fill")
                .foregroundColor(.gray)
        })
    }
    
    private func openInMaps(gym: Gym) {
        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: gym.coordinate))
        mapItem.name = gym.name
        mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
    }
    
    private func callPhoneNumber(_ phoneNumber: String) {
        if let url = URL(string: "tel://\(phoneNumber.replacingOccurrences(of: " ", with: ""))") {
            UIApplication.shared.open(url)
        }
    }
}

// Helper view to display a static map snapshot
struct MapSnapshotView: View {
    let coordinate: CLLocationCoordinate2D
    @State private var snapshot: UIImage?
    
    var body: some View {
        ZStack {
            if let snapshot = snapshot {
                Image(uiImage: snapshot)
                    .resizable()
                    .scaledToFill()
            } else {
                Color.gray.opacity(0.2)
                ProgressView()
            }
        }
        .onAppear {
            generateSnapshot()
        }
    }
    
    private func generateSnapshot() {
        let options = MKMapSnapshotter.Options()
        options.region = MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
        )
        options.size = CGSize(width: UIScreen.main.bounds.width - 32, height: 200)
        options.showsBuildings = true
        
        let snapshotter = MKMapSnapshotter(options: options)
        snapshotter.start { snapshot, error in
            guard error == nil, let snapshot = snapshot else {
                print("Error generating map snapshot: \(error?.localizedDescription ?? "unknown error")")
                return
            }
            
            // Add a pin to the snapshot
            let image = UIGraphicsImageRenderer(size: options.size).image { _ in
                // Draw the snapshot
                snapshot.image.draw(at: .zero)
                
                // Calculate the point for the coordinate
                let pinView = MKPinAnnotationView(annotation: nil, reuseIdentifier: nil)
                let pinImage = pinView.image
                
                let pinPoint = snapshot.point(for: coordinate)
                let pinCenterOffset = pinView.centerOffset
                let pinCenterX = pinPoint.x + pinCenterOffset.x
                let pinCenterY = pinPoint.y + pinCenterOffset.y
                
                // Draw the pin
                pinImage?.draw(at: CGPoint(x: pinCenterX - (pinImage?.size.width ?? 0) / 2,
                                          y: pinCenterY - (pinImage?.size.height ?? 0)))
            }
            
            DispatchQueue.main.async {
                self.snapshot = image
            }
        }
    }
}
