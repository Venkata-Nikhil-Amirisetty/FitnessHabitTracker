//
//  WorkoutMLViews.swift
//  FitnessHabitTracker
//
//  Created for CoreML integration
//

import SwiftUI
import SwiftData

// MARK: - Workout Suggestions View for Dashboard

struct WorkoutSuggestionsView: View {
    @EnvironmentObject var workoutViewModel: WorkoutViewModel
    @State private var showingNewWorkout = false
    @State private var selectedSuggestion: WorkoutSuggestion? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                HStack {
                    Image(systemName: "brain")
                        .foregroundColor(.purple)
                    
                    Text("Smart Suggestions")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                if !workoutViewModel.mlModelsAvailable {
                    Button(action: {
                        workoutViewModel.trainMLModels()
                    }) {
                        HStack {
                            Image(systemName: "wand.and.stars")
                                .font(.caption)
                            Text("Train")
                                .font(.caption)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.purple.opacity(0.1))
                        .cornerRadius(10)
                    }
                    .disabled(workoutViewModel.isTrainingModels || workoutViewModel.workouts.count < 10)
                }
            }
            .padding(.horizontal)
            
            if workoutViewModel.isTrainingModels {
                HStack {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                    
                    Text("Training models...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding()
            } else if workoutViewModel.workoutSuggestions.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 30))
                        .foregroundColor(.purple.opacity(0.7))
                    
                    Text("Not enough workout data")
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                    
                    Text("Add more workouts to get personalized suggestions")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding()
            } else {
                // Suggestions cards
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(workoutViewModel.workoutSuggestions, id: \.id) { suggestion in
                            WorkoutSuggestionCard(suggestion: suggestion)
                                .onTapGesture {
                                    selectedSuggestion = suggestion
                                    showingNewWorkout = true
                                }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .sheet(isPresented: $showingNewWorkout) {
            if let suggestion = selectedSuggestion {
                NavigationView {
                    WorkoutFromSuggestionView(suggestion: suggestion, isPresented: $showingNewWorkout)
                        .environmentObject(workoutViewModel)
                }
            }
        }
    }
}

// MARK: - Suggestion Card

struct WorkoutSuggestionCard: View {
    let suggestion: WorkoutSuggestion
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with icon
            HStack {
                Image(systemName: suggestion.workoutType.icon)
                    .font(.title3)
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [.purple, .purple.opacity(0.7)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(10)
                
                Spacer()
                
                // Confidence indicator
                ConfidenceIndicator(confidence: suggestion.confidence)
            }
            
            // Title and description
            VStack(alignment: .leading, spacing: 5) {
                Text(suggestion.title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .lineLimit(1)
                
                Text(suggestion.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Divider()
            
            // Workout details
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(suggestion.workoutType.rawValue.capitalized)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text(formatDuration(suggestion.suggestedDuration))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Start button
                Image(systemName: "play.circle.fill")
                    .foregroundColor(.purple)
                    .font(.title3)
            }
        }
        .padding()
        .frame(width: 220, height: 170)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds / 60)
        return "\(minutes) min"
    }
}

// MARK: - Confidence Indicator

struct ConfidenceIndicator: View {
    let confidence: Double
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<3) { index in
                Rectangle()
                    .fill(index < Int(confidence * 3) ? Color.purple : Color.gray.opacity(0.3))
                    .frame(width: 8, height: index == 0 ? 8 : (index == 1 ? 12 : 16))
                    .cornerRadius(2)
            }
        }
    }
}

// MARK: - Create Workout from Suggestion View

struct WorkoutFromSuggestionView: View {
    @EnvironmentObject var workoutViewModel: WorkoutViewModel
    @Binding var isPresented: Bool
    
    let suggestion: WorkoutSuggestion
    
    @State private var name: String = ""
    @State private var duration: Double
    @State private var date = Date()
    @State private var intensity: WorkoutIntensity = .moderate
    @State private var notes: String = ""
    
    // Prediction data
    @State private var predictedCalories: Double?
    
