//
//  ProfileImageService.swift
//  FitnessHabitTracker
//
//  Updated with improved caching and persistent storage
//

import SwiftUI
import UIKit
import FirebaseStorage

class ProfileImageService {
    // Singleton instance
    static let shared = ProfileImageService()
    
    // Storage reference
    private let storage = Storage.storage().reference()
    
    // Add a cache
    private let imageCache = NSCache<NSString, UIImage>()
    
    // Session configuration with better caching
    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .returnCacheDataElseLoad
        config.urlCache = URLCache.shared
        return URLSession(configuration: config)
    }()
    
    // Private initializer for singleton
    private init() {
        // Configure image cache
        imageCache.countLimit = 100 // Max number of images to keep in memory
        imageCache.totalCostLimit = 1024 * 1024 * 50 // 50 MB limit
        
        print("ProfileImageService initialized")
    }
    
    // Function to clear cache
    func clearCache(for urlString: String? = nil) {
        if let urlString = urlString {
            print("Clearing cache for URL: \(urlString)")
            imageCache.removeObject(forKey: urlString as NSString)
        } else {
            print("Clearing entire image cache")
            imageCache.removeAllObjects()
        }
        
        // Also clear the manager cache
        if let urlString = urlString {
            ProfileImageManager.shared.clearCache(for: urlString)
        } else {
            ProfileImageManager.shared.clearCache()
        }
        
        // Clear URL cache for web requests
        URLCache.shared.removeAllCachedResponses()
    }
    
    // Function to upload profile image
    func uploadProfileImage(_ image: UIImage, userId: String, completion: @escaping (Result<String, Error>) -> Void) {
        // Compress image with higher quality
        guard let imageData = image.jpegData(compressionQuality: 0.9) else {
            let error = NSError(domain: "ImageError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to compress image"])
            print("Error: \(error.localizedDescription)")
            completion(.failure(error))
            return
        }
        
        print("Starting upload of image (\(imageData.count) bytes) for user: \(userId)")
        
        // Create storage reference with timestamp to avoid caching issues
        let timestamp = Int(Date().timeIntervalSince1970)
        let profileRef = storage.child("profile_images/\(userId)_\(timestamp).jpg")
        
        // Add metadata
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        // Upload image
        let uploadTask = profileRef.putData(imageData, metadata: metadata) { metadata, error in
            if let error = error {
                print("Error uploading image: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            print("Image uploaded successfully, getting download URL")
            
            // Get download URL
            profileRef.downloadURL { url, error in
                if let error = error {
                    print("Error getting download URL: \(error.localizedDescription)")
                    completion(.failure(error))
                    return
                }
                
                guard let downloadURL = url else {
                    let error = NSError(domain: "URLError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to get download URL"])
                    print("Error: \(error.localizedDescription)")
                    completion(.failure(error))
                    return
                }
                
                let urlString = downloadURL.absoluteString
                print("Got download URL: \(urlString)")
                
                // Clear any cached version of this image
                self.clearCache(for: urlString)
                
                // Store the image in cache
                self.imageCache.setObject(image, forKey: urlString as NSString)
                
                // Also update the ProfileImageManager cache
                ProfileImageManager.shared.cacheImage(image, for: urlString)
                ProfileImageManager.shared.notifyImageUpdated()
                
                completion(.success(urlString))
            }
        }
        
        // Add progress observer for large images
        uploadTask.observe(.progress) { snapshot in
            guard let progress = snapshot.progress else { return }
            let percentComplete = Double(progress.completedUnitCount) / Double(progress.totalUnitCount) * 100
            print("Upload progress: \(Int(percentComplete))%")
        }
    }
    
    // Function to load profile image from URL with cache handling
    func loadProfileImage(from urlString: String, completion: @escaping (UIImage?) -> Void) {
        print("Attempting to load image from: \(urlString)")
        
        // Check in-memory cache first
        if let cachedImage = imageCache.object(forKey: urlString as NSString) {
            print("Image found in memory cache")
            completion(cachedImage)
            return
        }
        
        // Validate URL
        guard let url = URL(string: urlString) else {
            print("Invalid URL: \(urlString)")
            completion(nil)
            return
        }
        
        // Create a URL request with cache control
        var request = URLRequest(url: url)
        request.cachePolicy = .returnCacheDataElseLoad
        
        // Start network request
        let task = session.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Image load error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            
            // Check HTTP response
            if let httpResponse = response as? HTTPURLResponse {
                print("Image request status code: \(httpResponse.statusCode)")
                if httpResponse.statusCode != 200 {
                    DispatchQueue.main.async {
                        completion(nil)
                    }
                    return
                }
            }
            
            guard let data = data, let image = UIImage(data: data) else {
                print("Failed to create image from data")
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            
            // Cache the image in memory
            self.imageCache.setObject(image, forKey: urlString as NSString)
            
            print("Image loaded successfully and cached")
            DispatchQueue.main.async {
                completion(image)
            }
        }
        
        task.resume()
    }
    
    // Function to verify if image exists at URL
    func verifyImageURL(_ urlString: String, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: urlString) else {
            print("Invalid image URL for verification: \(urlString)")
            completion(false)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD" // Only fetch headers, not the actual image
        
        URLSession.shared.dataTask(with: request) { _, response, error in
            if let error = error {
                print("Error verifying image URL: \(error.localizedDescription)")
                completion(false)
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                let exists = httpResponse.statusCode == 200
                print("Image URL verification: \(exists ? "Exists" : "Not found")")
                completion(exists)
            } else {
                print("Invalid response while verifying image URL")
                completion(false)
            }
        }.resume()
    }
}
