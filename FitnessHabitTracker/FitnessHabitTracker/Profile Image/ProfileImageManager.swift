//
//  ProfileImageManager.swift
//  FitnessHabitTracker
//
//  Created for profile image update fix
//

import SwiftUI
import Combine
import CryptoKit

class ProfileImageManager: ObservableObject {
    static let shared = ProfileImageManager()
    @Published var lastUpdated = Date()
    @Published var cachedImages: [String: UIImage] = [:]
    
    private let fileManager = FileManager.default
    private let cacheDirectory: URL = {
        let paths = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
        return paths[0].appendingPathComponent("profile_images")
    }()
    
    private init() {
        setupCacheDirectory()
    }
    
    private func setupCacheDirectory() {
        if !fileManager.fileExists(atPath: cacheDirectory.path) {
            do {
                try fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
                print("Created cache directory at: \(cacheDirectory.path)")
            } catch {
                print("Error creating cache directory: \(error.localizedDescription)")
            }
        } else {
            print("Cache directory already exists at: \(cacheDirectory.path)")
        }
    }
    
    func notifyImageUpdated() {
        DispatchQueue.main.async {
            print("ProfileImageManager: Notifying image updated")
            self.lastUpdated = Date()
            self.objectWillChange.send()
        }
    }
    
    func cacheImage(_ image: UIImage, for url: String) {
        DispatchQueue.main.async {
            print("ProfileImageManager: Caching image for URL: \(url)")
            self.cachedImages[url] = image
            self.objectWillChange.send()
            
            // Also save to disk for persistence
            self.saveImageToDisk(image, for: url)
        }
    }
    
    func getCachedImage(for url: String) -> UIImage? {
        // First check in-memory cache
        if let cachedImage = cachedImages[url] {
            print("ProfileImageManager: Found image in memory cache for URL: \(url)")
            return cachedImage
        }
        
        // Then check disk cache
        if let diskImage = loadImageFromDisk(for: url) {
            print("ProfileImageManager: Found image in disk cache for URL: \(url)")
            // Add to memory cache for faster access next time
            cachedImages[url] = diskImage
            return diskImage
        }
        
        print("ProfileImageManager: No cached image found for URL: \(url)")
        return nil
    }
    
    func clearCache(for url: String? = nil) {
        DispatchQueue.main.async {
            if let url = url {
                print("ProfileImageManager: Clearing cache for URL: \(url)")
                self.cachedImages.removeValue(forKey: url)
                self.deleteImageFromDisk(for: url)
            } else {
                print("ProfileImageManager: Clearing entire cache")
                self.cachedImages.removeAll()
                self.clearDiskCache()
            }
            self.objectWillChange.send()
        }
    }
    
    // MARK: - Disk Cache Methods
    
    func saveImageToDisk(_ image: UIImage, for urlString: String) {
        let filename = urlString.md5Hash
        let fileURL = cacheDirectory.appendingPathComponent(filename)
        
        print("Saving image to disk: \(fileURL.path)")
        
        if let data = image.jpegData(compressionQuality: 0.8) {
            do {
                try data.write(to: fileURL)
                print("Image saved to disk successfully")
            } catch {
                print("Error saving image to disk: \(error.localizedDescription)")
            }
        }
    }
    
    func loadImageFromDisk(for urlString: String) -> UIImage? {
        let filename = urlString.md5Hash
        let fileURL = cacheDirectory.appendingPathComponent(filename)
        
        print("Trying to load image from disk: \(fileURL.path)")
        
        if fileManager.fileExists(atPath: fileURL.path),
           let data = try? Data(contentsOf: fileURL),
           let image = UIImage(data: data) {
            print("Image loaded from disk successfully")
            return image
        }
        
        print("Image not found on disk or failed to load")
        return nil
    }
    
    private func deleteImageFromDisk(for urlString: String) {
        let filename = urlString.md5Hash
        let fileURL = cacheDirectory.appendingPathComponent(filename)
        
        if fileManager.fileExists(atPath: fileURL.path) {
            do {
                try fileManager.removeItem(at: fileURL)
                print("Image deleted from disk successfully")
            } catch {
                print("Error deleting image from disk: \(error.localizedDescription)")
            }
        }
    }
    
    private func clearDiskCache() {
        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)
            for fileURL in fileURLs {
                try fileManager.removeItem(at: fileURL)
            }
            print("Disk cache cleared successfully")
        } catch {
            print("Error clearing disk cache: \(error.localizedDescription)")
        }
    }
}

// MARK: - String Extension for MD5 Hashing

extension String {
    var md5Hash: String {
        let inputData = Data(self.utf8)
        let hashed = Insecure.MD5.hash(data: inputData)
        let hashString = hashed.compactMap { String(format: "%02x", $0) }.joined()
        return hashString
    }
}
