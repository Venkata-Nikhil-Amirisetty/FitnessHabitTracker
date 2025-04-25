//
//  Workout.swift
//  FitnessHabitTracker
//
//  Created by Nikhil Av on 4/16/25.
//  Updated with SwiftData implementation

import Foundation
import SwiftUI
import SwiftData

@Model
final class Workout {
    var id: String
    var name: String
    var typeName: String // Store enum as String
    var duration: TimeInterval
    var caloriesBurned: Double
    var date: Date
    var notes: String?
    
    // New fields
    var distance: Double?  // stored in kilometers
    var intensityName: String? // Store enum as String
    var averageHeartRate: Double?
    var maxHeartRate: Double?
    
    init(id: String = UUID().uuidString,
         name: String,
         type: WorkoutType,
         duration: TimeInterval,
         caloriesBurned: Double,
         date: Date = Date(),
         notes: String? = nil,
         distance: Double? = nil,
         intensity: WorkoutIntensity? = nil,
         averageHeartRate: Double? = nil,
         maxHeartRate: Double? = nil) {
        self.id = id
        self.name = name
        self.typeName = type.rawValue
        self.duration = duration
        self.caloriesBurned = caloriesBurned
        self.date = date
        self.notes = notes
        self.distance = distance
        self.intensityName = intensity?.rawValue
        self.averageHeartRate = averageHeartRate
        self.maxHeartRate = maxHeartRate
    }
    
    // Computed properties to convert between String and Enum
    var type: WorkoutType {
        get {
            return WorkoutType(rawValue: typeName) ?? .other
        }
        set {
            typeName = newValue.rawValue
        }
    }
    
    var intensity: WorkoutIntensity? {
        get {
            guard let intensityName = intensityName else { return nil }
            return WorkoutIntensity(rawValue: intensityName)
        }
        set {
            intensityName = newValue?.rawValue
        }
    }
    
    // Format pace as minutes:seconds per distance unit
    func formatPace(unit: DistanceUnit = .km) -> String? {
        guard let distance = self.distance, distance > 0 else {
            return nil
        }
        
        let distanceValue = unit == .km ?
            distance :
            distance / 1.60934
        
        let paceInSeconds = duration / distanceValue
        let minutes = Int(paceInSeconds / 60)
        let seconds = Int(paceInSeconds.truncatingRemainder(dividingBy: 60))
        
        return String(format: "%d:%02d min/%@", minutes, seconds, unit.rawValue)
    }
    
    // Calculate estimated calorie burn if not provided
    static func estimateCalories(
        type: WorkoutType,
        duration: TimeInterval,
        intensity: WorkoutIntensity,
        userWeight: Double?
    ) -> Double {
        // Default weight if not provided (70kg)
        let weight = userWeight ?? 70.0
        
        // Base MET values by workout type
        let baseMET: Double
        switch type {
        case .running: baseMET = 8.0
        case .walking: baseMET = 3.5
        case .cycling: baseMET = 7.0
        case .swimming: baseMET = 6.0
        case .weightTraining: baseMET = 5.0
        case .yoga: baseMET = 3.0
        case .hiit: baseMET = 9.0
        case .other: baseMET = 5.0
        }
        
        // Intensity multiplier
        let intensityMultiplier: Double
        switch intensity {
        case .light: intensityMultiplier = 0.8
        case .moderate: intensityMultiplier = 1.0
        case .intense: intensityMultiplier = 1.2
        case .maximum: intensityMultiplier = 1.5
        }
        
        // Calculate calories: MET * weight (kg) * duration (hours)
        let durationInHours = duration / 3600
        let calories = baseMET * intensityMultiplier * weight * durationInHours
        
        return calories
    }
}

// Helper Enums (not part of SwiftData model but used by Workout)
enum WorkoutType: String, Codable, CaseIterable {
    case running
    case walking
    case cycling
    case swimming
    case weightTraining
    case yoga
    case hiit
    case other
    
    var icon: String {
        switch self {
        case .running: return "figure.run"
        case .walking: return "figure.walk"
        case .cycling: return "bicycle"
        case .swimming: return "figure.pool.swim"
        case .weightTraining: return "dumbbell"
        case .yoga: return "figure.mind.and.body"
        case .hiit: return "heart.circle"
        case .other: return "figure.mixed.cardio"
        }
    }
    
    var requiresDistance: Bool {
        switch self {
        case .running, .walking, .cycling, .swimming:
            return true
        default:
            return false
        }
    }
}