    init(suggestion: WorkoutSuggestion, isPresented: Binding<Bool>) {
        self.suggestion = suggestion
        self._isPresented = isPresented
        
        // Initialize with suggestion values
        self._name = State(initialValue: suggestion.title)
        self._duration = State(initialValue: suggestion.suggestedDuration / 60) // Convert to minutes
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Suggestion header
                VStack(spacing: 12) {
                    Image(systemName: suggestion.workoutType.icon)
                        .font(.system(size: 40))
                        .foregroundColor(.white)
                        .frame(width: 80, height: 80)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [.purple, .purple.opacity(0.7)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(20)
                        .shadow(color: Color.purple.opacity(0.3), radius: 10, x: 0, y: 5)
                    
                    Text("Suggested \(suggestion.workoutType.rawValue.capitalized) Workout")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(suggestion.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.bottom, 10)
                
                // Form fields
                VStack(alignment: .leading, spacing: 16) {
                    FormTextField(
                        title: "Workout Name",
                        text: $name,
                        placeholder: "e.g. Morning Run",
                        keyboardType: .default
                    )
                    
                    // Duration control
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Duration")
                            .font(.headline)
                            .padding(.leading)
                        
                        VStack(spacing: 8) {
                            HStack {
                                Slider(value: $duration, in: 1...180, step: 1)
                                    .accentColor(.purple)
                                    .onChange(of: duration) { _ in
                                        updateCaloriePrediction()
                                    }
                                
                                Text("\(Int(duration)) min")
                                    .font(.callout)
                                    .frame(width: 70, alignment: .trailing)
                            }
                            
                            // Duration Presets
                            HStack(spacing: 8) {
                                ForEach([15, 30, 45, 60], id: \.self) { preset in
                                    Button(action: {
                                        duration = Double(preset)
                                        updateCaloriePrediction()
                                    }) {
                                        Text("\(preset) min")
                                            .font(.caption)
                                            .padding(.vertical, 6)
                                            .padding(.horizontal, 12)
                                            .background(duration == Double(preset) ? Color.purple : Color.gray.opacity(0.2))
                                            .foregroundColor(duration == Double(preset) ? .white : .primary)
                                            .cornerRadius(8)
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                        .padding(.horizontal)
                    }
                    
                    // Intensity picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Intensity")
                            .font(.headline)
                            .padding(.leading)
                        
                        Picker("", selection: $intensity) {
                            ForEach(WorkoutIntensity.allCases, id: \.self) { intensity in
                                HStack {
                                    Circle()
                                        .fill(intensity.color)
                                        .frame(width: 10, height: 10)
                                    Text(intensity.rawValue.capitalized)
                                }
                                .tag(intensity)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding(.horizontal)
                        .onChange(of: intensity) { _ in
                            updateCaloriePrediction()
                        }
                    }
                    
                    // Date picker
                    DatePicker("Date & Time", selection: $date)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                        .padding(.horizontal)
                    
                    // ML calorie prediction
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Predicted Calories")
                            .font(.headline)
                            .padding(.leading)
                        
                        HStack {
                            Image(systemName: "brain.head.profile")
                                .foregroundColor(.purple)
                                .font(.title3)
                            
                            if let calories = predictedCalories {
                                Text("\(Int(calories)) calories")
                                    .font(.title3)
                                    .fontWeight(.bold)
                            } else {
                                Text("Calculating...")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if workoutViewModel.mlModelsAvailable {
                                Text("AI Powered")
                                    .font(.caption)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.purple)
                                    .cornerRadius(10)
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                        .padding(.horizontal)
                    }
                    
                    // Notes
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Notes")
                            .font(.headline)
                            .padding(.leading)
                        
                        TextEditor(text: $notes)
                            .frame(minHeight: 100)
                            .padding(10)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(10)
                            .padding(.horizontal)
                    }
                }
                
                // Buttons
                VStack(spacing: 12) {
                    Button(action: saveWorkout) {
                        Text("Start Workout")
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.purple)
                            .cornerRadius(10)
                    }
                    
                    Button(action: {
                        isPresented = false
                    }) {
                        Text("Cancel")
                            .fontWeight(.medium)
                            .foregroundColor(.red)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 10)
                .padding(.bottom, 30)
            }
            .padding(.vertical)
        }
        .navigationTitle("Suggested Workout")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            updateCaloriePrediction()
        }
    }
    
    private func updateCaloriePrediction() {
        // Get calorie prediction using ML model
        predictedCalories = workoutViewModel.predictCalories(
            for: suggestion.workoutType,
            duration: duration * 60, // Convert to seconds
            intensity: intensity
        )
    }
    
    private func saveWorkout() {
        // Calculate calories (use prediction or fallback to estimation)
        let calories = predictedCalories ?? Workout.estimateCalories(
            type: suggestion.workoutType,
            duration: duration * 60,
            intensity: intensity,
            userWeight: nil
        )
        
        // Create workout
        let workout = Workout(
            id: UUID().uuidString,
            name: name,
            type: suggestion.workoutType,
            duration: duration * 60, // Convert to seconds
            caloriesBurned: calories,
            date: date,
            notes: notes.isEmpty ? nil : notes,
            intensity: intensity
        )
        
        // Add workout
        workoutViewModel.addWorkout(workout)
        
        // Close sheet
        isPresented = false
    }
}

// MARK: - Workout ML Analytics View

struct WorkoutMLAnalyticsView: View {
    @EnvironmentObject var workoutViewModel: WorkoutViewModel
    @State private var showingMLTraining = false
    
    var body: some View {
        VStack(spacing: 20) {
            // ML Status Header
            VStack(spacing: 10) {
                HStack {
                    Image(systemName: workoutViewModel.mlModelsAvailable ? "brain.head.profile" : "brain")
                        .font(.system(size: 40))
                        .foregroundColor(.white)
                        .padding(20)
                        .background(
                            Circle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [.purple, .blue]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Text(workoutViewModel.mlModelsAvailable ? "ML Models Active" : "ML Models Inactive")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text(workoutViewModel.mlModelsAvailable ?
                             "Your workouts are enhanced with AI" :
                             "Add more workouts to enable AI features")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(15)
                .padding(.horizontal)
                
                // Training button
                if !workoutViewModel.mlModelsAvailable && workoutViewModel.workouts.count >= 10 {
                    Button(action: {
                        workoutViewModel.trainMLModels()
                    }) {
                        HStack {
                            Image(systemName: "wand.and.stars")
                            Text("Train ML Models")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.purple)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    .disabled(workoutViewModel.isTrainingModels)
                }
            }
            
            // ML Feature cards
            VStack(spacing: 16) {
                // Feature: Calorie Prediction
                FeatureCard(
                    title: "Calorie Prediction",
                    description: "Accurately predicts calories burned based on your workout history",
                    icon: "flame.fill",
                    isEnabled: workoutViewModel.mlModelsAvailable
                )
                
                // Feature: Recommendations
                FeatureCard(
                    title: "Smart Recommendations",
                    description: "Get personalized workout suggestions based on your patterns",
                    icon: "wand.and.stars",
                    isEnabled: workoutViewModel.mlModelsAvailable
                )
                
                // Feature: Activity Analysis
                FeatureCard(
                    title: "Activity Pattern Analysis",
                    description: "Identifies your most effective workout days and times",
                    icon: "chart.bar.fill",
                    isEnabled: workoutViewModel.mlModelsAvailable
                )
            }
            .padding(.horizontal)
            
            // Model info
            if workoutViewModel.mlModelsAvailable {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Model Information")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        ModelInfoRow(
                            label: "Training Data Size",
                            value: "\(workoutViewModel.workouts.count) workouts"
                        )
                        
                        Divider()
                        
                        ModelInfoRow(
                            label: "Model Types",
                            value: "Regression, Classification"
                        )
                        
                        Divider()
                        
                        // Here we'd show actual date if we were tracking it
                        ModelInfoRow(
                            label: "Last Updated",
                            value: "Today"
                        )
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                    .padding(.horizontal)
                }
                
                // Retrain button
                Button(action: {
                    showingMLTraining = true
                }) {
                    Text("Retrain Models")
                        .foregroundColor(.purple)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.purple, lineWidth: 1)
                        )
                }
                .padding(.horizontal)
                .disabled(workoutViewModel.isTrainingModels)
            } else {
                // Requirements explainer
                VStack(alignment: .leading, spacing: 10) {
                    Text("Requirements to Enable ML Features")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        RequirementRow(
                            text: "At least 10 workout sessions",
                            isMet: workoutViewModel.workouts.count >= 10
                        )
                        
                        RequirementRow(
                            text: "Multiple workout types",
                            isMet: workoutViewModel.workouts.map({ $0.type }).count >= 2
                        )
                        
                        RequirementRow(
                            text: "Workouts over multiple days",
                            isMet: Set(workoutViewModel.workouts.map {
                                Calendar.current.startOfDay(for: $0.date)
                            }).count >= 3
                        )
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                    .padding(.horizontal)
                }
            }
            
            Spacer()
        }
        .padding(.vertical)
        .navigationTitle("ML Features")
        .navigationBarTitleDisplayMode(.inline)
        .alert(isPresented: $showingMLTraining) {
            Alert(
                title: Text("Retrain ML Models"),
                message: Text("Do you want to retrain the models with your latest workout data? This might take a moment."),
                primaryButton: .default(Text("Retrain")) {
                    workoutViewModel.trainMLModels()
                },
                secondaryButton: .cancel()
            )
        }
    }
}

// MARK: - Supporting Views

struct FeatureCard: View {
    let title: String
    let description: String
    let icon: String
    let isEnabled: Bool
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(isEnabled ? .white : .gray)
                .frame(width: 45, height: 45)
                .background(
                    Circle()
                        .fill(isEnabled ? Color.purple : Color.gray.opacity(0.3))
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(isEnabled ? .primary : .gray)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(isEnabled ? .secondary : .gray)
            }
            
            Spacer()
            
            Image(systemName: isEnabled ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(isEnabled ? .green : .gray)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

struct ModelInfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

struct RequirementRow: View {
    let text: String
    let isMet: Bool
    
    var body: some View {
        HStack {
            Image(systemName: isMet ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isMet ? .green : .gray)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(isMet ? .primary : .secondary)
        }
    }
}
