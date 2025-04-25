//
//  FirebaseManager.swift
//  FitnessHabitTracker
//
//  Updated with improved profile image handling
//

import Foundation
import FirebaseCore
import FirebaseFirestore
import FirebaseAuth
import FirebaseAnalytics
import FirebaseStorage

class FirebaseManager {
    static let shared = FirebaseManager()
    
    private init() {}
    
    var firestore: Firestore {
        return Firestore.firestore()
    }
    
    var storage: Storage {
        return Storage.storage()
    }
    
    func setupCloudMessaging() {
        // Cloud Messaging setup would go here
        print("Cloud Messaging setup")
    }
    
    // MARK: - Analytics
    
    func logEvent(name: String, parameters: [String: Any]? = nil) {
        Analytics.logEvent(name, parameters: parameters)
    }
    
    // MARK: - Workout Conversions
    
    func dictionaryFromWorkout(_ workout: Workout) -> [String: Any] {
        var dict: [String: Any] = [
            "id": workout.id,
            "name": workout.name,
            "typeName": workout.typeName,
            "duration": workout.duration,
            "caloriesBurned": workout.caloriesBurned,
            "date": workout.date
        ]
        
        if let notes = workout.notes {
            dict["notes"] = notes
        }
        
        if let distance = workout.distance {
            dict["distance"] = distance
        }
        
        if let intensityName = workout.intensityName {
            dict["intensityName"] = intensityName
        }
        
        if let avgHR = workout.averageHeartRate {
            dict["averageHeartRate"] = avgHR
        }
        
        if let maxHR = workout.maxHeartRate {
            dict["maxHeartRate"] = maxHR
        }
        
        return dict
    }
    
    func workoutFromDictionary(_ data: [String: Any]) -> Workout? {
        guard let id = data["id"] as? String,
              let name = data["name"] as? String,
              let typeName = data["typeName"] as? String,
              let duration = data["duration"] as? TimeInterval,
              let caloriesBurned = data["caloriesBurned"] as? Double else {
            return nil
        }
        
        // Handle date conversion properly
        var date = Date()
        if let timestamp = data["date"] as? Timestamp {
            date = timestamp.dateValue()
        } else if let dateDouble = data["date"] as? Double {
            date = Date(timeIntervalSince1970: dateDouble)
        }
        
        let notes = data["notes"] as? String
        let distance = data["distance"] as? Double
        let intensityName = data["intensityName"] as? String
        let averageHeartRate = data["averageHeartRate"] as? Double
        let maxHeartRate = data["maxHeartRate"] as? Double
        
        // Create and return the workout
        let workout = Workout(
            id: id,
            name: name,
            type: WorkoutType(rawValue: typeName) ?? .other,
            duration: duration,
            caloriesBurned: caloriesBurned,
            date: date,
            notes: notes,
            distance: distance,
            intensity: intensityName != nil ? WorkoutIntensity(rawValue: intensityName!) : nil,
            averageHeartRate: averageHeartRate,
            maxHeartRate: maxHeartRate
        )
        
        return workout
    }
    
    // MARK: - Habit Conversions
    
    func dictionaryFromHabit(_ habit: Habit) -> [String: Any] {
        var dict: [String: Any] = [
            "id": habit.id,
            "name": habit.name,
            "categoryName": habit.categoryName,
            "frequencyName": habit.frequencyName,
            "targetDaysPerWeek": habit.targetDaysPerWeek,
            "startDate": habit.startDate,
            "isArchived": habit.isArchived
        ]
        
        if let desc = habit.descriptionText {
            dict["descriptionText"] = desc
        }
        
        if let reminderTime = habit.reminderTime {
            dict["reminderTime"] = reminderTime
        }
        
        // Convert completed dates array
        let completedDatesTimestamps = habit.completedDates.map { Timestamp(date: $0) }
        dict["completedDates"] = completedDatesTimestamps
        
        return dict
    }
    
