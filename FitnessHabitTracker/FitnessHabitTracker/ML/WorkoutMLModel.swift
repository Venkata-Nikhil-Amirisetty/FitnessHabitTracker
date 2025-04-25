//
//  WorkoutMLModel.swift
//  FitnessHabitTracker
//
//  Created for CoreML integration
//

import Foundation
import CoreML

class WorkoutMLModel {
    static let shared = WorkoutMLModel()
    
    private init() {}
    
    // MARK: - Model Paths
    
    // Get the URL for model storage
    private var modelContainerURL: URL {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentsURL.appendingPathComponent("MLModels", isDirectory: true)
    }
    
    private var calorieModelURL: URL {
        // First check if there's a user-trained model
        let userModelURL = modelContainerURL.appendingPathComponent("WorkoutCaloriePredictor.mlmodel")
        if FileManager.default.fileExists(atPath: userModelURL.path) {
            return userModelURL
        }
        
        // Fall back to bundled model if available
        if let bundledModelURL = Bundle.main.url(forResource: "WorkoutCaloriePredictor", withExtension: "mlmodel") {
            return bundledModelURL
        }
        
        // Return the user model path anyway (for future saving)
        return userModelURL
    }
    
    private var recommendationModelURL: URL {
        // First check if there's a user-trained model
        let userModelURL = modelContainerURL.appendingPathComponent("WorkoutRecommender.mlmodel")
        if FileManager.default.fileExists(atPath: userModelURL.path) {
            return userModelURL
        }
        
        // Fall back to bundled model if available
        if let bundledModelURL = Bundle.main.url(forResource: "WorkoutRecommender", withExtension: "mlmodel") {
            return bundledModelURL
        }
        
        // Return the user model path anyway (for future saving)
        return userModelURL
    }
    
    // MARK: - Model Management
    
    // Ensure model directory exists
    private func setupModelDirectory() {
        do {
            if !FileManager.default.fileExists(atPath: modelContainerURL.path) {
                try FileManager.default.createDirectory(at: modelContainerURL, withIntermediateDirectories: true)
            }
        } catch {
            print("Error creating ML model directory: \(error.localizedDescription)")
        }
    }
    
    // Check if models exist (either bundled or user-trained)
    func modelsExist() -> Bool {
        // Check for bundled models
        let bundledCalorieExists = Bundle.main.url(forResource: "WorkoutCaloriePredictor", withExtension: "mlmodel") != nil
        let bundledRecommenderExists = Bundle.main.url(forResource: "WorkoutRecommender", withExtension: "mlmodel") != nil
        
        // Check for user-trained models
        let userCalorieModelPath = modelContainerURL.appendingPathComponent("WorkoutCaloriePredictor.mlmodel").path
        let userRecommenderModelPath = modelContainerURL.appendingPathComponent("WorkoutRecommender.mlmodel").path
        
        let userCalorieExists = FileManager.default.fileExists(atPath: userCalorieModelPath)
        let userRecommenderExists = FileManager.default.fileExists(atPath: userRecommenderModelPath)
        
        // Return true if either bundled or user-trained models exist
        return (bundledCalorieExists || userCalorieExists) &&
               (bundledRecommenderExists || userRecommenderExists)
    }
    
    // MARK: - Simplified Training Approach
    
    // This function manages the workflow for model training
    // In a real implementation, this would:
    // 1. Export workout data to a server or companion macOS app
    // 2. The server/macOS app would train the model using CreateML
    // 3. Then send the trained model back to the iOS app
    
    func trainModels(with workouts: [Workout], userId: String, completion: @escaping (Bool) -> Void) {
        // For implementation simplicity, we'll simulate model "training" by:
        // 1. Calculating average stats for workout types
        // 2. Using these to create simple prediction logic
        
        setupModelDirectory()
        
        DispatchQueue.global(qos: .userInitiated).async {
            // In a real app, we would send the data to a server for training
            // or implement a companion macOS app for model creation
            
            // For now, we'll simulate successful training
            let success = self.buildStatisticalModels(workouts: workouts)
            
            DispatchQueue.main.async {
                if success {
                    // Log training event
                    FirebaseManager.shared.logEvent(name: "ml_models_trained", parameters: [
                        "workout_count": workouts.count,
                        "user_id": userId
                    ])
                }
                completion(success)
            }
        }
    }
    
