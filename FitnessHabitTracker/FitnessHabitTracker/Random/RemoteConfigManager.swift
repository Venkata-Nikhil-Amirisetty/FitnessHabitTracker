//
//  RemoteConfigManager.swift
//  FitnessHabitTracker
//
//  Created by Nikhil Av on 4/19/25.
//


import FirebaseRemoteConfig

class RemoteConfigManager {
    static let shared = RemoteConfigManager()
    
    private let remoteConfig: RemoteConfig
    
    // Define your feature flags and default values
    struct Keys {
        static let enableWorkoutSharing = "enable_workout_sharing"
        static let enableSocialFeatures = "enable_social_features"
        static let maxWorkoutsPerDay = "max_workouts_per_day"
        static let showDetailedAnalytics = "show_detailed_analytics"
        static let enableHealthKitSync = "enable_healthkit_sync"
        static let appThemeVersion = "app_theme_version"
        static let recommendedHabits = "recommended_habits"
    }
    
    private init() {
        remoteConfig = RemoteConfig.remoteConfig()
        let settings = RemoteConfigSettings()
        #if DEBUG
        settings.minimumFetchInterval = 0 // No minimum fetch interval for debug builds
        #else
        settings.minimumFetchInterval = 3600 // 1 hour for production
        #endif
        remoteConfig.configSettings = settings
        
        // Set default values
        remoteConfig.setDefaults([
            Keys.enableWorkoutSharing: false as NSObject,
            Keys.enableSocialFeatures: false as NSObject,
            Keys.maxWorkoutsPerDay: 5 as NSObject,
            Keys.showDetailedAnalytics: true as NSObject,
            Keys.enableHealthKitSync: true as NSObject,
            Keys.appThemeVersion: 1 as NSObject,
            Keys.recommendedHabits: """
            [
                {"name": "Daily Water", "category": "health", "description": "Drink 8 glasses of water daily"},
                {"name": "Morning Stretch", "category": "fitness", "description": "5-minute stretching routine"},
                {"name": "Meditation", "category": "mindfulness", "description": "10-minute daily meditation"}
            ]
            """ as NSObject
        ])
        
        fetchConfig()
    }
    
    func fetchConfig() {
        remoteConfig.fetch { [weak self] status, error in
            if status == .success {
                self?.remoteConfig.activate { _, error in
                    if let error = error {
                        print("Error activating remote config: \(error.localizedDescription)")
                    } else {
                        print("Remote config activated successfully")
                        
                        // Notify any listeners that config has been updated
                        NotificationCenter.default.post(
                            name: NSNotification.Name("RemoteConfigUpdated"),
                            object: nil
                        )
                    }
                }
            } else if let error = error {
                print("Error fetching remote config: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Feature Flags
    
    var isWorkoutSharingEnabled: Bool {
        return remoteConfig.configValue(forKey: Keys.enableWorkoutSharing).boolValue
    }
    
    var isSocialFeaturesEnabled: Bool {
        return remoteConfig.configValue(forKey: Keys.enableSocialFeatures).boolValue
    }
    
    var isDetailedAnalyticsEnabled: Bool {
        return remoteConfig.configValue(forKey: Keys.showDetailedAnalytics).boolValue
    }
    
    var isHealthKitSyncEnabled: Bool {
        return remoteConfig.configValue(forKey: Keys.enableHealthKitSync).boolValue
    }
    
    // MARK: - Configuration Values
    
    var maxWorkoutsPerDay: Int {
        return remoteConfig.configValue(forKey: Keys.maxWorkoutsPerDay).numberValue.intValue
    }
    
    var appThemeVersion: Int {
        return remoteConfig.configValue(forKey: Keys.appThemeVersion).numberValue.intValue
    }
    
    var recommendedHabitsJson: String {
        return remoteConfig.configValue(forKey: Keys.recommendedHabits).stringValue ?? "[]"
    }
    
    // MARK: - Helper Methods
    
    func getRecommendedHabits() -> [RecommendedHabit] {
        guard let data = recommendedHabitsJson.data(using: .utf8) else {
            return []
        }
        
        do {
            return try JSONDecoder().decode([RecommendedHabit].self, from: data)
        } catch {
            print("Error decoding recommended habits: \(error.localizedDescription)")
            return []
        }
    }
}

// MARK: - Model for Recommended Habits
struct RecommendedHabit: Codable {
    let name: String
    let category: String
    let description: String
    
    func toHabit() -> Habit {
        let categoryEnum = HabitCategory(rawValue: category) ?? .other
        
        return Habit(
            id: UUID().uuidString,
            name: name,
            descriptionText: description,
            category: categoryEnum,
            frequency: .daily,
            targetDaysPerWeek: 7,
            startDate: Date()
        )
    }
}