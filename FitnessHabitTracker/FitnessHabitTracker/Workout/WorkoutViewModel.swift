//
//  WorkoutViewModel.swift
//  FitnessHabitTracker
//
//  Created by Nikhil Av on 4/16/25.
//  Updated with SwiftData implementation, Goal integration, and CoreML

import SwiftUI
import Combine
import SwiftData
import FirebaseFirestore
import FirebaseAuth

class WorkoutViewModel: ObservableObject {
    @Published var workouts: [Workout] = []
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var showingError = false
    
    // CoreML status
    @Published var mlModelsAvailable = false
    @Published var isTrainingModels = false
    
    // Workout suggestions
    @Published var workoutSuggestions: [WorkoutSuggestion] = []
    
    private var modelContext: ModelContext?
    private var firestoreListener: ListenerRegistration?
    private var userId: String?
    
    // Added reference to GoalViewModel for updating goals
    private weak var goalViewModel: GoalViewModel?
    
    var recentWorkouts: [Workout] {
        Array(workouts.sorted(by: { $0.date > $1.date }).prefix(5))
    }
    
    init(modelContext: ModelContext? = nil, goalViewModel: GoalViewModel? = nil) {
        self.modelContext = modelContext
        self.goalViewModel = goalViewModel
        
        // Check ML models status
        checkMLModelsStatus()
        
        // Listen for authentication changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(userDidChange),
            name: NSNotification.Name("UserDidChangeNotification"),
            object: nil
        )
        
