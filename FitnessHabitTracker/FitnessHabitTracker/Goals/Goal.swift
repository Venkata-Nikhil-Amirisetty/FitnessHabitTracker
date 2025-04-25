//
//  Goal.swift
//  FitnessHabitTracker
//
//  Created by Nikhil Av on 4/21/25.
//  Updated for improved SwiftData persistence

import Foundation
import SwiftData

@Model
final class Goal {
    var id: String
    var userId: String
    var title: String
    var typeString: String
    var targetValue: Double
    var currentValue: Double
    var startDate: Date
    var endDate: Date
    var timeframeString: String
    var statusString: String
    var notes: String?
    var lastUpdated: Date
    var linkedWorkoutType: String?
    var linkedHabitId: String?
    
    // Computed properties
    var type: GoalType {
        get { return GoalType(rawValue: typeString) ?? .workout }
        set { typeString = newValue.rawValue }
    }
    
    var timeframe: GoalTimeframe {
        get { return GoalTimeframe(rawValue: timeframeString) ?? .weekly }
        set { timeframeString = newValue.rawValue }
    }
    
    var status: GoalStatus {
        get { return GoalStatus(rawValue: statusString) ?? .active }
        set { statusString = newValue.rawValue }
    }
    
    var progress: Double {
        return min(currentValue / targetValue, 1.0)
    }
    
    var remainingDays: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: endDate)
        return max(components.day ?? 0, 0)
    }
    
    var isExpired: Bool {
        return Date() > endDate && status == .active
    }
    
    init(id: String = UUID().uuidString,
         userId: String,
         title: String,
         type: GoalType,
         targetValue: Double,
         currentValue: Double = 0,
         startDate: Date = Date(),
         endDate: Date? = nil,
         timeframe: GoalTimeframe = .weekly,
         status: GoalStatus = .active,
         notes: String? = nil,
         lastUpdated: Date = Date(),
         linkedWorkoutType: String? = nil,
         linkedHabitId: String? = nil) {
        
        self.id = id
        self.userId = userId
        self.title = title
        self.typeString = type.rawValue
        self.targetValue = targetValue
        self.currentValue = currentValue
        self.startDate = startDate
        self.lastUpdated = lastUpdated
        
        // Calculate end date if not provided
        if let endDate = endDate {
            self.endDate = endDate
        } else {
            let calendar = Calendar.current
            switch timeframe {
            case .daily:
                self.endDate = calendar.date(byAdding: .day, value: 1, to: startDate) ?? startDate
            case .weekly:
                self.endDate = calendar.date(byAdding: .day, value: 7, to: startDate) ?? startDate
            case .monthly:
                self.endDate = calendar.date(byAdding: .month, value: 1, to: startDate) ?? startDate
            case .custom:
                self.endDate = calendar.date(byAdding: .day, value: 30, to: startDate) ?? startDate
            }
        }
        
        self.timeframeString = timeframe.rawValue
        self.statusString = status.rawValue
        self.notes = notes
        self.linkedWorkoutType = linkedWorkoutType
        self.linkedHabitId = linkedHabitId
    }
    
    func updateProgress(newValue: Double) {
        currentValue = newValue
        lastUpdated = Date()
        
        // Check if goal is completed
        if currentValue >= targetValue {
            status = .completed
        }
        
        // Check if goal has expired
        if isExpired && status == .active {
            if currentValue >= targetValue {
                status = .completed
            } else {
                status = .failed
            }
        }
    }
    
    func incrementProgress(by amount: Double = 1.0) {
        updateProgress(newValue: currentValue + amount)
    }
    
    // Helper methods for linking with workouts and habits
    func isLinkedToWorkout(_ workout: Workout) -> Bool {
        if let linkedType = linkedWorkoutType {
            return workout.typeName == linkedType
        }
        // For general workout goals with no specific type linked
        return type == .workout && linkedWorkoutType == nil
    }
    
    func isLinkedToHabit(_ habit: Habit) -> Bool {
        if let linkedId = linkedHabitId {
            return habit.id == linkedId
        }
        // For general habit goals with no specific habit linked
        return (type == .habit || type == .streak) && linkedHabitId == nil
    }
}

// Goal Type Enum
enum GoalType: String, Codable, CaseIterable {
    case workout = "workout"
    case habit = "habit"
    case distance = "distance"
    case duration = "duration"
    case streak = "streak"
    case weight = "weight"
    
    var icon: String {
        switch self {
        case .workout: return "figure.walk"
        case .habit: return "checklist"
        case .distance: return "ruler"
        case .duration: return "clock"
        case .streak: return "flame"
        case .weight: return "scalemass"
        }
    }
    
    var displayName: String {
        switch self {
        case .workout: return "Workout Count"
        case .habit: return "Habit Completion"
        case .distance: return "Distance"
        case .duration: return "Duration"
        case .streak: return "Streak"
        case .weight: return "Weight"
        }
    }
}

// Goal Status Enum
enum GoalStatus: String, Codable {
    case active = "active"
    case completed = "completed"
    case failed = "failed"
    case archived = "archived"
}

// Timeframe Enum
enum GoalTimeframe: String, Codable, CaseIterable {
    case daily = "daily"
    case weekly = "weekly"
    case monthly = "monthly"
    case custom = "custom"
    
    var displayName: String {
        self.rawValue.capitalized
    }
}
