//
//  Habit.swift
//  FitnessHabitTracker
//
//  Created by Nikhil Av on 4/16/25.
//


import Foundation
import SwiftUI
import SwiftData

// MARK: - Habit Model
@Model
final class Habit {
    @Attribute(.unique) var id: String
    var name: String
    var descriptionText: String?
    var categoryName: String
    var frequencyName: String
    var targetDaysPerWeek: Int
    var reminderTime: Date?
    var startDate: Date
    var completedDates: [Date]
    var isArchived: Bool
    
    // Weather-related properties (using computed properties with UserDefaults storage)
    var isWeatherSensitive: Bool {
        get {
            return UserDefaults.standard.bool(forKey: "habit_\(id)_weather_sensitive")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "habit_\(id)_weather_sensitive")
        }
    }
    
    var preferredWeatherConditions: [String] {
        get {
            return UserDefaults.standard.stringArray(forKey: "habit_\(id)_preferred_weather") ?? []
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "habit_\(id)_preferred_weather")
        }
    }
    
    var indoorAlternative: String? {
        get {
            return UserDefaults.standard.string(forKey: "habit_\(id)_indoor_alternative")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "habit_\(id)_indoor_alternative")
        }
    }
    
    init(id: String = UUID().uuidString,
         name: String,
         descriptionText: String? = nil,
         category: HabitCategory,
         frequency: HabitFrequency,
         targetDaysPerWeek: Int = 7,
         reminderTime: Date? = nil,
         startDate: Date = Date(),
         completedDates: [Date] = [],
         isArchived: Bool = false) {
        self.id = id
        self.name = name
        self.descriptionText = descriptionText
        self.categoryName = category.rawValue
        self.frequencyName = frequency.rawValue
        self.targetDaysPerWeek = targetDaysPerWeek
        self.reminderTime = reminderTime
        self.startDate = startDate
        self.completedDates = completedDates
        self.isArchived = isArchived
    }
    
    // MARK: - Computed Properties
    
    var category: HabitCategory {
        get {
            return HabitCategory(rawValue: categoryName) ?? .other
        }
        set {
            categoryName = newValue.rawValue
        }
    }
    
    var frequency: HabitFrequency {
        get {
            return HabitFrequency(rawValue: frequencyName) ?? .daily
        }
        set {
            frequencyName = newValue.rawValue
        }
    }
    
    var currentStreak: Int {
        return calculateStreak()
    }
    
    // MARK: - Methods
    
    private func calculateStreak() -> Int {
        // Simple implementation - can be enhanced
        let calendar = Calendar.current
        let sortedDates = completedDates.sorted(by: >)
        
        guard let lastCompletedDate = sortedDates.first else { return 0 }
        
        // If last completion wasn't today or yesterday, streak is broken
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let lastCompletedDay = calendar.startOfDay(for: lastCompletedDate)
        
        if lastCompletedDay != today && lastCompletedDay != yesterday {
            return 0
        }
        
        // Count consecutive days
        var streak = 1
        var currentDate = lastCompletedDay
        
        while true {
            let previousDate = calendar.date(byAdding: .day, value: -1, to: currentDate)!
            
            if sortedDates.contains(where: { calendar.isDate($0, inSameDayAs: previousDate) }) {
                streak += 1
                currentDate = previousDate
            } else {
                break
            }
        }
        
        return streak
    }
    
    // MARK: - Weather-related Methods
    
    // Check if current weather is suitable for this habit
    func isWeatherSuitable(weatherData: WeatherData?) -> Bool {
        guard isWeatherSensitive, let weatherData = weatherData else { return true }
        
        // If no preferences are set, assume any weather is ok
        if preferredWeatherConditions.isEmpty {
            return true
        }
        
        let currentCondition = weatherData.weather.first?.main.lowercased() ?? ""
        let isPreferredCondition = preferredWeatherConditions
            .contains(where: { currentCondition.contains($0.lowercased()) })
        
        // Check temperature preferences
        let containsHot = preferredWeatherConditions.contains("Hot")
        let containsCold = preferredWeatherConditions.contains("Cold")
        
        // If user prefers hot weather but it's cold, or vice versa
        if (containsHot && weatherData.main.isCold) || (containsCold && weatherData.main.isHot) {
            return false
        }
        
        // If current weather matches any preferred condition
        if isPreferredCondition {
            return true
        }
        
        // If user prefers sunny/clear but it's rainy/snowy
        if (preferredWeatherConditions.contains("Sunny") ||
            preferredWeatherConditions.contains("Clear")) &&
           (weatherData.weather.first?.isRainy == true ||
            weatherData.weather.first?.isSnowy == true) {
            return false
        }
        
        // Default to true for general preferences
        return preferredWeatherConditions.contains("Any") ||
               preferredWeatherConditions.contains(where: { $0.lowercased() == "any" })
    }
    
    // Get the weather-adjusted habit name
    func getWeatherAdjustedName(weatherData: WeatherData?) -> String {
        guard isWeatherSensitive,
              let weatherData = weatherData,
              !isWeatherSuitable(weatherData: weatherData),
              let alternative = indoorAlternative,
              !alternative.isEmpty else {
            return name
        }
        
        return "\(name) (Indoor: \(alternative))"
    }
    
    // Get weather recommendation text for the habit
    func getWeatherRecommendation(weatherData: WeatherData?) -> String? {
        guard isWeatherSensitive, let weatherData = weatherData else { return nil }
        
        if !isWeatherSuitable(weatherData: weatherData) {
            return "Weather may impact this habit. Consider the indoor alternative."
        }
        
        return "Current weather is suitable for this habit."
    }
}

// MARK: - Supporting Enums
enum HabitCategory: String, Codable, CaseIterable {
    case health
    case fitness
    case mindfulness
    case productivity
    case learning
    case other
    
    var icon: String {
        switch self {
        case .health: return "heart.fill"
        case .fitness: return "figure.walk"
        case .mindfulness: return "brain.head.profile"
        case .productivity: return "checklist"
        case .learning: return "book.fill"
        case .other: return "star.fill"
        }
    }
}

enum HabitFrequency: String, Codable, CaseIterable {
    case daily
    case weekdays
    case weekends
    case custom
}

// MARK: - Weather Condition Enum
enum WeatherCondition: String, CaseIterable, Identifiable {
    case sunny = "Sunny"
    case clear = "Clear"
    case cloudy = "Cloudy"
    case partlyCloudy = "Partly Cloudy"
    case rainy = "Rainy"
    case snowy = "Snowy"
    case windy = "Windy"
    case fog = "Fog"
    case hot = "Hot"
    case cold = "Cold"
    case any = "Any"
    
    var id: String { self.rawValue }
    
    var systemIconName: String {
        switch self {
        case .sunny: return "sun.max"
        case .clear: return "sun.max"
        case .cloudy: return "cloud"
        case .partlyCloudy: return "cloud.sun"
        case .rainy: return "cloud.rain"
        case .snowy: return "cloud.snow"
        case .windy: return "wind"
        case .fog: return "cloud.fog"
        case .hot: return "thermometer.sun"
        case .cold: return "thermometer.snowflake"
        case .any: return "checkmark.circle"
        }
    }
    
    var color: Color {
        switch self {
        case .sunny, .clear: return .orange
        case .cloudy, .partlyCloudy: return .gray
        case .rainy: return .blue
        case .snowy: return .cyan
        case .windy: return .mint
        case .fog: return .gray.opacity(0.7)
        case .hot: return .red
        case .cold: return .indigo
        case .any: return .green
        }
    }
}
