//
//  DemoDataGenerator.swift
//  FitnessHabitTracker
//
//  Created by Nikhil Av on 4/20/25.
//

import Foundation
import SwiftData
import FirebaseFirestore
import FirebaseAuth

class DemoDataGenerator {
    
    static func generateDemoData(for userId: String, modelContext: ModelContext, completion: @escaping (Bool) -> Void) {
        let dispatchGroup = DispatchGroup()
        var success = true
        
        // Generate demo workouts
        dispatchGroup.enter()
        generateDemoWorkouts(for: userId, modelContext: modelContext) { result in
            if !result {
                success = false
            }
            dispatchGroup.leave()
        }
        
        // Generate demo habits
        dispatchGroup.enter()
        generateDemoHabits(for: userId, modelContext: modelContext) { result in
            if !result {
                success = false
            }
            dispatchGroup.leave()
        }
        
        dispatchGroup.notify(queue: .main) {
            completion(success)
        }
    }
    
    // MARK: - Generate Demo Workouts
    
    private static func generateDemoWorkouts(for userId: String, modelContext: ModelContext, completion: @escaping (Bool) -> Void) {
        let calendar = Calendar.current
        let now = Date()
        var success = true
        let dispatchGroup = DispatchGroup()
        
        // Sample workout data with expanded examples
        let demoWorkouts: [Workout] = [
            // TODAY
            Workout(
                name: "Morning Run",
                type: .running,
                duration: 1800, // 30 minutes
                caloriesBurned: 320,
                date: calendar.date(byAdding: .hour, value: -6, to: now)!,
                notes: "Great morning run around the park. Weather was perfect!",
                distance: 5.2,
                intensity: .moderate,
                averageHeartRate: 145,
                maxHeartRate: 165
            ),
            
            // YESTERDAY
            Workout(
                name: "Weight Training",
                type: .weightTraining,
                duration: 3600, // 60 minutes
                caloriesBurned: 450,
                date: calendar.date(byAdding: .day, value: -1, to: now)!,
                notes: "Focus on upper body. Increased weight on bench press.",
                intensity: .intense,
                averageHeartRate: 135,
                maxHeartRate: 160
            ),
            
            // 2 days ago
            Workout(
                name: "Yoga Session",
                type: .yoga,
                duration: 2700, // 45 minutes
                caloriesBurned: 180,
                date: calendar.date(byAdding: .day, value: -2, to: now)!,
                notes: "Relaxing yoga session. Worked on flexibility.",
                intensity: .light,
                averageHeartRate: 110,
                maxHeartRate: 125
            ),
            
            // 3 days ago
            Workout(
                name: "Morning HIIT",
                type: .hiit,
                duration: 1500, // 25 minutes
                caloriesBurned: 280,
                date: calendar.date(bySettingHour: 7, minute: 30, second: 0, of: calendar.date(byAdding: .day, value: -3, to: now)!)!,
                notes: "Quick morning burst. Felt energized all day.",
                intensity: .intense,
                averageHeartRate: 155,
                maxHeartRate: 180
            ),
            
            // 4 days ago
            Workout(
                name: "Evening Bike Ride",
                type: .cycling,
                duration: 2400, // 40 minutes
                caloriesBurned: 380,
                date: calendar.date(byAdding: .day, value: -4, to: now)!,
                notes: "Tried a new route around the lake. Great views!",
                distance: 12.5,
                intensity: .moderate,
                averageHeartRate: 150,
                maxHeartRate: 170
            ),
            
            // 5 days ago
            Workout(
                name: "Lunch Walk",
                type: .walking,
                duration: 1800, // 30 minutes
                caloriesBurned: 150,
                date: calendar.date(bySettingHour: 12, minute: 15, second: 0, of: calendar.date(byAdding: .day, value: -5, to: now)!)!,
                notes: "Nice break in the middle of the workday.",
                distance: 2.5,
                intensity: .light,
                averageHeartRate: 105,
                maxHeartRate: 120
            ),
            
            // 6 days ago
            Workout(
                name: "Swimming Laps",
                type: .swimming,
                duration: 2100, // 35 minutes
                caloriesBurned: 310,
                date: calendar.date(byAdding: .day, value: -6, to: now)!,
                notes: "Focused on backstroke technique today.",
                distance: 1.8,
                intensity: .moderate,
                averageHeartRate: 140,
                maxHeartRate: 155
            ),
            
            // 1 week ago
            Workout(
                name: "HIIT Workout",
                type: .hiit,
                duration: 1200, // 20 minutes
                caloriesBurned: 250,
                date: calendar.date(byAdding: .day, value: -7, to: now)!,
                notes: "Intense but short workout. Focused on burpees and mountain climbers.",
                intensity: .maximum,
                averageHeartRate: 160,
                maxHeartRate: 185
            ),
            
            // 8 days ago
            Workout(
                name: "Swim Practice",
                type: .swimming,
                duration: 1800, // 30 minutes
                caloriesBurned: 300,
                date: calendar.date(byAdding: .day, value: -8, to: now)!,
                notes: "Pool was quiet today. Practiced freestyle technique.",
                distance: 1.5,
                intensity: .moderate,
                averageHeartRate: 130,
                maxHeartRate: 150
            ),
            
            // 9 days ago
            Workout(
                name: "Core Strengthening",
                type: .weightTraining,
                duration: 2700, // 45 minutes
                caloriesBurned: 350,
                date: calendar.date(byAdding: .day, value: -9, to: now)!,
                notes: "Focus on abs and lower back. Added planks to routine.",
                intensity: .moderate,
                averageHeartRate: 125,
                maxHeartRate: 145
            ),
            
            // 10 days ago
            Workout(
                name: "Evening Yoga",
                type: .yoga,
                duration: 3600, // 60 minutes
                caloriesBurned: 220,
                date: calendar.date(bySettingHour: 19, minute: 0, second: 0, of: calendar.date(byAdding: .day, value: -10, to: now)!)!,
                notes: "Deep stretching and meditation. Really needed this.",
                intensity: .moderate,
                averageHeartRate: 100,
                maxHeartRate: 115
            ),
            
            // 11 days ago
            Workout(
                name: "Interval Running",
                type: .running,
                duration: 2400, // 40 minutes
                caloriesBurned: 410,
                date: calendar.date(byAdding: .day, value: -11, to: now)!,
                notes: "Sprint intervals. Pushing my pace on each interval.",
                distance: 6.5,
                intensity: .intense,
                averageHeartRate: 160,
                maxHeartRate: 185
            ),
            
            // 12 days ago
            Workout(
                name: "Nature Hike",
                type: .walking,
                duration: 5400, // 90 minutes
                caloriesBurned: 450,
                date: calendar.date(byAdding: .day, value: -12, to: now)!,
                notes: "Beautiful trail in the mountains. Moderate elevation gain.",
                distance: 7.5,
                intensity: .moderate,
                averageHeartRate: 125,
                maxHeartRate: 150
            ),
            
            // Two weeks ago
            Workout(
                name: "Long Walk",
                type: .walking,
                duration: 3600, // 60 minutes
                caloriesBurned: 250,
                date: calendar.date(byAdding: .day, value: -14, to: now)!,
                notes: "Relaxing walk through the city. Stopped for coffee.",
                distance: 5.0,
                intensity: .light,
                averageHeartRate: 110,
                maxHeartRate: 125
            ),
            
            // 15 days ago
            Workout(
                name: "Group Cycling Class",
                type: .cycling,
                duration: 2700, // 45 minutes
                caloriesBurned: 520,
                date: calendar.date(byAdding: .day, value: -15, to: now)!,
                notes: "Intense spinning class with intervals. Great instructor!",
                distance: 18.0,
                intensity: .intense,
                averageHeartRate: 165,
                maxHeartRate: 182
            ),
            
            // 16 days ago
            Workout(
                name: "Leg Day",
                type: .weightTraining,
                duration: 3300, // 55 minutes
                caloriesBurned: 420,
                date: calendar.date(byAdding: .day, value: -16, to: now)!,
                notes: "Squats, deadlifts, and leg press. Will feel this tomorrow!",
                intensity: .intense,
                averageHeartRate: 140,
                maxHeartRate: 165
            ),
            
            // 17 days ago
            Workout(
                name: "Recovery Swim",
                type: .swimming,
                duration: 1200, // 20 minutes
                caloriesBurned: 180,
                date: calendar.date(byAdding: .day, value: -17, to: now)!,
                notes: "Easy swim to recover from leg day.",
                distance: 0.8,
                intensity: .light,
                averageHeartRate: 115,
                maxHeartRate: 130
            ),
            
            // 18 days ago
            Workout(
                name: "HIIT Circuit",
                type: .hiit,
                duration: 1800, // 30 minutes
                caloriesBurned: 350,
                date: calendar.date(bySettingHour: 18, minute: 30, second: 0, of: calendar.date(byAdding: .day, value: -18, to: now)!)!,
                notes: "Circuit training with kettlebells and bodyweight exercises.",
                intensity: .intense,
                averageHeartRate: 155,
                maxHeartRate: 175
            ),
            
            // Three weeks ago
            Workout(
                name: "Trail Running",
                type: .running,
                duration: 2700, // 45 minutes
                caloriesBurned: 400,
                date: calendar.date(byAdding: .day, value: -21, to: now)!,
                notes: "Challenging trail with lots of hills. Beautiful scenery!",
                distance: 7.5,
                intensity: .intense,
                averageHeartRate: 155,
                maxHeartRate: 180
            ),
            
            // 23 days ago
            Workout(
                name: "Morning Yoga",
                type: .yoga,
                duration: 1800, // 30 minutes
                caloriesBurned: 150,
                date: calendar.date(bySettingHour: 6, minute: 30, second: 0, of: calendar.date(byAdding: .day, value: -23, to: now)!)!,
                notes: "Sun salutations to start the day. Feel energized.",
                intensity: .light,
                averageHeartRate: 95,
                maxHeartRate: 110
            ),
            
            // 25 days ago
            Workout(
                name: "Quick Run",
                type: .running,
                duration: 1500, // 25 minutes
                caloriesBurned: 280,
                date: calendar.date(byAdding: .day, value: -25, to: now)!,
                notes: "Rushed but effective. Good pace.",
                distance: 4.0,
                intensity: .moderate,
                averageHeartRate: 150,
                maxHeartRate: 170
            ),
            
            // 26 days ago
            Workout(
                name: "Long Bike Ride",
                type: .cycling,
                duration: 5400, // 90 minutes
                caloriesBurned: 750,
                date: calendar.date(bySettingHour: 9, minute: 0, second: 0, of: calendar.date(byAdding: .day, value: -26, to: now)!)!,
                notes: "Weekend ride along the coast. Perfect day for it.",
                distance: 35.0,
                intensity: .moderate,
                averageHeartRate: 145,
                maxHeartRate: 165
            ),
            
            // 28 days ago
            Workout(
                name: "Full Body Workout",
                type: .weightTraining,
                duration: 3900, // 65 minutes
                caloriesBurned: 480,
                date: calendar.date(byAdding: .day, value: -28, to: now)!,
                notes: "Complete routine hitting all major muscle groups.",
                intensity: .intense,
                averageHeartRate: 135,
                maxHeartRate: 160
            ),
            
            // 30 days ago
            Workout(
                name: "Tabata Session",
                type: .hiit,
                duration: 1200, // 20 minutes
                caloriesBurned: 280,
                date: calendar.date(byAdding: .day, value: -30, to: now)!,
                notes: "Eight rounds of 20 seconds on, 10 seconds off. Brutal!",
                intensity: .maximum,
                averageHeartRate: 165,
                maxHeartRate: 190
            )
        ]
        
        // Save to local SwiftData
        for workout in demoWorkouts {
            modelContext.insert(workout)
        }
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to save demo workouts to SwiftData: \(error.localizedDescription)")
            success = false
        }
        
