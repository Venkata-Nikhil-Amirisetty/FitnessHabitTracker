//
//  GoalFormView.swift
//  FitnessHabitTracker
//
//  Created by Nikhil Av on 4/21/25.
//


//
//  GoalFormView.swift
//  FitnessHabitTracker
//
//  Created for Goal Setting Feature
//

import SwiftUI
import FirebaseAuth

struct GoalFormView: View {
    @EnvironmentObject var goalViewModel: GoalViewModel
    @EnvironmentObject var workoutViewModel: WorkoutViewModel
    @EnvironmentObject var habitViewModel: HabitViewModel
    @Environment(\.colorScheme) var colorScheme
    @Binding var isPresented: Bool
    
    // Form fields
    @State private var title = ""
    @State private var goalType: GoalType = .workout
    @State private var targetValue = ""
    @State private var timeframe: GoalTimeframe = .weekly
    @State private var customEndDate = Date()
    @State private var notes = ""
    @State private var linkedWorkoutType: WorkoutType? = nil
    @State private var linkedHabitId: String? = nil
    @State private var startImmediately = true
    
    // Animation states
    @State private var isAnimating = false
    
    // Validation
    @State private var showingValidationAlert = false
    @State private var validationMessage = ""
    
    // Show linked item picker
    @State private var showingWorkoutTypePicker = false
    @State private var showingHabitPicker = false
    
