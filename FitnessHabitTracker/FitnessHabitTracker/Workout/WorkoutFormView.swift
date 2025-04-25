//
//  WorkoutFormView.swift
//  FitnessHabitTracker
//
//  Created by Nikhil Av on 4/16/25.
//  Updated with SwiftData implementation and CoreML integration

import SwiftUI
import SwiftData

struct WorkoutFormView: View {
    @EnvironmentObject var workoutViewModel: WorkoutViewModel
    @Binding var isPresented: Bool
    @Environment(\.colorScheme) var colorScheme
    
    // Form state variables
    @State private var name = ""
    @State private var type: WorkoutType = .running
    @State private var duration: Double = 30
    @State private var caloriesBurned: Double = 200
    @State private var date = Date()
    @State private var notes = ""
    @State private var distance = ""
    @State private var intensity: WorkoutIntensity = .moderate
    @State private var averageHeartRate = ""
    @State private var maxHeartRate = ""
    @State private var showAdvancedOptions = false
    @State private var distanceUnit: DistanceUnit = .km
    
    // CoreML prediction state
    @State private var predictedCalories: Double? = nil
    
    // Validation
    @State private var showingValidationAlert = false
    @State private var validationMessage = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Workout Type Picker
                VStack(alignment: .leading, spacing: 8) {
                    Text("Workout Type")
                        .font(.headline)
                        .foregroundColor(.gray)
                    
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 12) {
                        ForEach(WorkoutType.allCases, id: \.self) { workoutType in
                            WorkoutTypeButton(
                                type: workoutType,
                                isSelected: type == workoutType,
                                action: {
                                    type = workoutType
                                    if workoutViewModel.mlModelsAvailable {
                                        predictedCalories = nil // Reset prediction when type changes
                                    }
                                }
                            )
                        }
                    }
                }
                .padding(.horizontal)
                
                // Basic Details Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Workout Details")
                        .font(.headline)
                        .padding(.leading)
                    
                    FormTextField(
                        title: "Workout Name",
                        text: $name,
                        placeholder: "e.g. Morning Run",
                        keyboardType: .default
                    )
                    
                    DatePicker("Date & Time", selection: $date)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                        .padding(.horizontal)
                }
                
                // Duration Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Duration")
                        .font(.headline)
                        .padding(.leading)
                    
                    VStack(spacing: 8) {
                        HStack {
                            Slider(value: $duration, in: 1...180, step: 1)
                                .accentColor(.blue)
                                .onChange(of: duration) { _ in
                                    if workoutViewModel.mlModelsAvailable {
                                        predictedCalories = nil // Reset prediction when duration changes
                                    }
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
                                    if workoutViewModel.mlModelsAvailable {
                                        predictedCalories = nil // Reset prediction when duration changes
                                    }
                                }) {
                                    Text("\(preset) min")
                                        .font(.caption)
                                        .padding(.vertical, 6)
                                        .padding(.horizontal, 12)
                                        .background(duration == Double(preset) ? Color.blue : Color.gray.opacity(0.2))
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
                
                // Distance Section (for applicable workout types)
                if showsDistanceField {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Distance")
                            .font(.headline)
                            .padding(.leading)
                        
                        HStack {
                            TextField("Distance", text: $distance)
                                .keyboardType(.decimalPad)
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(10)
                                .onChange(of: distance) { _ in
                                    if workoutViewModel.mlModelsAvailable {
                                        predictedCalories = nil // Reset prediction when distance changes
                                    }
                                }
                            
                            Picker("", selection: $distanceUnit) {
                                ForEach(DistanceUnit.allCases, id: \.self) { unit in
                                    Text(unit.rawValue).tag(unit)
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .frame(width: 100)
                            .onChange(of: distanceUnit) { _ in
                                if workoutViewModel.mlModelsAvailable {
                                    predictedCalories = nil // Reset prediction when unit changes
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                // Calories Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Calories Burned")
                        .font(.headline)
                        .padding(.leading)
                    
                    VStack(spacing: 8) {
                        HStack {
                            Slider(value: $caloriesBurned, in: 1...1000, step: 5)
                                .accentColor(.orange)
                            
                            Text("\(Int(caloriesBurned))")
                                .font(.callout)
                                .frame(width: 50, alignment: .trailing)
                        }
                        
                        // Calorie Prediction
                        if workoutViewModel.mlModelsAvailable {
                            HStack {
                                if let predicted = predictedCalories {
                                    Label {
                                        Text("AI estimate: \(Int(predicted)) cal")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    } icon: {
                                        Image(systemName: "brain")
                                            .font(.caption)
                                            .foregroundColor(.purple)
                                    }
                                } else {
                                    Spacer()
                                }
                                
                                Button("Predict") {
                                    updateCaloriePrediction()
                                }
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color.purple.opacity(0.2))
                                .foregroundColor(.purple)
                                .cornerRadius(8)
                            }
                            .padding(.top, 4)
                        }
                        
                        // Calorie Presets
                        HStack(spacing: 8) {
                            ForEach([100, 200, 300, 500], id: \.self) { preset in
                                Button(action: {
                                    caloriesBurned = Double(preset)
                                }) {
                                    Text("\(preset)")
                                        .font(.caption)
                                        .padding(.vertical, 6)
                                        .padding(.horizontal, 12)
                                        .background(caloriesBurned == Double(preset) ? Color.orange : Color.gray.opacity(0.2))
                                        .foregroundColor(caloriesBurned == Double(preset) ? .white : .primary)
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
                
                // Intensity Section
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
                        if workoutViewModel.mlModelsAvailable {
                            predictedCalories = nil // Reset prediction when intensity changes
                        }
                    }
                }
                
                // Advanced Options Toggle
                Button(action: {
                    withAnimation {
                        showAdvancedOptions.toggle()
                    }
                }) {
                    HStack {
                        Text(showAdvancedOptions ? "Hide Advanced Options" : "Show Advanced Options")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                        
                        Image(systemName: showAdvancedOptions ? "chevron.up" : "chevron.down")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    .padding(.vertical, 8)
                }
                
                // Advanced Options Section
                if showAdvancedOptions {
                    VStack(spacing: 16) {
                        // Heart Rate
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Heart Rate")
                                .font(.headline)
                                .padding(.leading)
                            
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Average")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    
                                    TextField("Avg", text: $averageHeartRate)
                                        .keyboardType(.numberPad)
                                        .padding()
                                        .background(Color.gray.opacity(0.1))
                                        .cornerRadius(10)
                                }
                                
                                VStack(alignment: .leading) {
                                    Text("Maximum")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    
                                    TextField("Max", text: $maxHeartRate)
                                        .keyboardType(.numberPad)
                                        .padding()
                                        .background(Color.gray.opacity(0.1))
                                        .cornerRadius(10)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical, 8)
                    .transition(.opacity)
                }
                
                // Notes Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Notes")
                        .font(.headline)
                        .padding(.leading)
                    
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                        .padding(10)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                        .padding(.horizontal)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                .padding(.horizontal)
                        )
                }
                
                // Save Button
                Button(action: saveWorkout) {
                    Text("Save Workout")
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isFormValid ? Color.blue : Color.gray)
                        .cornerRadius(10)
                        .padding(.horizontal)
                }
                .disabled(!isFormValid)
                .padding(.top, 10)
                
                // Cancel Button
                Button(action: {
                    isPresented = false
                }) {
                    Text("Cancel")
                        .fontWeight(.medium)
                        .foregroundColor(.red)
                }
                .padding(.bottom, 30)
            }
            .padding(.vertical)
        }
        .navigationTitle("Add Workout")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(leading: Button("Cancel") {
            isPresented = false
        })
        .alert(isPresented: $showingValidationAlert) {
            Alert(
                title: Text("Validation Error"),
                message: Text(validationMessage),
                dismissButton: .default(Text("OK"))
            )
        }
        .onTapGesture {
            hideKeyboard()
        }
        .background(colorScheme == .dark ? Color.black : Color.white)
    }
    
    // MARK: - Computed Properties
    
    var showsDistanceField: Bool {
        return type == .running || type == .walking || type == .cycling || type == .swimming
    }
    
    var isFormValid: Bool {
        return !name.isEmpty
    }
    
    // MARK: - Methods
    
    private func updateCaloriePrediction() {
        // Only predict if ML models are available
        if workoutViewModel.mlModelsAvailable {
            predictedCalories = workoutViewModel.predictCalories(
                for: type,
                duration: duration * 60, // Convert to seconds
                intensity: intensity,
                distance: Double(distance)
            )
            
            if let predicted = predictedCalories {
                caloriesBurned = predicted
            }
        }
    }
    
    private func saveWorkout() {
        // Validate name
        if name.isEmpty {
            validationMessage = "Please enter a workout name"
            showingValidationAlert = true
            return
        }
        
        // Parse numeric values
        let distanceValue: Double? = Double(distance)
        let avgHeartRateValue: Double? = Double(averageHeartRate)
        let maxHeartRateValue: Double? = Double(maxHeartRate)
        
        // Convert distance to kilometers if needed
        var distanceInKm: Double? = nil
        if let distVal = distanceValue {
            distanceInKm = (distanceUnit == .km) ? distVal : distVal * 1.60934
        }
        
        // Create new workout
        let newWorkout = Workout(
            id: UUID().uuidString,
            name: name,
            type: type,
            duration: duration * 60, // Convert to seconds
            caloriesBurned: caloriesBurned,
            date: date,
            notes: notes.isEmpty ? nil : notes,
            distance: distanceInKm,
            intensity: intensity,
            averageHeartRate: avgHeartRateValue,
            maxHeartRate: maxHeartRateValue
        )
        
        // Add workout to view model
        workoutViewModel.addWorkout(newWorkout)
        
        // Dismiss the view
        isPresented = false
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - Preview

struct WorkoutFormView_Previews: PreviewProvider {
    @State static var isPresented = true
    
    static var previews: some View {
        NavigationView {
            WorkoutFormView(isPresented: $isPresented)
                .environmentObject(WorkoutViewModel())
        }
        .modelContainerPreview {
            Text("Preview with SwiftData")
        }
    }
}