    // Create statistical models from workout data
    private func buildStatisticalModels(workouts: [Workout]) -> Bool {
        // Need minimum number of workouts
        guard workouts.count >= 10 else {
            return false
        }
        
        // Save workout statistics per type to UserDefaults for basic predictions
        var statsByType: [String: [String: Double]] = [:]
        
        for workout in workouts {
            let typeName = workout.typeName
            
            // Initialize if needed
            if statsByType[typeName] == nil {
                statsByType[typeName] = ["count": 0, "totalCalories": 0, "totalDuration": 0]
            }
            
            // Update stats
            statsByType[typeName]?["count"]! += 1
            statsByType[typeName]?["totalCalories"]! += workout.caloriesBurned
            statsByType[typeName]?["totalDuration"]! += workout.duration
        }
        
        // Calculate averages and save them
        for (type, stats) in statsByType {
            let count = stats["count"] ?? 1
            statsByType[type]?["avgCalories"] = (stats["totalCalories"] ?? 0) / count
            statsByType[type]?["avgDuration"] = (stats["totalDuration"] ?? 0) / count
        }
        
        // Save to UserDefaults for future predictions
        UserDefaults.standard.set(statsByType, forKey: "WorkoutMLStats")
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "WorkoutMLLastTrainingDate")
        UserDefaults.standard.set(true, forKey: "HasTrainedModels")
        
        // Track most common day/time patterns for each workout type
        // Using a different format that's UserDefaults-compatible
        // Format: [workoutType: [dayKey-hourKey: count]]
        var dayTimePatterns: [String: [String: Int]] = [:]
        let calendar = Calendar.current
        
        for workout in workouts {
            let typeName = workout.typeName
            let dayOfWeek = calendar.component(.weekday, from: workout.date)
            let hour = calendar.component(.hour, from: workout.date)
            
            // Create a single string key from day and hour
            let key = "\(dayOfWeek)-\(hour)"
            
            // Initialize if needed
            if dayTimePatterns[typeName] == nil {
                dayTimePatterns[typeName] = [:]
            }
            
            // Update patterns
            if dayTimePatterns[typeName]?[key] == nil {
                dayTimePatterns[typeName]?[key] = 1
            } else {
                dayTimePatterns[typeName]?[key]! += 1
            }
        }
        
        // Save to UserDefaults
        UserDefaults.standard.set(dayTimePatterns, forKey: "WorkoutMLDayTimePatterns")
        
