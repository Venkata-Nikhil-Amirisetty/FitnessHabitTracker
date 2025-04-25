//
//  ProfileImageView.swift
//  FitnessHabitTracker
//
//  Updated with improved image loading and persistent caching
//

import SwiftUI

struct ProfileImageView: View {
    let imageURL: String
    @State private var image: UIImage? = nil
    @State private var isLoading = true
    @State private var loadAttempts = 0
    @ObservedObject private var imageManager = ProfileImageManager.shared
    
    var body: some View {
        ZStack {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .foregroundColor(.gray)
            }
        }
        .onAppear {
            print("ProfileImageView appeared for URL: \(imageURL)")
            loadImage()
        }
        .onChange(of: imageManager.lastUpdated) { _ in
            print("ProfileImageManager updated, reloading image")
            loadImage(forceReload: true)
        }
        // Force refresh when URL changes by using a unique ID
        .id("\(imageURL)-\(imageManager.lastUpdated.timeIntervalSince1970)")
    }
    
    private func loadImage(forceReload: Bool = false) {
        isLoading = true
        loadAttempts += 1
        print("Loading image from URL: \(imageURL) (Attempt: \(loadAttempts), Force: \(forceReload))")
        
        // Step 1: Check image manager memory cache first if not forcing reload
        if !forceReload, let cachedImage = imageManager.getCachedImage(for: imageURL) {
            DispatchQueue.main.async {
                self.image = cachedImage
                self.isLoading = false
                print("Using cached image from manager")
            }
            return
        }
        
        // Step 2: Add cache busting parameter
        var urlWithCacheBusting = imageURL
        if !urlWithCacheBusting.contains("?") {
            urlWithCacheBusting += "?t=\(Date().timeIntervalSince1970)"
        } else {
            urlWithCacheBusting += "&t=\(Date().timeIntervalSince1970)"
        }
        
        print("Loading from network with cache busting: \(urlWithCacheBusting)")
        
        // Step 3: Load from network
        ProfileImageService.shared.loadProfileImage(from: urlWithCacheBusting) { loadedImage in
            DispatchQueue.main.async {
                if let loadedImage = loadedImage {
                    self.image = loadedImage
                    self.isLoading = false
                    print("Image loaded successfully from network")
                    
                    // Cache the image in memory and on disk
                    imageManager.cacheImage(loadedImage, for: imageURL)
                } else {
                    self.isLoading = false
                    print("Failed to load image from network")
                    
                    // If network loading fails, try loading from disk as a last resort
                    if let diskImage = imageManager.loadImageFromDisk(for: imageURL) {
                        self.image = diskImage
                        print("Fallback: Loaded image from disk cache")
                        imageManager.cacheImage(diskImage, for: imageURL)
                    }
                }
            }
        }
    }
    
    // Method to explicitly reload the image
    func reloadImage() {
        loadImage(forceReload: true)
    }
}
