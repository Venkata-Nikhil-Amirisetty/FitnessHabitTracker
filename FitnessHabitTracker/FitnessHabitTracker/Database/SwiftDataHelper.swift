//
//  SwiftDataHelper.swift
//  FitnessHabitTracker
//
//  Created by Nikhil Av on 4/16/25.
//

import Foundation
import SwiftData
import SwiftUI

// MARK: - SwiftDataHelper
/// Helper struct for SwiftData operations
struct SwiftDataHelper {
    
    // Use for sorting and filtering workouts and habits
    static func workoutPredicate(for type: WorkoutType?) -> Predicate<Workout> {
        if let type = type {
            return #Predicate<Workout> { workout in
                workout.typeName == type.rawValue
            }
        } else {
            return #Predicate<Workout> { _ in true }
        }
    }
    
    static func workoutSortDescriptors(by sortOption: WorkoutSortOption) -> [SortDescriptor<Workout>] {
        switch sortOption {
        case .dateDescending:
            return [SortDescriptor(\Workout.date, order: .reverse)]
        case .dateAscending:
            return [SortDescriptor(\Workout.date)]
        case .durationDescending:
            return [SortDescriptor(\Workout.duration, order: .reverse)]
        case .durationAscending:
            return [SortDescriptor(\Workout.duration)]
        case .caloriesDescending:
            return [SortDescriptor(\Workout.caloriesBurned, order: .reverse)]
        case .caloriesAscending:
            return [SortDescriptor(\Workout.caloriesBurned)]
        case .name:
            return [SortDescriptor(\Workout.name)]
        }
    }
    
    // Search workouts by name or notes
    static func searchPredicate(for query: String) -> Predicate<Workout> {
        if query.isEmpty {
            return #Predicate<Workout> { _ in true }
        } else {
            return #Predicate<Workout> { workout in
                workout.name.localizedStandardContains(query) ||
                (workout.notes?.localizedStandardContains(query) ?? false)
            }
        }
    }
    
    // MARK: - Advanced Search
    @MainActor
    static func combinedWorkoutPredicate(
        type: WorkoutType? = nil,
        query: String? = nil,
        dateRange: ClosedRange<Date>? = nil
    ) -> Predicate<Workout> {
        // Base predicate - matches everything
        var predicate = #Predicate<Workout> { _ in true }
        
        // Add type filter if provided
        if let type = type {
            let typePredicate = #Predicate<Workout> { workout in
                workout.typeName == type.rawValue
            }
            predicate = #Predicate<Workout> { workout in
                predicate.evaluate(workout) && typePredicate.evaluate(workout)
            }
        }
        
        // Add search query if provided
        if let query = query, !query.isEmpty {
            let queryPredicate = #Predicate<Workout> { workout in
                workout.name.localizedStandardContains(query) ||
                (workout.notes?.localizedStandardContains(query) ?? false)
            }
            predicate = #Predicate<Workout> { workout in
                predicate.evaluate(workout) && queryPredicate.evaluate(workout)
            }
        }
        
        // Add date range if provided
        if let dateRange = dateRange {
            let datePredicate = #Predicate<Workout> { workout in
                workout.date >= dateRange.lowerBound && workout.date <= dateRange.upperBound
            }
            predicate = #Predicate<Workout> { workout in
                predicate.evaluate(workout) && datePredicate.evaluate(workout)
            }
        }
        
        return predicate
    }
    
    // MARK: - Statistics and Aggregation
    
    // Calculate total calories burned in a time period
    static func calculateTotalCalories(from workouts: [Workout], in period: TimePeriod) -> Double {
        let filteredWorkouts = filterWorkoutsByPeriod(workouts, period: period)
        return filteredWorkouts.reduce(0) { $0 + $1.caloriesBurned }
    }
    
    // Calculate total workout duration in a time period (in minutes)
    static func calculateTotalDuration(from workouts: [Workout], in period: TimePeriod) -> Double {
        let filteredWorkouts = filterWorkoutsByPeriod(workouts, period: period)
        return filteredWorkouts.reduce(0) { $0 + $1.duration } / 60 // Convert seconds to minutes
    }
    
    // Filter workouts by time period
    private static func filterWorkoutsByPeriod(_ workouts: [Workout], period: TimePeriod) -> [Workout] {
        let calendar = Calendar.current
        let now = Date()
        
        switch period {
        case .today:
            let startOfDay = calendar.startOfDay(for: now)
            return workouts.filter { $0.date >= startOfDay }
            
        case .week:
            let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
            return workouts.filter { $0.date >= startOfWeek }
            
        case .month:
            let components = calendar.dateComponents([.year, .month], from: now)
            let startOfMonth = calendar.date(from: components)!
            return workouts.filter { $0.date >= startOfMonth }
            
        case .year:
            let components = calendar.dateComponents([.year], from: now)
            let startOfYear = calendar.date(from: components)!
            return workouts.filter { $0.date >= startOfYear }
            
        case .allTime:
            return workouts
        }
    }
}