    // Suggested goals view
    @State private var showingSuggestedGoals = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [colorScheme == .dark ? Color.black : Color.white, getTypeColor().opacity(0.1)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    // Form header with animated icon
                    HStack {
                        Spacer()
                        ZStack {
                            Circle()
                                .fill(getTypeColor().opacity(0.2))
                                .frame(width: 80, height: 80)
                                .scaleEffect(isAnimating ? 1.0 : 0.8)
                                .animation(.spring(response: 0.5).delay(0.2), value: isAnimating)
                            
                            Image(systemName: goalType.icon)
                                .font(.system(size: 32))
                                .foregroundColor(getTypeColor())
                                .scaleEffect(isAnimating ? 1.0 : 0)
                                .rotationEffect(isAnimating ? .degrees(0) : .degrees(-90))
                                .animation(.spring(response: 0.6, dampingFraction: 0.6).delay(0.3), value: isAnimating)
                        }
                        Spacer()
                    }
                    .padding(.top, 20)
                    .opacity(isAnimating ? 1.0 : 0.0)
                    .animation(.easeIn(duration: 0.3), value: isAnimating)
                    
                    Form {
                        Section(header:
                            SectionHeaderView(title: "Goal Details", icon: "target", color: getTypeColor())
                        ) {
                            HStack {
                                Image(systemName: "text.cursor")
                                    .foregroundColor(getTypeColor())
                                    .font(.system(size: 18))
                                    .frame(width: 24)
                                
                                TextField("Goal Title", text: $title)
                                    .font(.system(size: 17, design: .rounded))
                                    .disableAutocorrection(true)
                            }
                            .padding(.vertical, 5)
                            
                            HStack {
                                Image(systemName: "folder")
                                    .foregroundColor(getTypeColor())
                                    .font(.system(size: 18))
                                    .frame(width: 24)
                                
                                Picker("Goal Type", selection: $goalType) {
                                    ForEach(GoalType.allCases, id: \.self) { type in
                                        HStack {
                                            Image(systemName: type.icon)
                                            Text(type.displayName)
                                        }
                                        .tag(type)
                                    }
                                }
                                .onChange(of: goalType) { _ in
                                    // Reset linked items when type changes
                                    if goalType != .workout {
                                        linkedWorkoutType = nil
                                    }
                                    if goalType != .habit && goalType != .streak {
                                        linkedHabitId = nil
                                    }
                                    
                                    // Animate icon change
                                    withAnimation(.spring(response: 0.5)) {
                                        isAnimating = false
                                        
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                            withAnimation(.spring(response: 0.5)) {
                                                isAnimating = true
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(.vertical, 5)
                            
                            HStack {
                                Image(systemName: "number")
                                    .foregroundColor(getTypeColor())
                                    .font(.system(size: 18))
                                    .frame(width: 24)
                                
                                Text("Target")
                                    .font(.system(size: 17, design: .rounded))
                                
                                Spacer()
                                
                                TextField("0", text: $targetValue)
                                    .keyboardType(.numberPad)
                                    .multilineTextAlignment(.trailing)
                                    .frame(width: 120)
                                    .font(.system(size: 17, weight: .medium, design: .rounded))
                                
                                Text(getUnitLabel())
                                    .foregroundColor(.secondary)
                                    .font(.system(size: 15, design: .rounded))
                            }
                            .padding(.vertical, 5)
                        }
                        
                        Section(header:
                            SectionHeaderView(title: "Timeframe", icon: "calendar", color: getTypeColor())
                        ) {
                            HStack {
                                Image(systemName: "clock")
                                    .foregroundColor(getTypeColor())
                                    .font(.system(size: 18))
                                    .frame(width: 24)
                                
                                Picker("Duration", selection: $timeframe) {
                                    ForEach(GoalTimeframe.allCases, id: \.self) { timeframe in
                                        Text(timeframe.displayName).tag(timeframe)
                                    }
                                }
                                .pickerStyle(DefaultPickerStyle())
                            }
                            .padding(.vertical, 5)
                            
                            if timeframe == .custom {
                                HStack {
                                    Image(systemName: "calendar.badge.clock")
                                        .foregroundColor(getTypeColor())
                                        .font(.system(size: 18))
                                        .frame(width: 24)
                                    
                                    DatePicker("End Date", selection: $customEndDate, displayedComponents: .date)
                                        .font(.system(size: 17, design: .rounded))
                                }
                                .padding(.vertical, 5)
                            }
                            
                            HStack {
                                Image(systemName: "play.circle")
                                    .foregroundColor(getTypeColor())
                                    .font(.system(size: 18))
                                    .frame(width: 24)
                                
                                Toggle("Start Immediately", isOn: $startImmediately)
                                    .toggleStyle(SwitchToggleStyle(tint: getTypeColor()))
                                    .font(.system(size: 17, design: .rounded))
                            }
                            .padding(.vertical, 5)
                        }
                        
                        // Linking section
                        if goalType == .workout {
                            Section(header:
                                SectionHeaderView(title: "Link to Workout Type (Optional)", icon: "link", color: getTypeColor())
                            ) {
                                if let selectedType = linkedWorkoutType {
                                    Button(action: {
                                        showingWorkoutTypePicker = true
                                    }) {
                                        HStack {
                                            Image(systemName: "figure.walk")
                                                .foregroundColor(getTypeColor())
                                                .font(.system(size: 18))
                                                .frame(width: 24)
                                            
                                            Text("Workout Type")
                                                .font(.system(size: 17, design: .rounded))
                                                .foregroundColor(.primary)
                                            
                                            Spacer()
                                            
                                            HStack(spacing: 4) {
                                                Image(systemName: selectedType.icon)
                                                    .foregroundColor(getTypeColor())
                                                
                                                Text(selectedType.rawValue.capitalized)
                                                    .font(.system(size: 16, weight: .medium, design: .rounded))
                                                    .foregroundColor(getTypeColor())
                                            }
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 5)
                                            .background(getTypeColor().opacity(0.1))
                                            .cornerRadius(8)
                                            
                                            Image(systemName: "chevron.right")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                } else {
                                    Button(action: {
                                        showingWorkoutTypePicker = true
                                    }) {
                                        HStack {
                                            Image(systemName: "plus.circle.fill")
                                                .foregroundColor(getTypeColor())
                                                .font(.system(size: 18))
                                                .frame(width: 24)
                                            
                                            Text("Select Workout Type")
                                                .font(.system(size: 17, design: .rounded))
                                                .foregroundColor(getTypeColor())
                                            
                                            Spacer()
                                            
                                            Image(systemName: "chevron.right")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        } else if goalType == .habit || goalType == .streak {
                            Section(header:
                                SectionHeaderView(title: "Link to Specific Habit (Optional)", icon: "link", color: getTypeColor())
                            ) {
                                if let habitId = linkedHabitId,
                                   let habit = habitViewModel.habits.first(where: { $0.id == habitId }) {
                                    Button(action: {
                                        showingHabitPicker = true
                                    }) {
                                        HStack {
                                            Image(systemName: "repeat.circle")
                                                .foregroundColor(getTypeColor())
                                                .font(.system(size: 18))
                                                .frame(width: 24)
                                            
                                            Text("Habit")
                                                .font(.system(size: 17, design: .rounded))
                                                .foregroundColor(.primary)
                                            
                                            Spacer()
                                            
                                            Text(habit.name)
                                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                                .foregroundColor(getTypeColor())
                                                .padding(.horizontal, 10)
                                                .padding(.vertical, 5)
                                                .background(getTypeColor().opacity(0.1))
                                                .cornerRadius(8)
                                            
                                            Image(systemName: "chevron.right")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                } else {
                                    Button(action: {
                                        showingHabitPicker = true
                                    }) {
                                        HStack {
                                            Image(systemName: "plus.circle.fill")
                                                .foregroundColor(getTypeColor())
                                                .font(.system(size: 18))
                                                .frame(width: 24)
                                            
                                            Text("Select Habit")
                                                .font(.system(size: 17, design: .rounded))
                                                .foregroundColor(getTypeColor())
                                            
                                            Spacer()
                                            
                                            Image(systemName: "chevron.right")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        }
                        
                        Section(header:
                            SectionHeaderView(title: "Notes (Optional)", icon: "note.text", color: getTypeColor())
                        ) {
                            TextEditor(text: $notes)
                                .frame(height: 100)
                                .font(.system(size: 17, design: .rounded))
                                .padding(5)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(getTypeColor().opacity(0.2), lineWidth: 1)
                                )
                                .padding(.vertical, 5)
                        }
                        
                        Section {
                            Button(action: {
                                // Show suggested goals
                                showingSuggestedGoals = true
                            }) {
                                HStack {
                                    Spacer()
                                    
                                    Image(systemName: "lightbulb.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(.yellow)
                                        .shadow(color: .yellow.opacity(0.5), radius: 2, x: 0, y: 0)
                                    
                                    Text("Suggested Goals")
                                        .font(.system(size: 17, weight: .medium, design: .rounded))
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                }
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.yellow.opacity(0.1))
                                )
                            }
                            .buttonStyle(SpringButtonStyle())
                            .listRowBackground(Color.clear)
                        }
                        
                        Section {
                            Button(action: saveGoal) {
                                HStack {
                                    Spacer()
                                    
                                    Text("Save Goal")
                                        .font(.system(size: 18, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                }
                                .padding(.vertical, 12)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [getTypeColor(), getTypeColor().opacity(0.8)]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(12)
                                .shadow(color: getTypeColor().opacity(0.3), radius: 5, x: 0, y: 2)
                            }
                            .buttonStyle(SpringButtonStyle())
                            .listRowBackground(Color.clear)
                        }
                    }
                    .scrollContentBackground(colorScheme == .dark ? .hidden : .visible)
                }
            }
            .navigationTitle("Create Goal")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading: Button(action: {
                isPresented = false
            }) {
                Text("Cancel")
                    .foregroundColor(getTypeColor())
            })
            .alert(isPresented: $showingValidationAlert) {
                Alert(
                    title: Text("Validation Error"),
                    message: Text(validationMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            .sheet(isPresented: $showingWorkoutTypePicker) {
                WorkoutTypePickerView(selectedType: $linkedWorkoutType)
            }
            .sheet(isPresented: $showingHabitPicker) {
                HabitPickerView(selectedHabitId: $linkedHabitId, habits: habitViewModel.habits)
            }
            .sheet(isPresented: $showingSuggestedGoals) {
                SuggestedGoalsView(isPresented: $showingSuggestedGoals, parentPresented: $isPresented)
                    .environmentObject(goalViewModel)
            }
            .onAppear {
                // Start animations
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation {
                        isAnimating = true
                    }
                }
            }
        }
    }
    
    private func saveGoal() {
        // Validate inputs
        guard !title.isEmpty else {
            validationMessage = "Please enter a goal title"
            showingValidationAlert = true
            return
        }
        
        guard let targetDouble = Double(targetValue), targetDouble > 0 else {
            validationMessage = "Please enter a valid target value greater than 0"
            showingValidationAlert = true
            return
        }
        
        // Create goal
        let startDate = startImmediately ? Date() : Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        var endDate: Date
        
        if timeframe == .custom {
            endDate = customEndDate
        } else {
            let calendar = Calendar.current
            switch timeframe {
            case .daily:
                endDate = calendar.date(byAdding: .day, value: 1, to: startDate)!
            case .weekly:
                endDate = calendar.date(byAdding: .day, value: 7, to: startDate)!
            case .monthly:
                endDate = calendar.date(byAdding: .month, value: 1, to: startDate)!
            default:
                endDate = calendar.date(byAdding: .day, value: 30, to: startDate)!
            }
        }
        
        guard let userId = Auth.auth().currentUser?.uid else {
            validationMessage = "You must be logged in to create a goal"
            showingValidationAlert = true
            return
        }
        
        let goal = Goal(
            userId: userId,
            title: title,
            type: goalType,
            targetValue: targetDouble,
            startDate: startDate,
            endDate: endDate,
            timeframe: timeframe,
            notes: notes.isEmpty ? nil : notes,
            linkedWorkoutType: linkedWorkoutType?.rawValue,
            linkedHabitId: linkedHabitId
        )
        
        // Save goal
        goalViewModel.addGoal(goal)
        
        // Log event
        FirebaseManager.shared.logEvent(name: "goal_created", parameters: [
            "goal_type": goalType.rawValue,
            "timeframe": timeframe.rawValue
        ])
        
        // Close sheet
        isPresented = false
    }
    
    private func getUnitLabel() -> String {
        switch goalType {
        case .workout: return "workouts"
        case .habit: return "completions"
        case .distance: return "kilometers"
        case .duration: return "minutes"
        case .streak: return "days"
        case .weight: return "kilograms"
        }
    }
    
    private func getTypeColor() -> Color {
        switch goalType {
        case .workout: return .blue
        case .habit: return .green
        case .distance: return .orange
        case .duration: return .purple
        case .streak: return .red
        case .weight: return .gray
        }
    }
}

// Custom section header
struct SectionHeaderView: View {
    var title: String
    var icon: String
    var color: Color
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(color)
            
            Text(title)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(color)
        }
    }
}



// Enhanced picker views
struct WorkoutTypePickerView: View {
    @Binding var selectedType: WorkoutType?
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                colorScheme == .dark ? Color.black.edgesIgnoringSafeArea(.all) : Color.white.edgesIgnoringSafeArea(.all)
                
                List {
                    ForEach(WorkoutType.allCases, id: \.self) { type in
                        Button(action: {
                            withAnimation {
                                selectedType = type
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                presentationMode.wrappedValue.dismiss()
                            }
                        }) {
                            HStack {
                                Image(systemName: type.icon)
                                    .font(.system(size: 18))
                                    .foregroundColor(.blue)
                                    .frame(width: 30)
                                
                                Text(type.rawValue.capitalized)
                                    .font(.system(size: 17, design: .rounded))
                                
                                Spacer()
                                
                                if selectedType == type {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.blue)
                                        .font(.system(size: 18))
                                }
                            }
                            .padding(.vertical, 6)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    // Option to clear selection
                    if selectedType != nil {
                        Button(action: {
                            withAnimation {
                                selectedType = nil
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                presentationMode.wrappedValue.dismiss()
                            }
                        }) {
                            HStack {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(.red)
                                    .frame(width: 30)
                                
                                Text("Clear Selection")
                                    .font(.system(size: 17, design: .rounded))
                                    .foregroundColor(.red)
                                
                                Spacer()
                            }
                            .padding(.vertical, 6)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .listStyle(InsetGroupedListStyle())
            }
            .navigationTitle("Select Workout Type")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

struct HabitPickerView: View {
    @Binding var selectedHabitId: String?
    var habits: [Habit]
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                colorScheme == .dark ? Color.black.edgesIgnoringSafeArea(.all) : Color.white.edgesIgnoringSafeArea(.all)
                
                List {
                    if habits.isEmpty {
                        Text("No habits available")
                            .font(.system(size: 16, design: .rounded))
                            .foregroundColor(.secondary)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .center)
                    } else {
                        ForEach(habits, id: \.id) { habit in
                            Button(action: {
                                withAnimation {
                                    selectedHabitId = habit.id
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    presentationMode.wrappedValue.dismiss()
                                }
                            }) {
                                HStack {
                                    Image(systemName: habit.category.icon)
                                        .font(.system(size: 18))
                                        .foregroundColor(.green)
                                        .frame(width: 30)
                                    
                                    Text(habit.name)
                                        .font(.system(size: 17, design: .rounded))
                                    
                                    Spacer()
                                    
                                    if selectedHabitId == habit.id {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                            .font(.system(size: 18))
                                    }
                                }
                                .padding(.vertical, 6)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        
                        // Option to clear selection
                        if selectedHabitId != nil {
                            Button(action: {
                                withAnimation {
                                    selectedHabitId = nil
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    presentationMode.wrappedValue.dismiss()
                                }
                            }) {
                                HStack {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 18))
                                        .foregroundColor(.red)
                                        .frame(width: 30)
                                    
                                    Text("Clear Selection")
                                        .font(.system(size: 17, design: .rounded))
                                        .foregroundColor(.red)
                                    
                                    Spacer()
                                }
                                .padding(.vertical, 6)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
            }
            .navigationTitle("Select Habit")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}