        print("Successfully built statistical ML models from \(workouts.count) workouts")
        return true
    }
    
    // MARK: - Prediction Methods
    
    // Predict calories for a workout
    func predictCalories(for workoutType: WorkoutType,
                         duration: TimeInterval,
                         intensity: WorkoutIntensity,
                         distance: Double? = nil,
                         heartRate: Double? = nil) -> Double? {
        
        // Try to use MLModel if available
        if let model = loadCalorieModel() {
            do {
                // Create feature dictionary
                var features: [String: MLFeatureValue] = [
                    "type": MLFeatureValue(string: workoutType.rawValue),
                    "duration": MLFeatureValue(double: duration / 60), // Convert to minutes
                    "intensity": MLFeatureValue(string: intensity.rawValue)
                ]
                
                // Add optional features
                if let distance = distance {
                    features["distance"] = MLFeatureValue(double: distance)
                }
                
                if let heartRate = heartRate {
                    features["heart_rate"] = MLFeatureValue(double: heartRate)
                }
                
                // Create input from features
                let input = try MLDictionaryFeatureProvider(dictionary: features)
                
                // Make prediction
                let prediction = try model.prediction(from: input)
                
                // Extract and return calorie value
                if let caloriesValue = prediction.featureValue(for: "calories") {
                    return caloriesValue.doubleValue
                }
            } catch {
                print("Error predicting calories: \(error.localizedDescription)")
                // Fall back to statistical prediction below
            }
        }
        
        // Fall back to statistical prediction if model not available or prediction failed
        return statisticalCaloriePrediction(for: workoutType, duration: duration, intensity: intensity, distance: distance)
    }
    
    // A simple statistical prediction based on historical data
    private func statisticalCaloriePrediction(for workoutType: WorkoutType,
                                           duration: TimeInterval,
                                           intensity: WorkoutIntensity,
                                           distance: Double? = nil) -> Double {
        
        // Get saved stats
        guard let stats = UserDefaults.standard.dictionary(forKey: "WorkoutMLStats") as? [String: [String: Double]] else {
            // Fall back to estimation
            return Workout.estimateCalories(
                type: workoutType,
                duration: duration,
                intensity: intensity,
                userWeight: nil
            )
        }
        
        // Get stats for this workout type
        guard let typeStats = stats[workoutType.rawValue] else {
            // Fall back to estimation
            return Workout.estimateCalories(
                type: workoutType,
                duration: duration,
                intensity: intensity,
                userWeight: nil
            )
        }
        
        // Get average calories per minute
        let avgDuration = typeStats["avgDuration"] ?? 30 * 60
        let avgCalories = typeStats["avgCalories"] ?? 200
        let caloriesPerMinute = avgCalories / (avgDuration / 60)
        
        // Calculate base prediction
        let basePrediction = caloriesPerMinute * (duration / 60)
        
        // Apply intensity multiplier
        let intensityMultiplier: Double
        switch intensity {
        case .light: intensityMultiplier = 0.8
        case .moderate: intensityMultiplier = 1.0
        case .intense: intensityMultiplier = 1.2
        case .maximum: intensityMultiplier = 1.5
        }
        
        return basePrediction * intensityMultiplier
    }
    
    // Recommend workout for a specific day and time
    func recommendWorkout(for date: Date = Date()) -> WorkoutType? {
        // Try to use MLModel if available
        if let model = loadRecommendationModel() {
            do {
                let calendar = Calendar.current
                let dayOfWeek = calendar.component(.weekday, from: date)
                let hour = calendar.component(.hour, from: date)
                
                // Create feature dictionary
                let features: [String: MLFeatureValue] = [
                    "day_of_week": MLFeatureValue(int64: Int64(dayOfWeek)),
                    "hour_of_day": MLFeatureValue(int64: Int64(hour)),
                    "duration": MLFeatureValue(double: 30) // Default duration
                ]
                
                // Create input from features
                let input = try MLDictionaryFeatureProvider(dictionary: features)
                
                // Make prediction
                let prediction = try model.prediction(from: input)
                
                // Extract and return workout type
                if let typeValue = prediction.featureValue(for: "workout_type"),
                   let typeString = typeValue.stringValue as String?,
                   let workoutType = WorkoutType(rawValue: typeString) {
                    return workoutType
                }
            } catch {
                print("Error recommending workout: \(error.localizedDescription)")
                // Fall back to statistical recommendation below
            }
        }
        
        // Fall back to statistical recommendation
        return statisticalWorkoutRecommendation(for: date)
    }
    
    // A simple statistical workout recommendation based on historical patterns
    private func statisticalWorkoutRecommendation(for date: Date) -> WorkoutType? {
        let calendar = Calendar.current
        let dayOfWeek = calendar.component(.weekday, from: date)
        let hour = calendar.component(.hour, from: date)
        
        // Create the key that matches our storage format
        let key = "\(dayOfWeek)-\(hour)"
        
        // Get saved patterns
        guard let patterns = UserDefaults.standard.dictionary(forKey: "WorkoutMLDayTimePatterns") as? [String: [String: Int]] else {
            return .running // Default recommendation
        }
        
        // Find the workout type with the highest occurrence for this day/hour
        var bestType: WorkoutType?
        var maxCount = 0
        
        for (typeStr, timePatterns) in patterns {
            guard let type = WorkoutType(rawValue: typeStr) else { continue }
            
            // Get count for this day/hour
            let count = timePatterns[key] ?? 0
            
            if count > maxCount {
                maxCount = count
                bestType = type
            }
        }
        
        return bestType ?? .running
    }
    
    // MARK: - Model Loading
    
    // Load calorie prediction model
    func loadCalorieModel() -> MLModel? {
        let modelURL = calorieModelURL
        
        // Check if model exists at the URL
        guard FileManager.default.fileExists(atPath: modelURL.path) else {
            print("Calorie prediction model not found at: \(modelURL.path)")
            return nil
        }
        
        do {
            let compiledModelURL = try MLModel.compileModel(at: modelURL)
            return try MLModel(contentsOf: compiledModelURL)
        } catch {
            print("Error loading calorie prediction model: \(error.localizedDescription)")
            return nil
        }
    }
    
    // Load workout recommendation model
    func loadRecommendationModel() -> MLModel? {
        let modelURL = recommendationModelURL
        
        // Check if model exists at the URL
        guard FileManager.default.fileExists(atPath: modelURL.path) else {
            print("Workout recommendation model not found at: \(modelURL.path)")
            return nil
        }
        
        do {
            let compiledModelURL = try MLModel.compileModel(at: modelURL)
            return try MLModel(contentsOf: compiledModelURL)
        } catch {
            print("Error loading workout recommendation model: \(error.localizedDescription)")
            return nil
        }
    }
}
