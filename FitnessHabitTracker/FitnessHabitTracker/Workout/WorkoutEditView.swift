//
//  WorkoutEditView.swift
//  FitnessHabitTracker
//
//  Created by Nikhil Av on 4/16/25.
//  Updated with SwiftData implementation

import SwiftUI
import SwiftData

struct WorkoutEditView: View {
    // Environment
    @EnvironmentObject var workoutViewModel: WorkoutViewModel
    @Environment(\.presentationMode) var presentationMode
    
    // Binding for sheet dismissal
    @Binding var isPresented: Bool
    
    // Original workout being edited
    var workout: Workout
    
    // Form state variables
    @State private var name: String
    @State private var type: WorkoutType
    @State private var duration: Double
    @State private var caloriesBurned: Double
    @State private var date: Date
    @State private var notes: String
    
    // Distance tracking
    @State private var distance: String = ""
    @State private var distanceUnit: DistanceUnit = .km
    
    // Intensity
    @State private var intensity: WorkoutIntensity
    
    // Heart rate
    @State private var averageHeartRate: String = ""
    @State private var maxHeartRate: String = ""
    
    // Validation
    @State private var showingValidationAlert = false
    @State private var validationMessage = ""
    
    // Advanced mode toggle
    @State private var showAdvancedOptions = false
    
    init(workout: Workout, isPresented: Binding<Bool>) {
        self.workout = workout
        self._isPresented = isPresented
        
        // Initialize state variables with workout values
        self._name = State(initialValue: workout.name)
        self._type = State(initialValue: workout.type)
        self._duration = State(initialValue: workout.duration / 60) // Convert seconds to minutes
        self._caloriesBurned = State(initialValue: workout.caloriesBurned)
        self._date = State(initialValue: workout.date)
        self._notes = State(initialValue: workout.notes ?? "")
        
        // Initialize intensity with a default value first
        self._intensity = State(initialValue: .moderate)
        
        // Then override with the workout's intensity if available
        if let workoutIntensity = workout.intensity {
            self._intensity = State(initialValue: workoutIntensity)
        }
        
        // Initialize new fields
        if let workoutDistance = workout.distance {
            self._distance = State(initialValue: String(format: "%.2f", workoutDistance))
        }
        
        if let avgHR = workout.averageHeartRate {
            self._averageHeartRate = State(initialValue: String(format: "%.0f", avgHR))
        }
        
        if let maxHR = workout.maxHeartRate {
            self._maxHeartRate = State(initialValue: String(format: "%.0f", maxHR))
        }
    }
    
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
                                action: { type = workoutType }
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
                            
                            Text("\(Int(duration)) min")
                                .font(.callout)
                                .frame(width: 70, alignment: .trailing)
                        }
                        
                        // Duration Presets
                        HStack(spacing: 8) {
                            ForEach([15, 30, 45, 60], id: \.self) { preset in
                                Button(action: {
                                    duration = Double(preset)
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
                            
                            Picker("", selection: $distanceUnit) {
                                ForEach(DistanceUnit.allCases, id: \.self) { unit in
                                    Text(unit.rawValue).tag(unit)
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .frame(width: 100)
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
                            Slider(value: $caloriesBurned, in: 1...5000, step: 5)
                                .accentColor(.orange)
                            
                            Text("\(Int(caloriesBurned))")
                                .font(.callout)
                                .frame(width: 50, alignment: .trailing)
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
                            Text(intensity.rawValue.capitalized).tag(intensity)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
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
                }
                
                // Action Buttons
                VStack(spacing: 12) {
                    Button(action: validateAndSaveWorkout) {
                        Text("Save Workout")
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isFormValid ? Color.blue : Color.gray)
                            .cornerRadius(10)
                    }
                    .disabled(!isFormValid)
                    
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
        .navigationTitle("Edit Workout")
        .navigationBarTitleDisplayMode(.inline)
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
    }
    
    // MARK: - Computed Properties
    
    var showsDistanceField: Bool {
        return type == .running || type == .walking || type == .cycling || type == .swimming
    }
    
    var isFormValid: Bool {
        return !name.isEmpty
    }
    
    // MARK: - Methods
    
    private func validateAndSaveWorkout() {
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
        
        // Update workout properties directly (SwiftData approach)
        workout.name = name
        workout.type = type
        workout.duration = duration * 60 // Convert to seconds
        workout.caloriesBurned = caloriesBurned
        workout.date = date
        workout.notes = notes.isEmpty ? nil : notes
        workout.distance = distanceInKm
        workout.intensity = intensity
        workout.averageHeartRate = avgHeartRateValue
        workout.maxHeartRate = maxHeartRateValue
        
        // Save the workout
        workoutViewModel.updateWorkout(workout)
        
        // Dismiss the view
        isPresented = false
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - Supporting Views

struct WorkoutTypeButton: View {
    var type: WorkoutType
    var isSelected: Bool
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: type.icon)
                    .font(.title3)
                    .foregroundColor(isSelected ? .white : .blue)
                    .frame(width: 40, height: 40)
                    .background(isSelected ? Color.blue : Color.blue.opacity(0.1))
                    .cornerRadius(10)
                
                Text(type.rawValue.capitalized)
                    .font(.caption)
                    .foregroundColor(isSelected ? .blue : .gray)
            }
            .padding(.vertical, 4)
        }
    }
}

struct FormTextField: View {
    var title: String
    @Binding var text: String
    var placeholder: String
    var keyboardType: UIKeyboardType
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
                .padding(.leading, 16)
            
            TextField(placeholder, text: $text)
                .keyboardType(keyboardType)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                .padding(.horizontal)
        }
    }
}

// MARK: - Preview

struct WorkoutEditView_Previews: PreviewProvider {
    @State static var isPresented = true
    
    static var previews: some View {
        NavigationView {
            WorkoutEditView(
                workout: Workout(
                    name: "Morning Run",
                    type: .running,
                    duration: 1800,
                    caloriesBurned: 320,
                    notes: "Felt great today!"
                ),
                isPresented: $isPresented
            )
            .environmentObject(WorkoutViewModel())
        }
        .modelContainerPreview {
            Text("Preview with SwiftData")
        }
    }
}