        // Add observer for imported workouts
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleImportedWorkouts),
            name: NSNotification.Name("ImportWorkoutsNotification"),
            object: nil
        )
        
        // Add observer for imported workouts from CSV
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleImportedWorkoutsFromCSV),
            name: NSNotification.Name("ImportWorkoutsFromCSVNotification"),
            object: nil
        )
        
        // ML models update notification
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMLModelsUpdated),
            name: NSNotification.Name("MLModelsUpdated"),
            object: nil
        )
        
        // If a user is already authenticated, load workouts
        if let currentUser = Auth.auth().currentUser {
            self.userId = currentUser.uid
            loadWorkouts()
        }
    }
    
    deinit {
        firestoreListener?.remove()
        NotificationCenter.default.removeObserver(self)
    }
    
    // Set the GoalViewModel reference
    func setGoalViewModel(_ viewModel: GoalViewModel) {
        self.goalViewModel = viewModel
        print("GoalViewModel reference set in WorkoutViewModel")
    }
    
    @objc func userDidChange(_ notification: Notification) {
        if let userId = notification.userInfo?["userId"] as? String {
            self.userId = userId
            loadWorkouts()
        } else {
            // User logged out
            self.userId = nil
            self.workouts = []
            firestoreListener?.remove()
        }
    }
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        if let firebaseUser = Auth.auth().currentUser {
            self.userId = firebaseUser.uid
            loadWorkouts()
        }
    }
    
    // MARK: - Import Handling
    
    @objc func handleImportedWorkouts(_ notification: Notification) {
        guard let workoutsData = notification.userInfo?["workouts"] as? [[String: Any]] else {
            print("No workout data found in notification")
            return
        }
        
        print("Received \(workoutsData.count) workouts to import")
        
        // Convert dates from strings to Date objects
        let dateFormatter = ISO8601DateFormatter()
        
        for var workoutData in workoutsData {
            // Convert date strings to Date objects
            if let dateString = workoutData["date"] as? String {
                workoutData["date"] = dateFormatter.date(from: dateString) ?? Date()
            }
            
            // Create workout from dictionary
            if let workout = processWorkoutFromDictionary(workoutData) {
                print("Processing workout: \(workout.name)")
                // Add to database (this will update the UI)
                DispatchQueue.main.async {
                    self.addWorkout(workout)
                }
            }
        }
        
        // Force UI refresh
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }
    
    @objc func handleImportedWorkoutsFromCSV(_ notification: Notification) {
        guard let csvData = notification.userInfo?["csvData"] as? [String] else {
            print("No CSV workout data found in notification")
            return
        }
        
        print("Received \(csvData.count) lines of CSV workout data to import")
        
        // First line should be headers
        guard csvData.count > 1 else { return }
        
        let headers = csvData[0].components(separatedBy: ",")
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        // Process each data row
        for i in 1..<csvData.count {
            let line = csvData[i]
            let components = parseCSVLine(line)
            
            guard components.count >= 6 else { continue }
            
            // Map CSV components to workout properties using headers
            var workoutData: [String: Any] = [:]
            
            for (index, header) in headers.enumerated() {
                if index < components.count {
                    let key = header.trimmingCharacters(in: .whitespacesAndNewlines)
                    let value = components[index].trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    // Remove quotes if present
                    let cleanValue = value.replacingOccurrences(of: "\"", with: "")
                    
                    // Parse values correctly based on type
                    if key == "id" || key == "name" || key == "type" || key == "notes" || key == "intensity" {
                        workoutData[key] = cleanValue
                    } else if key == "duration" || key == "calories" {
                        workoutData[key] = Double(cleanValue) ?? 0.0
                    } else if key == "date" {
                        workoutData[key] = dateFormatter.date(from: cleanValue) ?? Date()
                    } else if key == "distance" && !cleanValue.isEmpty {
                        workoutData[key] = Double(cleanValue)
                    } else if (key == "avgHeartRate" || key == "maxHeartRate") && !cleanValue.isEmpty {
                        workoutData[key] = Double(cleanValue)
                    }
                }
            }
            
            // Create workout from processed data
            if let workout = processWorkoutFromCSV(workoutData) {
                print("Processed workout from CSV: \(workout.name)")
                // Add to database
                DispatchQueue.main.async {
                    self.addWorkout(workout)
                }
            }
        }
        
        // Force UI refresh
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }
    
    private func parseCSVLine(_ line: String) -> [String] {
        var result: [String] = []
        var currentValue = ""
        var inQuotes = false
        
        for char in line {
            if char == "\"" {
                inQuotes = !inQuotes
            } else if char == "," && !inQuotes {
                result.append(currentValue)
                currentValue = ""
            } else {
                currentValue.append(char)
            }
        }
        
        // Add the last value
        result.append(currentValue)
        
        return result
    }
    
    private func processWorkoutFromDictionary(_ data: [String: Any]) -> Workout? {
        // Required fields
        guard let id = data["id"] as? String,
              let name = data["name"] as? String,
              let typeNameValue = data["typeName"] as? String else {
            print("Missing required fields for workout")
            return nil
        }
        
        // Get workout type
        let type = WorkoutType(rawValue: typeNameValue) ?? .other
        
        // Get duration - default to 0 if missing
        let duration = (data["duration"] as? Double) ?? 0
        
        // Get calories - default to 0 if missing
        let calories = (data["caloriesBurned"] as? Double) ?? 0
        
        // Get date - default to now if missing
        let date = (data["date"] as? Date) ?? Date()
        
        // Get optional fields
        let notes = data["notes"] as? String
        let distance = data["distance"] as? Double
        
        // Get intensity if available
        var intensity: WorkoutIntensity? = nil
        if let intensityName = data["intensityName"] as? String {
            intensity = WorkoutIntensity(rawValue: intensityName)
        }
        
        // Get heart rate data if available
        let avgHeartRate = data["averageHeartRate"] as? Double
        let maxHeartRate = data["maxHeartRate"] as? Double
        
        // Create and return workout
        return Workout(
            id: id,
            name: name,
            type: type,
            duration: duration,
            caloriesBurned: calories,
            date: date,
            notes: notes,
            distance: distance,
            intensity: intensity,
            averageHeartRate: avgHeartRate,
            maxHeartRate: maxHeartRate
        )
    }
    
    private func processWorkoutFromCSV(_ data: [String: Any]) -> Workout? {
        // Required fields
        guard let id = data["id"] as? String,
              let name = data["name"] as? String,
              let typeStr = data["type"] as? String else {
            print("Missing required fields for workout")
            return nil
        }
        
        // Parse fields
        let type = WorkoutType(rawValue: typeStr) ?? .other
        let duration = (data["duration"] as? Double) ?? 0
        let calories = (data["calories"] as? Double) ?? 0
        let date = (data["date"] as? Date) ?? Date()
        let notes = data["notes"] as? String
        let distance = data["distance"] as? Double
        
        // Parse intensity
        var intensity: WorkoutIntensity? = nil
        if let intensityStr = data["intensity"] as? String, !intensityStr.isEmpty {
            intensity = WorkoutIntensity(rawValue: intensityStr)
        }
        
        // Parse heart rate data
        let avgHeartRate = data["avgHeartRate"] as? Double
        let maxHeartRate = data["maxHeartRate"] as? Double
        
        // Create and return workout
        return Workout(
            id: id,
            name: name,
            type: type,
            duration: duration,
            caloriesBurned: calories,
            date: date,
            notes: notes,
            distance: distance,
            intensity: intensity,
            averageHeartRate: avgHeartRate,
            maxHeartRate: maxHeartRate
        )
    }
    
    // MARK: - Standard Data Operations
    
    func loadWorkouts() {
        guard let userId = userId else {
            // No authenticated user
            self.workouts = []
            return
        }
        
        isLoading = true
        
        // First, try to load from local SwiftData store
        if let modelContext = modelContext {
            do {
                let descriptor = FetchDescriptor<Workout>()
                let localWorkouts = try modelContext.fetch(descriptor)
                
                if !localWorkouts.isEmpty {
                    print("Found \(localWorkouts.count) workouts in local storage")
                    self.workouts = localWorkouts.sorted(by: { $0.date > $1.date })
                }
            } catch {
                print("Error fetching local workouts: \(error.localizedDescription)")
            }
        }
        
        // Remove any existing listener
        firestoreListener?.remove()
        
        // Set up real-time listener for user's workouts
        let db = FirebaseManager.shared.firestore
        let workoutsRef = db.collection("users").document(userId).collection("workouts")
            .order(by: "date", descending: true)
        
        firestoreListener = workoutsRef.addSnapshotListener { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = "Failed to load workouts: \(error.localizedDescription)"
                    self.showingError = true
                }
                return
            }
            
            guard let documents = snapshot?.documents else {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.workouts = []
                }
                return
            }
            
            // Parse Firestore documents into Workout objects
            let firestoreWorkouts = documents.compactMap { document -> Workout? in
                // Fix: data() returns a non-optional, so no need for if let
                let data = document.data()
                return FirebaseManager.shared.workoutFromDictionary(data)
            }
            
            // Convert to local Workout models and save to SwiftData
            DispatchQueue.main.async {
                self.syncWorkoutsWithLocal(firestoreWorkouts)
                self.isLoading = false
                
                // After successfully loading workouts, update ML-based features
                if !self.workouts.isEmpty {
                    self.checkMLModelsStatus()
                    
                    // Generate workout suggestions
                    if self.mlModelsAvailable {
                        self.workoutSuggestions = self.getPersonalizedWorkoutSuggestions()
                    } else {
                        // Use default suggestions if ML not available
                        self.workoutSuggestions = self.getDefaultSuggestions()
                    }
                }
            }
        }
    }
    
    private func syncWorkoutsWithLocal(_ firestoreWorkouts: [Workout]) {
        guard let modelContext = modelContext else {
            self.workouts = firestoreWorkouts
            return
        }
        
        // Get existing workouts from SwiftData
        do {
            let descriptor = FetchDescriptor<Workout>()
            let existingWorkouts = try modelContext.fetch(descriptor)
            
            // Prepare ID sets for quick lookups
            let existingIds = Set(existingWorkouts.map { $0.id })
            let firestoreIds = Set(firestoreWorkouts.map { $0.id })
            
            // Add new workouts
            for firestoreWorkout in firestoreWorkouts {
                if !existingIds.contains(firestoreWorkout.id) {
                    modelContext.insert(firestoreWorkout)
                }
            }
            
            // Remove deleted workouts
            for workout in existingWorkouts {
                if !firestoreIds.contains(workout.id) {
                    modelContext.delete(workout)
                }
            }
            
            // Update existing workouts
            for firestoreWorkout in firestoreWorkouts {
                if let existingWorkout = existingWorkouts.first(where: { $0.id == firestoreWorkout.id }) {
                    // Update properties
                    existingWorkout.name = firestoreWorkout.name
                    existingWorkout.typeName = firestoreWorkout.typeName
                    existingWorkout.duration = firestoreWorkout.duration
                    existingWorkout.caloriesBurned = firestoreWorkout.caloriesBurned
                    existingWorkout.date = firestoreWorkout.date
                    existingWorkout.notes = firestoreWorkout.notes
                    existingWorkout.distance = firestoreWorkout.distance
                    existingWorkout.intensityName = firestoreWorkout.intensityName
                    existingWorkout.averageHeartRate = firestoreWorkout.averageHeartRate
                    existingWorkout.maxHeartRate = firestoreWorkout.maxHeartRate
                }
            }
            
            // Make sure to save changes to persistent storage
            try modelContext.save()
            print("Successfully saved workouts to local storage")
            
            // Update published property with latest data
            let updatedDescriptor = FetchDescriptor<Workout>(sortBy: [SortDescriptor(\.date, order: .reverse)])
            self.workouts = try modelContext.fetch(updatedDescriptor)
        } catch {
            self.errorMessage = "Failed to sync workouts: \(error.localizedDescription)"
            self.showingError = true
            
            // Fallback to memory-only if local storage fails
            self.workouts = firestoreWorkouts
        }
    }
    
    func addWorkout(_ workout: Workout) {
        guard let userId = userId else {
            errorMessage = "User not authenticated"
            showingError = true
            return
        }
        
        print("Adding workout: \(workout.name)")
        
        // Add to local storage
        if let modelContext = modelContext {
            modelContext.insert(workout)
            do {
                try modelContext.save()
                
                // Update the workouts array
                if let index = self.workouts.firstIndex(where: { $0.date < workout.date }) {
                    self.workouts.insert(workout, at: index)
                } else {
                    self.workouts.append(workout)
                }
                
                // Force UI update
                self.objectWillChange.send()
                
                // Update goals when workout is added
                if let goalViewModel = self.goalViewModel {
                    goalViewModel.updateGoalsForWorkout(workout)
                    
                    // Track specific workout types that might be linked to goals
                    FirebaseManager.shared.logEvent(name: "workout_goal_progress", parameters: [
                        "workout_type": workout.typeName,
                        "duration": workout.duration,
                        "distance": workout.distance ?? 0
                    ])
                } else {
                    print("WARNING: GoalViewModel reference is nil, goals will not be updated")
                }
                
                // Check if we should suggest creating a goal
                showGoalCreationPrompt(for: workout)
                
                // If ML models are available, check if we should update suggestions
                if mlModelsAvailable {
                    // Update workout suggestions
                    workoutSuggestions = getPersonalizedWorkoutSuggestions()
                }
                
            } catch {
                errorMessage = "Failed to save workout locally: \(error.localizedDescription)"
                showingError = true
            }
        } else {
            print("WARNING: modelContext is nil, workout will only be saved to Firestore")
        }
        
        // Save to Firestore
        let db = FirebaseManager.shared.firestore
        let workoutRef = db.collection("users").document(userId).collection("workouts").document(workout.id)
        
        // Convert Workout to Dictionary
        let workoutData = FirebaseManager.shared.dictionaryFromWorkout(workout)
        
        // Save to Firestore
        workoutRef.setData(workoutData) { [weak self] error in
            if let error = error {
                DispatchQueue.main.async {
                    self?.errorMessage = "Failed to save workout to cloud: \(error.localizedDescription)"
                    self?.showingError = true
                }
            } else {
                // Log analytics event
                FirebaseManager.shared.logEvent(name: "workout_added", parameters: ["workout_id": workout.id])
            }
        }
    }
    
    func updateWorkout(_ workout: Workout) {
        guard let userId = userId else {
            errorMessage = "User not authenticated"
            showingError = true
            return
        }
        
        // Update in local storage
        if let modelContext = modelContext {
            do {
                try modelContext.save()
                
                // Update local array to reflect changes
                if let index = workouts.firstIndex(where: { $0.id == workout.id }) {
                    workouts[index] = workout
                }
                
                // Force UI update
                self.objectWillChange.send()
                
                if let goalViewModel = goalViewModel {
                    // Update goals when workout is updated
                    goalViewModel.updateGoalsForWorkout(workout)
                } else {
                    print("WARNING: GoalViewModel reference is nil, goals will not be updated")
                }
                
            } catch {
                errorMessage = "Failed to update workout locally: \(error.localizedDescription)"
                showingError = true
            }
        }
        
        // Update in Firestore
        let db = FirebaseManager.shared.firestore
        let workoutRef = db.collection("users").document(userId).collection("workouts").document(workout.id)
        
        // Convert Workout to Dictionary
        let workoutData = FirebaseManager.shared.dictionaryFromWorkout(workout)
        
        // Update in Firestore
        workoutRef.setData(workoutData) { [weak self] error in
            if let error = error {
                DispatchQueue.main.async {
                    self?.errorMessage = "Failed to update workout in cloud: \(error.localizedDescription)"
                    self?.showingError = true
                }
            } else {
                // Log analytics event
                FirebaseManager.shared.logEvent(name: "workout_updated", parameters: ["workout_id": workout.id])
            }
        }
    }
    
    func deleteWorkout(_ workout: Workout) {
        guard let userId = userId else {
            errorMessage = "User not authenticated"
            showingError = true
            return
        }
        
        // Delete from local storage
        if let modelContext = modelContext {
            modelContext.delete(workout)
            do {
                try modelContext.save()
                workouts.removeAll(where: { $0.id == workout.id })
                
                // Force UI update
                self.objectWillChange.send()
            } catch {
                errorMessage = "Failed to delete workout locally: \(error.localizedDescription)"
                showingError = true
            }
        }
        
        // Delete from Firestore
        let db = FirebaseManager.shared.firestore
        let workoutRef = db.collection("users").document(userId).collection("workouts").document(workout.id)
        
        workoutRef.delete { [weak self] error in
            if let error = error {
                DispatchQueue.main.async {
                    self?.errorMessage = "Failed to delete workout from cloud: \(error.localizedDescription)"
                    self?.showingError = true
                }
            } else {
                // Log analytics event
                FirebaseManager.shared.logEvent(name: "workout_deleted", parameters: ["workout_id": workout.id])
            }
        }
    }
    
    // MARK: - Goal Suggestion Methods
    
    private func showGoalCreationPrompt(for workout: Workout) {
        guard let goalViewModel = self.goalViewModel else { return }
        
        // Check if user already has active goals for this workout type
        let hasExistingGoal = goalViewModel.activeGoals.contains { goal in
            if let linkedType = goal.linkedWorkoutType {
                return linkedType == workout.typeName
            }
            return false
        }
        
        // Only suggest goals if there are no existing ones for this workout type
        if !hasExistingGoal {
            // Create a notification to show goal suggestion UI
            NotificationCenter.default.post(
                name: NSNotification.Name("SuggestWorkoutGoal"),
                object: nil,
                userInfo: ["workout": workout]
            )
        }
    }
    
    func hasExistingWorkoutGoal() -> Bool {
        guard let goalViewModel = goalViewModel else { return false }
        return goalViewModel.activeGoals.contains {
            $0.type == .workout || $0.type == .distance || $0.type == .duration
        }
    }
    
    func createSuggestedGoalsForWorkout(_ workout: Workout) -> [Goal] {
        guard let userId = userId else { return [] }
        
        var suggestedGoals: [Goal] = []
        let workoutType = workout.type
        
        // Create workout count goal
        let countGoal = Goal(
            userId: userId,
            title: "Complete 3 \(workoutType.rawValue) workouts",
            type: .workout,
            targetValue: 3,
            timeframe: .weekly,
            linkedWorkoutType: workoutType.rawValue
        )
        suggestedGoals.append(countGoal)
        
        // If distance-based workout, add distance goal
        if let distance = workout.distance, distance > 0 {
            let distanceGoal = Goal(
                userId: userId,
                title: "Cover \(Int(distance * 3)) km with \(workoutType.rawValue)",
                type: .distance,
                targetValue: distance * 3,
                timeframe: .weekly,
                linkedWorkoutType: workoutType.rawValue
            )
            suggestedGoals.append(distanceGoal)
        }
        
        // Add duration goal
        let durationInMinutes = workout.duration / 60
        let durationGoal = Goal(
            userId: userId,
            title: "Exercise for \(Int(durationInMinutes * 3)) minutes",
            type: .duration,
            targetValue: durationInMinutes * 3,
            timeframe: .weekly,
            linkedWorkoutType: workoutType.rawValue
        )
        suggestedGoals.append(durationGoal)
        
        return suggestedGoals
    }
    
    // MARK: - ML-Related Methods
    
    @objc private func handleMLModelsUpdated() {
        // Refresh ML-based features
        DispatchQueue.main.async {
            self.workoutSuggestions = self.getPersonalizedWorkoutSuggestions()
        }
    }
    
    // MARK: - ML Training & Management
    
    /// Train machine learning models with available workout data
    func trainMLModels(completion: @escaping (Bool) -> Void = { _ in }) {
        guard let userId = userId, !workouts.isEmpty else {
            print("Cannot train ML models: No workouts or user ID available")
            completion(false)
            return
        }
        
        print("Training ML models with \(workouts.count) workouts...")
        
        // Show training indicator if visible to user
        isLoading = true
        isTrainingModels = true
        
        WorkoutMLModel.shared.trainModels(with: workouts, userId: userId) { success in
            self.isLoading = false
            self.isTrainingModels = false
            
            if success {
                print("Successfully trained ML models")
                // Update UI state to reflect ML capabilities
                self.mlModelsAvailable = true
                NotificationCenter.default.post(name: NSNotification.Name("MLModelsUpdated"), object: nil)
            } else {
                print("Failed to train ML models")
                self.errorMessage = "Could not train workout prediction models. Please try again later."
                self.showingError = true
            }
            
            completion(success)
        }
    }
    
    /// Check if ML models exist and are usable
    func checkMLModelsStatus() {
        mlModelsAvailable = WorkoutMLModel.shared.modelsExist()
        
        // If models don't exist but we have enough data, train them automatically
        if !mlModelsAvailable && workouts.count >= 15 {
            DispatchQueue.global(qos: .background).async {
                self.trainMLModels()
            }
        }
    }
    
    // MARK: - Predictive Features
    
    /// Predict calories for a workout with given parameters
    func predictCalories(for workoutType: WorkoutType,
                         duration: TimeInterval,
                         intensity: WorkoutIntensity,
                         distance: Double? = nil) -> Double? {
        
        // Use the workout ML model to predict calories
        let prediction = WorkoutMLModel.shared.predictCalories(
            for: workoutType,
            duration: duration,
            intensity: intensity,
            distance: distance
        )
        
        // Log the prediction for analytics
        if let predictedCalories = prediction {
            FirebaseManager.shared.logEvent(name: "ml_calorie_prediction", parameters: [
                "workout_type": workoutType.rawValue,
                "predicted_calories": predictedCalories
            ])
        }
        
        return prediction
    }
    
    /// Get a workout recommendation for the current time
    func getWorkoutRecommendation() -> WorkoutRecommendation? {
        // First, check if models are available
        guard mlModelsAvailable else { return nil }
        
        // Get recommended workout type
        guard let recommendedType = WorkoutMLModel.shared.recommendWorkout() else { return nil }
        
        // Find optimal duration based on user history for this type
        let typicalDuration = getTypicalDuration(for: recommendedType)
        
        // Create a workout recommendation
        let recommendation = WorkoutRecommendation(
            workoutType: recommendedType,
            suggestedDuration: typicalDuration,
            suggestedIntensity: .moderate,
            confidence: 0.85 // Could be dynamic based on model confidence
        )
        
        // Log the recommendation for analytics
        FirebaseManager.shared.logEvent(name: "ml_workout_recommendation", parameters: [
            "workout_type": recommendedType.rawValue,
            "suggested_duration": typicalDuration
        ])
        
        return recommendation
    }
    
    /// Get personalized workout suggestions based on user patterns
    func getPersonalizedWorkoutSuggestions() -> [WorkoutSuggestion] {
        // Need models and sufficient data
        guard mlModelsAvailable, workouts.count >= 10 else { return getDefaultSuggestions() }
        
        var suggestions: [WorkoutSuggestion] = []
        
        // Get the current day of week and time
        let calendar = Calendar.current
        let today = Date()
        let dayOfWeek = calendar.component(.weekday, from: today)
        
        // Filter workouts to find patterns for this day of week
        let workoutsOnSameDay = workouts.filter {
            calendar.component(.weekday, from: $0.date) == dayOfWeek
        }
        
        // No history for this day? Use ML recommendation
        if workoutsOnSameDay.isEmpty {
            if let recommendedType = WorkoutMLModel.shared.recommendWorkout() {
                let typicalDuration = getTypicalDuration(for: recommendedType)
                
                suggestions.append(WorkoutSuggestion(
                    title: "Recommended for Today",
                    description: "Based on your workout patterns",
                    workoutType: recommendedType,
                    suggestedDuration: typicalDuration,
                    confidence: 0.8
                ))
            }
        } else {
            // Find most common workout type for this day
            let typeFrequency = Dictionary(grouping: workoutsOnSameDay) { $0.type }
                .mapValues { $0.count }
                .sorted { $0.value > $1.value }
            
            if let mostCommonType = typeFrequency.first?.key {
                let sameTypeWorkouts = workoutsOnSameDay.filter { $0.type == mostCommonType }
                let avgDuration = sameTypeWorkouts.reduce(0) { $0 + $1.duration } / Double(sameTypeWorkouts.count)
                
                suggestions.append(WorkoutSuggestion(
                    title: "Your Usual \(calendar.weekdaySymbols[dayOfWeek-1]) Workout",
                    description: "Based on your history",
                    workoutType: mostCommonType,
                    suggestedDuration: avgDuration,
                    confidence: 0.9
                ))
            }
        }
        
        // Add a recommendation for improving streak/consistency
        if let lastWorkout = workouts.sorted(by: { $0.date > $1.date }).first {
            let daysSinceLastWorkout = calendar.dateComponents([.day], from: lastWorkout.date, to: today).day ?? 0
            
            if daysSinceLastWorkout >= 2 {
                // Recommend a workout to maintain streak
                if let recommendedType = WorkoutMLModel.shared.recommendWorkout() {
                    suggestions.append(WorkoutSuggestion(
                        title: "Get Back on Track",
                        description: "It's been \(daysSinceLastWorkout) days since your last workout",
                        workoutType: recommendedType,
                        suggestedDuration: getTypicalDuration(for: recommendedType),
                        confidence: 0.75
                    ))
                }
            }
        }
        
        // If we have less than 2 suggestions, add default ones
        if suggestions.count < 2 {
            suggestions.append(contentsOf: getDefaultSuggestions())
        }
        
        // Return unique suggestions (up to 3)
        return Array(Set(suggestions)).prefix(3).map { $0 }
    }
    
    // MARK: - Helper Methods for ML
    
    /// Get typical duration for a workout type based on user history
    private func getTypicalDuration(for workoutType: WorkoutType) -> TimeInterval {
        // Filter workouts by type
        let sameTypeWorkouts = workouts.filter { $0.type == workoutType }
        
        if sameTypeWorkouts.isEmpty {
            // Default durations if no history
            switch workoutType {
            case .running, .cycling:
                return 30 * 60 // 30 minutes
            case .hiit:
                return 20 * 60 // 20 minutes
            case .yoga, .walking:
                return 45 * 60 // 45 minutes
            case .weightTraining:
                return 40 * 60 // 40 minutes
            case .swimming:
                return 30 * 60 // 30 minutes
            default:
                return 30 * 60 // 30 minutes for others
            }
        }
        
        // Calculate average duration
        let totalDuration = sameTypeWorkouts.reduce(0) { $0 + $1.duration }
        return totalDuration / Double(sameTypeWorkouts.count)
    }
    
    /// Get default workout suggestions if ML is not available
    private func getDefaultSuggestions() -> [WorkoutSuggestion] {
        return [
            WorkoutSuggestion(
                title: "Quick Cardio",
                description: "Great for busy days",
                workoutType: .hiit,
                suggestedDuration: 20 * 60,
                confidence: 0.7
            ),
            WorkoutSuggestion(
                title: "Strength Building",
                description: "Focus on muscle groups",
                workoutType: .weightTraining,
                suggestedDuration: 45 * 60,
                confidence: 0.7
            ),
            WorkoutSuggestion(
                title: "Endurance Run",
                description: "Improve your stamina",
                workoutType: .running,
                suggestedDuration: 30 * 60,
                confidence: 0.7
            )
        ]
    }
}