    func habitFromDictionary(_ data: [String: Any]) -> Habit? {
        guard let id = data["id"] as? String,
              let name = data["name"] as? String,
              let categoryName = data["categoryName"] as? String,
              let frequencyName = data["frequencyName"] as? String,
              let targetDaysPerWeek = data["targetDaysPerWeek"] as? Int else {
            return nil
        }
        
        // Handle start date
        var startDate = Date()
        if let timestamp = data["startDate"] as? Timestamp {
            startDate = timestamp.dateValue()
        } else if let dateDouble = data["startDate"] as? Double {
            startDate = Date(timeIntervalSince1970: dateDouble)
        }
        
        // Handle reminder time if exists
        var reminderTime: Date? = nil
        if let reminderTimestamp = data["reminderTime"] as? Timestamp {
            reminderTime = reminderTimestamp.dateValue()
        } else if let reminderTimeDouble = data["reminderTime"] as? Double {
            reminderTime = Date(timeIntervalSince1970: reminderTimeDouble)
        }
        
        let descriptionText = data["descriptionText"] as? String
        let isArchived = data["isArchived"] as? Bool ?? false
        
        // Handle completed dates
        var completedDates: [Date] = []
        
        if let timestamps = data["completedDates"] as? [Timestamp] {
            completedDates = timestamps.map { $0.dateValue() }
        } else if let dateArray = data["completedDates"] as? [[String: Any]] {
            // Handle case where dates might be stored differently
            completedDates = dateArray.compactMap { dateDict -> Date? in
                if let seconds = dateDict["seconds"] as? TimeInterval {
                    return Date(timeIntervalSince1970: seconds)
                }
                return nil
            }
        }
        
        // Create and return the habit
        let habit = Habit(
            id: id,
            name: name,
            descriptionText: descriptionText,
            category: HabitCategory(rawValue: categoryName) ?? .other,
            frequency: HabitFrequency(rawValue: frequencyName) ?? .daily,
            targetDaysPerWeek: targetDaysPerWeek,
            reminderTime: reminderTime,
            startDate: startDate,
            completedDates: completedDates,
            isArchived: isArchived
        )
        
        return habit
    }
    
    // MARK: - User Conversions
    
    func dictionaryFromUser(_ user: User) -> [String: Any] {
        var dict: [String: Any] = [
            "id": user.id,
            "name": user.name,
            "email": user.email,
            "passwordHash": user.passwordHash,
            "joinDate": user.joinDate
        ]
        
        // Explicitly add profile image URL even if nil
        dict["profileImageURL"] = user.profileImageURL
        print("Including profileImageURL in user data: \(user.profileImageURL ?? "nil")")
        
        // Explicitly add other fields, even if nil
        dict["weight"] = user.weight
        dict["height"] = user.height
        dict["fitnessGoal"] = user.fitnessGoal
        
        print("Final user dictionary for Firebase: \(dict)")
        return dict
    }
    
    func userFromDictionary(_ data: [String: Any]) -> User? {
        guard let id = data["id"] as? String,
              let name = data["name"] as? String,
              let email = data["email"] as? String,
              let passwordHash = data["passwordHash"] as? String else {
            return nil
        }
        
        // Handle join date
        var joinDate = Date()
        if let timestamp = data["joinDate"] as? Timestamp {
            joinDate = timestamp.dateValue()
        } else if let dateDouble = data["joinDate"] as? Double {
            joinDate = Date(timeIntervalSince1970: dateDouble)
        }
        
        let profileImageURL = data["profileImageURL"] as? String
        let weight = data["weight"] as? Double
        let height = data["height"] as? Double
        let fitnessGoal = data["fitnessGoal"] as? String
        
        // Create and return the user
        let user = User(
            id: id,
            name: name,
            email: email,
            passwordHash: passwordHash,
            profileImageURL: profileImageURL,
            weight: weight,
            height: height,
            fitnessGoal: fitnessGoal,
            joinDate: joinDate
        )
        
        return user
    }
    
    // MARK: - Goal Conversions
    
    func dictionaryFromGoal(_ goal: Goal) -> [String: Any] {
        var dict: [String: Any] = [
            "id": goal.id,
            "userId": goal.userId,
            "title": goal.title,
            "typeString": goal.typeString,
            "targetValue": goal.targetValue,
            "currentValue": goal.currentValue,
            "startDate": goal.startDate,
            "endDate": goal.endDate,
            "timeframeString": goal.timeframeString,
            "statusString": goal.statusString,
            "lastUpdated": goal.lastUpdated
        ]
        
        if let notes = goal.notes {
            dict["notes"] = notes
        }
        
        if let linkedWorkoutType = goal.linkedWorkoutType {
            dict["linkedWorkoutType"] = linkedWorkoutType
        }
        
        if let linkedHabitId = goal.linkedHabitId {
            dict["linkedHabitId"] = linkedHabitId
        }
        
        return dict
    }
    
