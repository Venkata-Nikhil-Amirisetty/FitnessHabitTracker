//
//  AppDelegate.swift
//  FitnessHabitTracker
//
//  Updated with app launch image preloading
//

import UIKit
import FirebaseCore
import FirebaseAuth
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        // Configure Firebase
        FirebaseApp.configure()
        
        // Setup Cloud Messaging
        FirebaseManager.shared.setupCloudMessaging()
        
        // Set up the UNUserNotificationCenter delegate
        UNUserNotificationCenter.current().delegate = self
        
        // Initialize NotificationManager to request permissions early
        _ = NotificationManager.shared
        
        // Preload user profile image if available
        preloadUserProfileImage()
        
        print("App finished launching")
        return true
    }
    
    // MARK: - Profile Image Preloading
    
    private func preloadUserProfileImage() {
        // This will be called after Firebase is configured but before the UI is fully loaded
        print("Checking for user profile image to preload...")
        
        // Check if we have a logged-in user
        if let userId = FirebaseAuth.Auth.auth().currentUser?.uid {
            print("Found logged in user: \(userId), fetching profile data")
            
            // Fetch user data to get profile image URL
            let db = FirebaseManager.shared.firestore
            db.collection("users").document(userId).getDocument { document, error in
                if let error = error {
                    print("Error fetching user data for image preload: \(error.localizedDescription)")
                    return
                }
                
                if let document = document, document.exists,
                   let data = document.data(),
                   let profileImageURL = data["profileImageURL"] as? String,
                   !profileImageURL.isEmpty {
                    
                    print("Found profile image URL: \(profileImageURL), preloading...")
                    
                    // Preload the image
                    ProfileImageService.shared.loadProfileImage(from: profileImageURL) { loadedImage in
                        if let loadedImage = loadedImage {
                            print("Successfully preloaded profile image at startup")
                            
                            // Cache the image for immediate use
                            ProfileImageManager.shared.cacheImage(loadedImage, for: profileImageURL)
                            ProfileImageManager.shared.notifyImageUpdated()
                        } else {
                            print("Failed to preload profile image at startup")
                        }
                    }
                } else {
                    print("No profile image URL found for preloading")
                }
            }
        } else {
            print("No user logged in, skipping profile image preload")
        }
    }
    
    // MARK: - Remote Notification Registration
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // Handle device token
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
        print("Device Token: \(token)")
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for remote notifications: \(error.localizedDescription)")
    }
    
    // MARK: - Universal Links Handling
    
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        // Handle Universal Links (for deeplinks and social sharing)
        if userActivity.activityType == NSUserActivityTypeBrowsingWeb, let url = userActivity.webpageURL {
            handleDeepLink(url)
            return true
        }
        return false
    }
    
    // MARK: - URL Scheme Handling
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        // Handle custom URL schemes
        handleDeepLink(url)
        return true
    }
    
    // MARK: - Helper Methods
    
    private func handleDeepLink(_ url: URL) {
        // Parse the URL and route to appropriate screen
        // This would route to appropriate views in your app
        
        // Example URL formats:
        // fitnesshabittracker://workout/{workout_id}
        // fitnesshabittracker://habit/{habit_id}
        
        let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)
        guard let host = urlComponents?.host else { return }
        
        switch host {
        case "workout":
            if let workoutId = urlComponents?.path.replacingOccurrences(of: "/", with: "") {
                // Route to workout detail
                print("Opening workout with ID: \(workoutId)")
                NotificationCenter.default.post(
                    name: NSNotification.Name("OpenWorkoutDetail"),
                    object: nil,
                    userInfo: ["workoutId": workoutId]
                )
            }
        case "habit":
            if let habitId = urlComponents?.path.replacingOccurrences(of: "/", with: "") {
                // Route to habit detail
                print("Opening habit with ID: \(habitId)")
                NotificationCenter.default.post(
                    name: NSNotification.Name("OpenHabitDetail"),
                    object: nil,
                    userInfo: ["habitId": habitId]
                )
            }
        case "reminder":
            if let reminderId = urlComponents?.path.replacingOccurrences(of: "/", with: "") {
                // Route to reminder detail
                print("Opening reminder with ID: \(reminderId)")
                NotificationCenter.default.post(
                    name: NSNotification.Name("OpenReminderDetail"),
                    object: nil,
                    userInfo: ["reminderId": reminderId]
                )
            }
        default:
            print("Unknown deep link: \(url.absoluteString)")
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension AppDelegate: UNUserNotificationCenterDelegate {
    // Handle foreground notifications
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show the notification even when the app is in the foreground
        if #available(iOS 14.0, *) {
            completionHandler([.banner, .sound, .badge])
        } else {
            completionHandler([.alert, .sound, .badge])
        }
    }
    
    // Handle notification interactions
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        // Extract the notification data
        let userInfo = response.notification.request.content.userInfo
        let identifier = response.notification.request.identifier
        
        // Check if it's a habit reminder
        if let habitId = userInfo["habitId"] as? String {
            // Post a notification to open the habit detail
            NotificationCenter.default.post(
                name: NSNotification.Name("OpenHabitDetail"),
                object: nil,
                userInfo: ["habitId": habitId]
            )
        }
        // Check if it's a reminder notification
        else if identifier.starts(with: "reminder-") {
            // Parse the reminder ID from the identifier
            let components = identifier.components(separatedBy: "-")
            if components.count >= 2 {
                let reminderId = components[1]
                // Post notification to open reminder detail
                NotificationCenter.default.post(
                    name: NSNotification.Name("OpenReminderDetail"),
                    object: nil,
                    userInfo: ["reminderId": reminderId]
                )
            }
        }
        // Check if it's a workout reminder
        else if identifier.starts(with: "workout-") {
            // Navigate to workouts tab
            NotificationCenter.default.post(
                name: NSNotification.Name("OpenWorkoutsTab"),
                object: nil
            )
        }
        // Check if it's a general reminder
        else if identifier.starts(with: "test-reminder-") {
            // This is just a test notification, no action needed
            print("Test notification tapped")
        }
        // Check if it's a notification with a deeplink
        else if let urlString = userInfo["deeplink"] as? String, let url = URL(string: urlString) {
            // Handle deeplink
            handleDeepLink(url)
        }
        
        completionHandler()
    }
}
