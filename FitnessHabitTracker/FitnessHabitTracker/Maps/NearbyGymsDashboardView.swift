//
//  NearbyGymsDashboardView.swift
//  FitnessHabitTracker
//
//  Created by Nikhil Av on 4/24/25.
//


//
//  NearbyGymsDashboardView.swift
//  FitnessHabitTracker
//
//  Created on 4/24/25.
//

import SwiftUI
import MapKit

struct NearbyGymsDashboardView: View {
    @ObservedObject private var gymFinderService = GymFinderService.shared
    @State private var showingAllGyms = false
    @State private var showingGymDetails = false
    @State private var selectedGym: Gym? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            // Title and View All button
            HStack {
                Text("Nearby Gyms")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(action: {
                    showingAllGyms = true
                }) {
                    HStack {
                        Text("View All")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
            }
            .padding(.horizontal)
            
            if gymFinderService.isLoading {
                // Loading state
                HStack {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                    Text("Finding gyms...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .frame(height: 120)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal)
            } else if let errorMessage = gymFinderService.errorMessage {
                // Error state
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(.orange)
                    
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Button(action: {
                        gymFinderService.refreshGyms()
                    }) {
                        Text("Retry")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal)
            } else if gymFinderService.nearbyGyms.isEmpty {
                // Empty state
                VStack(spacing: 10) {
                    Image(systemName: "dumbbell")
                        .font(.system(size: 30))
                        .foregroundColor(.gray)
                    
                    Text("No gyms found nearby")
                        .font(.subheadline)
                    
                    Text("Enable location access or try again later")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Button(action: {
                        LocationManager.shared.requestLocation()
                    }) {
                        Text("Update Location")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
                .frame(height: 120)
                .frame(maxWidth: .infinity)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal)
            } else {
                // Show horizontal scrolling list of nearby gyms
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 15) {
                        ForEach(gymFinderService.nearbyGyms.prefix(5)) { gym in
                            GymCard(gym: gym)
                                .onTapGesture {
                                    selectedGym = gym
                                    showingGymDetails = true
                                }
                        }
                    }
                    .padding(.horizontal)
                }
                .frame(height: 140)
            }
        }
        .sheet(isPresented: $showingAllGyms) {
            NearbyGymsView()
        }
        .sheet(item: $selectedGym) { gym in
            GymDetailView(gym: gym)
        }
        .onAppear {
            if gymFinderService.nearbyGyms.isEmpty && !gymFinderService.isLoading {
                gymFinderService.refreshGyms()
            }
        }
    }
}

struct GymCard: View {
    var gym: Gym
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Image(systemName: "dumbbell.fill")
                    .foregroundColor(.white)
                    .padding(6)
                    .background(Color.blue)
                    .cornerRadius(8)
                
                Spacer()
                
                HStack(spacing: 4) {
                    Circle()
                        .fill(gym.statusColor)
                        .frame(width: 6, height: 6)
                    
                    Text(gym.statusText)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            // Name and distance
            Text(gym.name)
                .font(.subheadline)
                .fontWeight(.semibold)
                .lineLimit(1)
            
            Text(gym.formattedDistance)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            // Get directions button
            Button(action: {
                openInMaps(gym: gym)
            }) {
                Text("Directions")
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.vertical, 4)
                    .padding(.horizontal, 10)
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(8)
            }
        }
        .padding(12)
        .frame(width: 160, height: 130)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.secondarySystemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
    
    private func openInMaps(gym: Gym) {
        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: gym.coordinate))
        mapItem.name = gym.name
        mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
    }
}