    func goalFromDictionary(_ data: [String: Any]) -> Goal? {
        guard let id = data["id"] as? String,
              let userId = data["userId"] as? String,
              let title = data["title"] as? String,
              let typeString = data["typeString"] as? String,
              let targetValue = data["targetValue"] as? Double,
              let currentValue = data["currentValue"] as? Double,
              let timeframeString = data["timeframeString"] as? String,
              let statusString = data["statusString"] as? String else {
            return nil
        }
        
        // Handle dates
        var startDate = Date()
        if let timestamp = data["startDate"] as? Timestamp {
            startDate = timestamp.dateValue()
        } else if let dateDouble = data["startDate"] as? Double {
            startDate = Date(timeIntervalSince1970: dateDouble)
        }
        
        var endDate = Date(timeIntervalSinceNow: 86400 * 7) // Default to 7 days from now
        if let timestamp = data["endDate"] as? Timestamp {
            endDate = timestamp.dateValue()
        } else if let dateDouble = data["endDate"] as? Double {
            endDate = Date(timeIntervalSince1970: dateDouble)
        }
        
        var lastUpdated = Date()
        if let timestamp = data["lastUpdated"] as? Timestamp {
            lastUpdated = timestamp.dateValue()
        } else if let dateDouble = data["lastUpdated"] as? Double {
            lastUpdated = Date(timeIntervalSince1970: dateDouble)
        }
        
        // Optional fields
        let notes = data["notes"] as? String
        let linkedWorkoutType = data["linkedWorkoutType"] as? String
        let linkedHabitId = data["linkedHabitId"] as? String
        
        // Create the goal
        let goal = Goal(
            id: id,
            userId: userId,
            title: title,
            type: GoalType(rawValue: typeString) ?? .workout,
            targetValue: targetValue,
            currentValue: currentValue,
            startDate: startDate,
            endDate: endDate,
            timeframe: GoalTimeframe(rawValue: timeframeString) ?? .weekly,
            status: GoalStatus(rawValue: statusString) ?? .active,
            notes: notes,
            linkedWorkoutType: linkedWorkoutType,
            linkedHabitId: linkedHabitId
        )
        
        // Set the lastUpdated field
        goal.lastUpdated = lastUpdated
        
        return goal
    }
    
    
    // MARK: - Additional Goal Helpers
    
    // Check if a goal exists in Firestore
    func checkGoalExists(goalId: String, userId: String, completion: @escaping (Bool) -> Void) {
        let goalRef = firestore.collection("users").document(userId).collection("goals").document(goalId)
        
        goalRef.getDocument { document, error in
            if let error = error {
                print("Error checking if goal exists: \(error.localizedDescription)")
                completion(false)
                return
            }
            
            completion(document?.exists ?? false)
        }
    }
    
    // Batch add multiple goals (for suggested goals)
    func batchAddGoals(_ goals: [Goal], userId: String, completion: @escaping (Bool) -> Void) {
        let batch = firestore.batch()
        
        for goal in goals {
            let goalRef = firestore.collection("users").document(userId).collection("goals").document(goal.id)
            let goalData = dictionaryFromGoal(goal)
            batch.setData(goalData, forDocument: goalRef)
        }
        
        batch.commit { error in
            if let error = error {
                print("Error batch adding goals: \(error.localizedDescription)")
                completion(false)
            } else {
                completion(true)
            }
        }
    }
    
    // Get goal progress summary
    func getGoalSummary(userId: String, completion: @escaping ([String: Any]?, Error?) -> Void) {
        let goalsRef = firestore.collection("users").document(userId).collection("goals")
        
        goalsRef.getDocuments { snapshot, error in
            if let error = error {
                completion(nil, error)
                return
            }
            
            guard let documents = snapshot?.documents else {
                completion([:], nil)
                return
            }
            
            var totalGoals = 0
            var completedGoals = 0
            var activeGoals = 0
            var failedGoals = 0
            
            for document in documents {
                totalGoals += 1
                
                if let status = document.data()["statusString"] as? String {
                    switch status {
                    case "completed": completedGoals += 1
                    case "active": activeGoals += 1
                    case "failed": failedGoals += 1
                    default: break
                    }
                }
            }
            
            let summary: [String: Any] = [
                "totalGoals": totalGoals,
                "completedGoals": completedGoals,
                "activeGoals": activeGoals,
                "failedGoals": failedGoals,
                "completionRate": totalGoals > 0 ? Double(completedGoals) / Double(totalGoals) : 0.0
            ]
            
            completion(summary, nil)
        }
    }
}
