//
//  AnalyticsManager.swift
//  FitnessHabitTracker
//
//  Created by Nikhil Av on 4/19/25.
//


import Foundation
import FirebaseAnalytics

class AnalyticsManager {
    static let shared = AnalyticsManager()
    
    private init() {}
    
    // MARK: - User Analytics
    
    func logUserSignUp(method: String) {
        Analytics.logEvent(AnalyticsEventSignUp, parameters: [
            AnalyticsParameterMethod: method
        ])
    }
    
    func logUserLogin(method: String) {
        Analytics.logEvent(AnalyticsEventLogin, parameters: [
            AnalyticsParameterMethod: method
        ])
    }
    
    func logProfileUpdate() {
        Analytics.logEvent("profile_updated", parameters: nil)
    }
    
    // MARK: - Workout Analytics
    
    func logWorkoutAdded(workout: Workout) {
        Analytics.logEvent("workout_added", parameters: [
            "workout_id": workout.id,
            "workout_type": workout.typeName,
            "duration": workout.duration,
            "calories": workout.caloriesBurned
        ])
    }
    
    func logWorkoutCompleted(workout: Workout) {
        Analytics.logEvent("workout_completed", parameters: [
            "workout_id": workout.id,
            "workout_type": workout.typeName,
            "duration": workout.duration,
            "calories": workout.caloriesBurned
        ])
    }
    
    func logWorkoutDeleted(workoutType: String) {
        Analytics.logEvent("workout_deleted", parameters: [
            "workout_type": workoutType
        ])
    }
    
    // MARK: - Habit Analytics
    
    func logHabitAdded(habit: Habit) {
        Analytics.logEvent("habit_added", parameters: [
            "habit_id": habit.id,
            "habit_name": habit.name,
            "habit_category": habit.categoryName
        ])
    }
    
    func logHabitCompleted(habit: Habit) {
        Analytics.logEvent("habit_completed", parameters: [
            "habit_id": habit.id,
            "habit_name": habit.name,
            "habit_category": habit.categoryName,
            "habit_streak": habit.currentStreak
        ])
    }
    
    func logHabitStreak(habitId: String, streakCount: Int) {
        Analytics.logEvent("habit_streak", parameters: [
            "habit_id": habitId,
            "streak_count": streakCount
        ])
    }
    
    // MARK: - Features Analytics
    
    func logFeatureUsage(featureName: String) {
        Analytics.logEvent("feature_used", parameters: [
            "feature_name": featureName
        ])
    }
    
    func logScreenView(screenName: String, screenClass: String) {
        Analytics.logEvent(AnalyticsEventScreenView, parameters: [
            AnalyticsParameterScreenName: screenName,
            AnalyticsParameterScreenClass: screenClass
        ])
    }
    
    // MARK: - Error Analytics
    
    func logError(domain: String, code: Int, description: String) {
        Analytics.logEvent("app_error", parameters: [
            "error_domain": domain,
            "error_code": code,
            "error_description": description
        ])
    }
}

// MARK: - Analytics Extension for ViewModels

extension AuthViewModel {
    func trackLogin(email: String) {
        AnalyticsManager.shared.logUserLogin(method: "email")
    }
    
    func trackSignUp(email: String) {
        AnalyticsManager.shared.logUserSignUp(method: "email")
    }
    
    func trackProfileUpdate() {
        AnalyticsManager.shared.logProfileUpdate()
    }
}

extension WorkoutViewModel {
    func trackWorkoutAdded(_ workout: Workout) {
        AnalyticsManager.shared.logWorkoutAdded(workout: workout)
    }
    
    func trackWorkoutCompleted(_ workout: Workout) {
        AnalyticsManager.shared.logWorkoutCompleted(workout: workout)
    }
    
    func trackWorkoutDeleted(_ workout: Workout) {
        AnalyticsManager.shared.logWorkoutDeleted(workoutType: workout.typeName)
    }
}

extension HabitViewModel {
    func trackHabitAdded(_ habit: Habit) {
        AnalyticsManager.shared.logHabitAdded(habit: habit)
    }
    
    func trackHabitCompleted(_ habit: Habit) {
        AnalyticsManager.shared.logHabitCompleted(habit: habit)
        
        // Track streak milestones
        let streak = habit.currentStreak
        if streak > 0 && streak % 7 == 0 {  // Track weekly milestones
            AnalyticsManager.shared.logHabitStreak(habitId: habit.id, streakCount: streak)
        }
    }
}