        // Save to Firebase
        let db = FirebaseManager.shared.firestore
        
        for workout in demoWorkouts {
            dispatchGroup.enter()
            
            let workoutRef = db.collection("users").document(userId).collection("workouts").document(workout.id)
            let workoutData = FirebaseManager.shared.dictionaryFromWorkout(workout)
            
            workoutRef.setData(workoutData) { error in
                if let error = error {
                    print("Error adding demo workout to Firebase: \(error.localizedDescription)")
                    success = false
                }
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            completion(success)
        }
    }
    
    // MARK: - Generate Demo Habits
    
    private static func generateDemoHabits(for userId: String, modelContext: ModelContext, completion: @escaping (Bool) -> Void) {
        let calendar = Calendar.current
        let now = Date()
        var success = true
        let dispatchGroup = DispatchGroup()
        
        // Sample completed dates for habits
        let dailyMeditationDates = generateCompletedDates(startingFrom: calendar.date(byAdding: .day, value: -30, to: now)!, consistencyPercentage: 80)
        let drinkWaterDates = generateCompletedDates(startingFrom: calendar.date(byAdding: .day, value: -45, to: now)!, consistencyPercentage: 90)
        let readingDates = generateCompletedDates(startingFrom: calendar.date(byAdding: .day, value: -60, to: now)!, consistencyPercentage: 60)
        let stretchingDates = generateCompletedDates(startingFrom: calendar.date(byAdding: .day, value: -14, to: now)!, consistencyPercentage: 70)
        let vitaminsDate = generateCompletedDates(startingFrom: calendar.date(byAdding: .day, value: -90, to: now)!, consistencyPercentage: 85)
        
        // Create reminder times
        let morningReminderTime = calendar.date(bySettingHour: 8, minute: 0, second: 0, of: now)!
        let eveningReminderTime = calendar.date(bySettingHour: 20, minute: 0, second: 0, of: now)!
        
        // Sample habit data
        let demoHabits: [Habit] = [
            Habit(
                name: "Daily Meditation",
                descriptionText: "10 minutes of mindfulness meditation to start the day",
                category: .mindfulness,
                frequency: .daily,
                targetDaysPerWeek: 7,
                reminderTime: morningReminderTime,
                startDate: calendar.date(byAdding: .day, value: -30, to: now)!,
                completedDates: dailyMeditationDates
            ),
            
            Habit(
                name: "Drink 8 Glasses of Water",
                descriptionText: "Stay hydrated throughout the day",
                category: .health,
                frequency: .daily,
                targetDaysPerWeek: 7,
                reminderTime: nil,
                startDate: calendar.date(byAdding: .day, value: -45, to: now)!,
                completedDates: drinkWaterDates
            ),
            
            Habit(
                name: "Read for 30 Minutes",
                descriptionText: "Read a book before bed to improve knowledge and relax",
                category: .learning,
                frequency: .daily,
                targetDaysPerWeek: 7,
                reminderTime: eveningReminderTime,
                startDate: calendar.date(byAdding: .day, value: -60, to: now)!,
                completedDates: readingDates
            ),
            
            Habit(
                name: "Morning Stretching",
                descriptionText: "5 minutes of stretching exercises to start the day",
                category: .fitness,
                frequency: .daily,
                targetDaysPerWeek: 7,
                reminderTime: calendar.date(bySettingHour: 7, minute: 0, second: 0, of: now)!,
                startDate: calendar.date(byAdding: .day, value: -14, to: now)!,
                completedDates: stretchingDates,
            ),
            
            Habit(
                name: "Take Vitamins",
                descriptionText: "Take daily multivitamins with breakfast",
                category: .health,
                frequency: .daily,
                targetDaysPerWeek: 7,
                reminderTime: calendar.date(bySettingHour: 9, minute: 0, second: 0, of: now)!,
                startDate: calendar.date(byAdding: .day, value: -90, to: now)!,
                completedDates: vitaminsDate
            ),
            
            Habit(
                name: "Weekend Meal Prep",
                descriptionText: "Prepare healthy meals for the week ahead",
                category: .health,
                frequency: .weekends,
                targetDaysPerWeek: 1,
                reminderTime: calendar.date(bySettingHour: 10, minute: 0, second: 0, of: now)!,
                startDate: calendar.date(byAdding: .day, value: -21, to: now)!,
                completedDates: [
                    calendar.date(byAdding: .day, value: -21, to: now)!,
                    calendar.date(byAdding: .day, value: -14, to: now)!,
                    calendar.date(byAdding: .day, value: -7, to: now)!
                ]
            ),
            
            Habit(
                name: "No Screens After 10pm",
                descriptionText: "Improve sleep by avoiding screens before bed",
                category: .health,
                frequency: .weekdays,
                targetDaysPerWeek: 5,
                reminderTime: calendar.date(bySettingHour: 21, minute: 45, second: 0, of: now)!,
                startDate: calendar.date(byAdding: .day, value: -10, to: now)!,
                completedDates: [
                    calendar.date(byAdding: .day, value: -10, to: now)!,
                    calendar.date(byAdding: .day, value: -9, to: now)!,
                    calendar.date(byAdding: .day, value: -8, to: now)!,
                    calendar.date(byAdding: .day, value: -5, to: now)!,
                    calendar.date(byAdding: .day, value: -4, to: now)!,
                    calendar.date(byAdding: .day, value: -3, to: now)!,
                    calendar.date(byAdding: .day, value: -2, to: now)!
                ]
            ),
            
            // Additional habits
            Habit(
                name: "Outdoor Run",
                descriptionText: "30-minute run outdoors for cardiovascular health",
                category: .fitness,
                frequency: .custom,
                targetDaysPerWeek: 3,
                reminderTime: calendar.date(bySettingHour: 17, minute: 30, second: 0, of: now)!,
                startDate: calendar.date(byAdding: .day, value: -40, to: now)!,
                completedDates: generateCompletedDates(startingFrom: calendar.date(byAdding: .day, value: -40, to: now)!, consistencyPercentage: 75),
            ),
            
            Habit(
                name: "Practice Gratitude",
                descriptionText: "Write down three things I'm grateful for today",
                category: .mindfulness,
                frequency: .daily,
                targetDaysPerWeek: 7,
                reminderTime: calendar.date(bySettingHour: 21, minute: 0, second: 0, of: now)!,
                startDate: calendar.date(byAdding: .day, value: -50, to: now)!,
                completedDates: generateCompletedDates(startingFrom: calendar.date(byAdding: .day, value: -50, to: now)!, consistencyPercentage: 85)
            ),
            
            Habit(
                name: "Learn New Skill",
                descriptionText: "Spend 20 minutes on a new skill or hobby",
                category: .learning,
                frequency: .weekdays,
                targetDaysPerWeek: 5,
                reminderTime: calendar.date(bySettingHour: 19, minute: 0, second: 0, of: now)!,
                startDate: calendar.date(byAdding: .day, value: -35, to: now)!,
                completedDates: generateCompletedDates(startingFrom: calendar.date(byAdding: .day, value: -35, to: now)!, consistencyPercentage: 65)
            )
        ]
        
        // Save to local SwiftData
        for habit in demoHabits {
            modelContext.insert(habit)
        }
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to save demo habits to SwiftData: \(error.localizedDescription)")
            success = false
        }
        