// MARK: - Data Structures for ML Features

/// Workout recommendation model
struct WorkoutRecommendation {
    let workoutType: WorkoutType
    let suggestedDuration: TimeInterval
    let suggestedIntensity: WorkoutIntensity
    let confidence: Double // 0.0 to 1.0
    
    /// Convert to a new workout
    func toWorkout(withName name: String) -> Workout {
        // Predict calories
        let calories = WorkoutMLModel.shared.predictCalories(
            for: workoutType,
            duration: suggestedDuration,
            intensity: suggestedIntensity
        ) ?? Workout.estimateCalories(
            type: workoutType,
            duration: suggestedDuration,
            intensity: suggestedIntensity,
            userWeight: nil
        )
        
        return Workout(
            id: UUID().uuidString,
            name: name,
            type: workoutType,
            duration: suggestedDuration,
            caloriesBurned: calories,
            date: Date(),
            intensity: suggestedIntensity
        )
    }
}

/// Workout suggestion model
struct WorkoutSuggestion: Hashable {
    let id = UUID()
    let title: String
    let description: String
    let workoutType: WorkoutType
    let suggestedDuration: TimeInterval
    let confidence: Double
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: WorkoutSuggestion, rhs: WorkoutSuggestion) -> Bool {
        return lhs.id == rhs.id
    }
    
    /// Create a workout from this suggestion
    func createWorkout(withName name: String = "") -> Workout {
        let workoutName = name.isEmpty ? "\(title)" : name
        
        // Predict calories or use estimation
        let calories = WorkoutMLModel.shared.predictCalories(
            for: workoutType,
            duration: suggestedDuration,
            intensity: .moderate
        ) ?? Workout.estimateCalories(
            type: workoutType,
            duration: suggestedDuration,
            intensity: .moderate,
            userWeight: nil
        )
        
        return Workout(
            id: UUID().uuidString,
            name: workoutName,
            type: workoutType,
            duration: suggestedDuration,
            caloriesBurned: calories,
            date: Date()
        )
    }
}