// MARK: - Supporting Enums


enum TimePeriod: String, CaseIterable {
    case today = "Today"
    case week = "This Week"
    case month = "This Month"
    case year = "This Year"
    case allTime = "All Time"
}

// MARK: - SwiftData Preview Helper
extension ModelContainer {
    static var previewContainer: ModelContainer {
        do {
            let schema = Schema([Workout.self])
            let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
            let container = try ModelContainer(for: schema, configurations: [configuration])
            
            // This part needs to be run on the main actor
            Task { @MainActor in
                // Add sample data for previews
                let calendar = Calendar.current
                let now = Date()
                
                let sampleWorkouts = [
                    Workout(
                        name: "Morning Run",
                        type: .running,
                        duration: 1800, // 30 minutes
                        caloriesBurned: 320,
                        date: calendar.date(byAdding: .day, value: -1, to: now)!,
                        notes: "Felt great today, maintained good pace",
                        distance: 5.2,
                        intensity: .moderate
                    ),
                    Workout(
                        name: "Strength Training",
                        type: .weightTraining,
                        duration: 3600, // 60 minutes
                        caloriesBurned: 450,
                        date: calendar.date(byAdding: .day, value: -2, to: now)!,
                        notes: "Focused on upper body, increased weights",
                        intensity: .intense
                    ),
                    Workout(
                        name: "Yoga Session",
                        type: .yoga,
                        duration: 2700, // 45 minutes
                        caloriesBurned: 180,
                        date: calendar.date(byAdding: .day, value: -3, to: now)!,
                        intensity: .light
                    ),
                    Workout(
                        name: "Evening Bike Ride",
                        type: .cycling,
                        duration: 2400, // 40 minutes
                        caloriesBurned: 380,
                        date: calendar.date(byAdding: .day, value: -5, to: now)!,
                        notes: "Tried a new route around the park",
                        distance: 12.5,
                        intensity: .moderate
                    ),
                    Workout(
                        name: "HIIT Workout",
                        type: .hiit,
                        duration: 1200, // 20 minutes
                        caloriesBurned: 250,
                        date: calendar.date(byAdding: .day, value: -7, to: now)!,
                        intensity: .maximum,
                        averageHeartRate: 145,
                        maxHeartRate: 182
                    )
                ]
                
                // Insert sample data into container
                for workout in sampleWorkouts {
                    container.mainContext.insert(workout)
                }
            }
            
            return container
        } catch {
            // Fallback if container creation fails
            fatalError("Failed to create preview container: \(error.localizedDescription)")
        }
    }
}

// MARK: - SwiftData Preview Helper View Modifier
extension View {
    func modelContainerPreview<Content: View>(
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        return self
            .modelContainer(for: Workout.self, inMemory: true)
            .previewDisplayName("Preview with SwiftData")
    }
}