        // Save to Firebase
        let db = FirebaseManager.shared.firestore
        
        for habit in demoHabits {
            dispatchGroup.enter()
            
            let habitRef = db.collection("users").document(userId).collection("habits").document(habit.id)
            let habitData = FirebaseManager.shared.dictionaryFromHabit(habit)
            
            habitRef.setData(habitData) { error in
                if let error = error {
                    print("Error adding demo habit to Firebase: \(error.localizedDescription)")
                    success = false
                }
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            completion(success)
        }
    }
    
    // MARK: - Helper Methods
    
    private static func generateCompletedDates(startingFrom startDate: Date, consistencyPercentage: Int) -> [Date] {
        let calendar = Calendar.current
        let now = Date()
        let dayCount = calendar.dateComponents([.day], from: startDate, to: now).day ?? 0
        
        var completedDates: [Date] = []
        let targetCompletions = Int(Double(dayCount) * (Double(consistencyPercentage) / 100.0))
        
        // Add today if consistency is high enough
        if consistencyPercentage > 70 {
            completedDates.append(calendar.startOfDay(for: now))
        }
        
        // Generate a pattern of completions that creates streaks
        // but also has some gaps to make it realistic
        var currentDate = calendar.startOfDay(for: startDate)
        var consecutiveCompletions = 0
        var consecutiveSkips = 0
        
        while currentDate < now {
            let random = Int.random(in: 1...100)
            let shouldComplete: Bool
            
            // Add some logic to create streaks and realistic patterns
            if consecutiveCompletions >= 5 {
                // After 5 consecutive completions, increase chance of skipping
                shouldComplete = random <= max(consistencyPercentage - 30, 0)
            } else if consecutiveSkips >= 2 {
                // After 2 consecutive skips, increase chance of completing
                shouldComplete = random <= min(consistencyPercentage + 30, 100)
            } else {
                shouldComplete = random <= consistencyPercentage
            }
            
            if shouldComplete && completedDates.count < targetCompletions {
                completedDates.append(currentDate)
                consecutiveCompletions += 1
                consecutiveSkips = 0
            } else {
                consecutiveSkips += 1
                consecutiveCompletions = 0
            }
            
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }
        
        return completedDates
    }
}
