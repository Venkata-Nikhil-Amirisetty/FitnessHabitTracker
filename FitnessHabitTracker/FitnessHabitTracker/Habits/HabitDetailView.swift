//
//  HabitDetailView.swift
//  FitnessHabitTracker
//
//  Created by Nikhil Av on 4/16/25.
//


import SwiftUI
import SwiftData
import Charts

struct HabitDetailView: View {
    var habit: Habit
    @EnvironmentObject var habitViewModel: HabitViewModel
    @EnvironmentObject var goalViewModel: GoalViewModel  // Add GoalViewModel
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    @State private var showingWeatherPreferencesSheet = false
    @State private var showingGoalSheet = false  // NEW: For goal creation
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack {
                    VStack(alignment: .leading) {
                        Text(habit.name)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        HStack {
                            Image(systemName: habit.category.icon)
                                .foregroundColor(.gray)
                            
                            Text(habit.category.rawValue.capitalized)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        habitViewModel.toggleHabitCompletion(habit)
                    }) {
                        let isCompletedToday = isHabitCompletedToday(habit)
                        Image(systemName: isCompletedToday ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 40))
                            .foregroundColor(isCompletedToday ? .green : .gray)
                    }
                }
                .padding()
                
                // Enhanced Streak Visualization
                if habit.currentStreak > 0 {
                    AnimatedStreakView(streakCount: habit.currentStreak)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(15)
                        .padding(.horizontal)
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "flame")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                        
                        Text("No Active Streak")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        Text("Complete this habit today to start your streak!")
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(15)
                    .padding(.horizontal)
                }
                
                // Weather section for weather-sensitive habits
                if habit.isWeatherSensitive {
                    WeatherRecommendationView(
                        habit: habit,
                        weatherViewModel: habitViewModel.weatherViewModel
                    )
                    .padding(.horizontal)
                }
                
                // Description
                if let description = habit.descriptionText, !description.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.headline)
                            .foregroundColor(.primary)

                        Text(description)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.leading)
                            .lineLimit(nil)
                            .padding(.top, 2)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGray6))
                    .cornerRadius(15)
                    .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
                    .padding(.horizontal)
                }
                
                // NEW: Linked Goals Section
                linkedGoalsSection
                
                // Details
                VStack(alignment: .leading, spacing: 15) {
                    Text("Details")
                        .font(.headline)
                        .padding(.bottom, 5)
                    
                    DetailRow(title: "Frequency", value: frequencyText(habit))
                    
                    if let reminderTime = habit.reminderTime {
                        DetailRow(title: "Reminder", value: formatTime(reminderTime))
                    }
                    
                    DetailRow(title: "Started", value: formatDate(habit.startDate))
                    
                    // Weather preference indicator
                    if habit.isWeatherSensitive {
                        DetailRow(
                            title: "Weather Sensitive",
                            value: "Yes"
                        )
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(15)
                .padding(.horizontal)
                
                // Calendar view of completions
                VStack(alignment: .leading, spacing: 10) {
                    Text("Completion History")
                        .font(.headline)
                    
                    CompletionCalendarView(completedDates: habit.completedDates)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(15)
                .padding(.horizontal)
                
                // Action buttons
                VStack(spacing: 15) {
                    Button(action: {
                        showingEditSheet = true
                    }) {
                        HStack {
                            Image(systemName: "pencil")
                            Text("Edit Habit")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    
                    Button(action: {
                        showingWeatherPreferencesSheet = true
                    }) {
                        HStack {
                            Image(systemName: "cloud.sun")
                            Text("Weather Preferences")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    
                    // NEW: Create Goal Button
                    if !hasLinkedGoal() {
                        Button(action: {
                            showingGoalSheet = true
                        }) {
                            HStack {
                                Image(systemName: "target")
                                Text("Create Goal")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                    }
                    
                    NavigationLink(destination: HabitStatsView(habit: habit)) {
                        HStack {
                            Image(systemName: "chart.bar")
                            Text("View Statistics")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    
                    Button(action: {
                        showingDeleteAlert = true
                    }) {
                        HStack {
                            Image(systemName: "trash")
                            Text("Delete Habit")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .foregroundColor(.red)
                        .cornerRadius(10)
                    }
                }
                .padding()
            }
            .padding(.vertical)
        }
        .navigationTitle("Habit Details")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingEditSheet) {
            NavigationView {
                HabitEditView(habit: habit, isPresented: $showingEditSheet)
                    .environmentObject(habitViewModel)
                    .navigationTitle("Edit Habit")
                    .navigationBarItems(leading: Button("Cancel") {
                        showingEditSheet = false
                    })
            }
        }
        .sheet(isPresented: $showingWeatherPreferencesSheet) {
            NavigationView {
                WeatherPreferencesView(habit: habit, isPresented: $showingWeatherPreferencesSheet)
                    .environmentObject(habitViewModel)
                    .navigationTitle("Weather Preferences")
                    .navigationBarItems(leading: Button("Cancel") {
                        showingWeatherPreferencesSheet = false
                    })
            }
        }
        // Sheet for creating goals
        .sheet(isPresented: $showingGoalSheet) {
            NavigationView {
                SuggestedGoalsView(
                    isPresented: $showingGoalSheet,
                    parentPresented: $showingGoalSheet,
                    specificHabit: habit
                )
                .environmentObject(goalViewModel)
                .environmentObject(habitViewModel)
            }
        }
        .alert(isPresented: $showingDeleteAlert) {
            Alert(
                title: Text("Delete Habit"),
                message: Text("Are you sure you want to delete this habit? This action cannot be undone."),
                primaryButton: .destructive(Text("Delete")) {
                    habitViewModel.deleteHabit(habit)
                },
                secondaryButton: .cancel()
            )
        }
        .onAppear {
            // No need to load weather preferences explicitly since they're stored as computed props
        }
    }
    
    // MARK: - NEW Linked Goals Section
    
    private var linkedGoalsSection: some View {
        VStack(alignment: .leading) {
            let linkedGoals = goalViewModel.activeGoals.filter { $0.isLinkedToHabit(habit) }
            
            if !linkedGoals.isEmpty {
                Text("Linked Goals")
                    .font(.headline)
                    .padding(.horizontal)
                
                VStack(spacing: 12) {
                    ForEach(linkedGoals, id: \.id) { goal in
                        NavigationLink(destination: GoalDetailView(goal: goal)) {
                            HStack {
                                Image(systemName: goal.type.icon)
                                    .foregroundColor(.white)
                                    .padding(8)
                                    .background(getGoalTypeColor(goal.type))
                                    .cornerRadius(8)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(goal.title)
                                        .font(.headline)
                                    
                                    if goal.type == .streak {
                                        Text("Current streak: \(habit.currentStreak)/\(Int(goal.targetValue))")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    } else {
                                        Text("Progress: \(Int(goal.currentValue))/\(Int(goal.targetValue))")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                Spacer()
                                
                                CircularProgressView(progress: goal.progress)
                                    .frame(width: 40, height: 40)
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(12)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func isHabitCompletedToday(_ habit: Habit) -> Bool {
        let today = Calendar.current.startOfDay(for: Date())
        return habit.completedDates.contains(where: { Calendar.current.isDate($0, inSameDayAs: today) })
    }
    
    private func frequencyText(_ habit: Habit) -> String {
        switch habit.frequency {
        case .daily:
            return "Every day"
        case .weekdays:
            return "Weekdays (Mon-Fri)"
        case .weekends:
            return "Weekends (Sat-Sun)"
        case .custom:
            return "\(habit.targetDaysPerWeek) days per week"
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    // NEW: Goal-related helper methods
    
    private func hasLinkedGoal() -> Bool {
        return goalViewModel.activeGoals.contains { $0.isLinkedToHabit(habit) }
    }
    
    private func getGoalTypeColor(_ type: GoalType) -> Color {
        switch type {
        case .workout: return .blue
        case .habit: return .green
        case .distance: return .orange
        case .duration: return .purple
        case .streak: return .red
        case .weight: return .gray
        }
    }
}

// MARK: - AnimatedStreakView

struct AnimatedStreakView: View {
    var streakCount: Int
    @State private var animateFlame = false
    @State private var pulseScale = false
    @State private var confetti: [ConfettiPiece] = []
    @State private var showConfetti = false
    
    let colors: [Color] = [.red, .blue, .green, .yellow, .pink, .purple, .orange]
    
    var body: some View {
        VStack(spacing: 15) {
            // Milestone badge (if applicable)
            if let milestone = getMilestoneText() {
                Text(milestone)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(streakColor.opacity(0.2))
                    .foregroundColor(streakColor)
                    .cornerRadius(12)
            }
            
            // Flame visualization with counter
            ZStack {
                // Confetti layer
                if showConfetti {
                    ZStack {
                        ForEach(confetti) { piece in
                            ConfettiPieceView(piece: piece, isActive: showConfetti)
                        }
                    }
                }
                
                // Base flame
                Image(systemName: "flame.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundColor(streakColor)
                    .frame(width: baseSize, height: baseSize)
                    .scaleEffect(animateFlame ? 1.1 : 1.0)
                    .shadow(color: streakColor.opacity(0.5), radius: 10, x: 0, y: 5)
                
                // Secondary flames for higher streaks
                if streakCount >= 7 {
                    Image(systemName: "flame.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .foregroundColor(streakColor.opacity(0.7))
                        .offset(x: -10, y: -5)
                        .frame(width: baseSize * 0.7, height: baseSize * 0.7)
                        .scaleEffect(animateFlame ? 1.2 : 0.9)
                        .shadow(color: streakColor.opacity(0.3), radius: 8, x: 0, y: 5)
                }
                
                if streakCount >= 14 {
                    Image(systemName: "flame.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .foregroundColor(streakColor.opacity(0.7))
                        .offset(x: 10, y: -5)
                        .frame(width: baseSize * 0.7, height: baseSize * 0.7)
                        .scaleEffect(animateFlame ? 0.9 : 1.2)
                        .shadow(color: streakColor.opacity(0.3), radius: 8, x: 0, y: 5)
                }
                
                // Streak counter in circle
                Circle()
                    .fill(Color.white)
                    .frame(width: counterSize)
                    .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
                    .overlay(
                        Text("\(streakCount)")
                            .font(.system(size: fontSize, weight: .bold))
                            .foregroundColor(streakColor)
                    )
                    .scaleEffect(pulseScale ? 1.05 : 1.0)
            }
            .frame(width: containerSize, height: containerSize)
            .onAppear {
                withAnimation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    animateFlame = true
                }
                withAnimation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    pulseScale = true
                }
            }
            
            Text("Day Streak")
                .font(.headline)
                .foregroundColor(.gray)
                
            // Streak meta info
            HStack(spacing: 25) {
                VStack {
                    Text("Started")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(getStreakStartDate())
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                VStack {
                    Text("Category")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 4) {
                        if streakCount < 7 {
                            Text("Beginner")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        } else if streakCount < 21 {
                            Text("Regular")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        } else if streakCount < 60 {
                            Text("Dedicated")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        } else {
                            Text("Master")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
        .onAppear {
            // Generate confetti if it's a milestone
            if isMilestone(streakCount) {
                for _ in 0..<100 {
                    confetti.append(ConfettiPiece(
                        position: CGPoint(
                            x: CGFloat.random(in: -100...100),
                            y: CGFloat.random(in: -20...20)
                        ),
                        size: CGFloat.random(in: 4...8),
                        color: colors.randomElement() ?? .blue,
                        rotation: Double.random(in: 0...360),
                        velocity: CGVector(
                            dx: CGFloat.random(in: -100...100),
                            dy: CGFloat.random(in: 400...600)
                        )
                    ))
                }
                
                // Show confetti with a slight delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showConfetti = true
                }
            }
        }
    }
    
    // Helper methods
    
    // Dynamic sizing based on streak count
    private var baseSize: CGFloat {
        let baseValue: CGFloat = 60
        let growth = min(CGFloat(streakCount) * 0.8, 40)
        return baseValue + growth
    }
    
    private var containerSize: CGFloat {
        return baseSize * 1.5
    }
    
    private var counterSize: CGFloat {
        return baseSize * 0.7
    }
    
    private var fontSize: CGFloat {
        return min(20 + CGFloat(streakCount/10), 32)
    }
    
    // Dynamic color based on streak length
    private var streakColor: Color {
        switch streakCount {
        case 0...6:
            return .orange
        case 7...13:
            return Color(red: 1.0, green: 0.6, blue: 0.0)
        case 14...20:
            return Color(red: 1.0, green: 0.4, blue: 0.0)
        case 21...59:
            return Color(red: 1.0, green: 0.2, blue: 0.0)
        default:
            return Color(red: 0.8, green: 0.0, blue: 0.3)
        }
    }
    
    // Optional milestone text
    private func getMilestoneText() -> String? {
        switch streakCount {
        case 1:
            return "First day! 🌱"
        case 3:
            return "3 Day Momentum! 🌿"
        case 7:
            return "One Week Streak! 🔥"
        case 14:
            return "Two Weeks Strong! 💪"
        case 21:
            return "21 Days - Habit Formed! ⭐️"
        case 30:
            return "30 Day Challenge Complete! 🏆"
        case 60:
            return "60 Days - Dedication Level: Expert! 🌟"
        case 100:
            return "100 Days! You're Unstoppable! 💯"
        case _ where streakCount > 0 && streakCount % 50 == 0:
            return "\(streakCount) Days! Incredible Milestone! 🎯"
        default:
            return nil
        }
    }
    
    private func isMilestone(_ streak: Int) -> Bool {
        return streak == 1 || streak == 3 || streak == 7 || streak == 14 ||
               streak == 21 || streak == 30 || streak == 60 || streak == 100 ||
               (streak > 0 && streak % 50 == 0)
    }
    
    private func getStreakStartDate() -> String {
        let calendar = Calendar.current
        // Calculate the start date based on streak
        let startDate = calendar.date(byAdding: .day, value: -(streakCount - 1), to: Date()) ?? Date()
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: startDate)
    }
}

// MARK: - ConfettiPiece and View

struct ConfettiPiece: Identifiable {
    let id = UUID()
    var position: CGPoint
    var size: CGFloat
    var color: Color
    var rotation: Double
    var velocity: CGVector
}

struct ConfettiPieceView: View {
    let piece: ConfettiPiece
    var isActive: Bool
    
    var body: some View {
        Rectangle()
            .fill(piece.color)
            .frame(width: piece.size, height: piece.size * 2.5)
            .position(
                x: piece.position.x + (isActive ? piece.velocity.dx * 0.2 : 0),
                y: piece.position.y + (isActive ? piece.velocity.dy * 0.2 : 0)
            )
            .rotationEffect(.degrees(piece.rotation + (isActive ? Double.random(in: 180...360) : 0)))
            .opacity(isActive ? 0 : 1)
            .animation(.easeOut(duration: 2.0), value: isActive)
    }
}

// MARK: - CircularProgressView

struct CircularProgressView: View {
    var progress: Double
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 4)
                .frame(width: 40, height: 40)
            
            Circle()
                .trim(from: 0, to: CGFloat(min(progress, 1.0)))
                .stroke(progress >= 1.0 ? Color.green : Color.blue, lineWidth: 4)
                .frame(width: 40, height: 40)
                .rotationEffect(.degrees(-90))
                // Make sure the animation properly updates
                .animation(.easeOut, value: progress)
            
            Text("\(Int(progress * 100))%")
                .font(.system(size: 10))
                .fontWeight(.bold)
        }
    }
}

// Keep existing component definitions
struct CompletionCalendarView: View {
    var completedDates: [Date]
    
    var body: some View {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let days = 30 // Show last 30 days
        
        VStack(alignment: .leading, spacing: 15) {
            // Days of week header
            HStack {
                ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .frame(maxWidth: .infinity)
                }
            }
            
            // Calendar grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach((0..<days).reversed(), id: \.self) { dayOffset in
                    if let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) {
                        let isCompleted = completedDates.contains(where: { calendar.isDate($0, inSameDayAs: date) })
                        
                        ZStack {
                            Circle()
                                .fill(isCompleted ? Color.green : Color.gray.opacity(0.2))
                                .frame(width: 30, height: 30)
                            
                            Text("\(calendar.component(.day, from: date))")
                                .font(.caption)
                                .foregroundColor(isCompleted ? .white : .primary)
                        }
                    }
                }
            }
        }
    }
}

struct DetailRow: View {
    var title: String
    var value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.gray)
            
            Spacer()
            
            Text(value)
                .fontWeight(.medium)
        }
    }
}

struct HabitEditView: View {
    var habit: Habit
    @Binding var isPresented: Bool
    @EnvironmentObject var habitViewModel: HabitViewModel
    
    @State private var name: String
    @State private var description: String
    @State private var category: HabitCategory
    @State private var frequency: HabitFrequency
    @State private var targetDaysPerWeek: Int
    @State private var enableReminder: Bool
    @State private var reminderTime: Date
    @State private var showingDeleteAlert = false
    
    init(habit: Habit, isPresented: Binding<Bool>) {
        self.habit = habit
        self._isPresented = isPresented
        
        // Initialize state variables with habit values
        self._name = State(initialValue: habit.name)
        self._description = State(initialValue: habit.descriptionText ?? "")
        self._category = State(initialValue: habit.category)
        self._frequency = State(initialValue: habit.frequency)
        self._targetDaysPerWeek = State(initialValue: habit.targetDaysPerWeek)
        self._enableReminder = State(initialValue: habit.reminderTime != nil)
        self._reminderTime = State(initialValue: habit.reminderTime ?? Date())
    }
    
    var body: some View {
        Form {
            Section(header: Text("Habit Details")) {
                TextField("Habit Name", text: $name)
                
                TextField("Description (Optional)", text: $description)
                
                Picker("Category", selection: $category) {
                    ForEach(HabitCategory.allCases, id: \.self) { category in
                        HStack {
                            Image(systemName: category.icon)
                            Text(category.rawValue.capitalized)
                        }
                        .tag(category)
                    }
                }
            }
            
            Section(header: Text("Frequency")) {
                Picker("Repeat", selection: $frequency) {
                    Text("Daily").tag(HabitFrequency.daily)
                    Text("Weekdays").tag(HabitFrequency.weekdays)
                    Text("Weekends").tag(HabitFrequency.weekends)
                    Text("Custom").tag(HabitFrequency.custom)
                }
                
                if frequency == .custom {
                    Stepper(value: $targetDaysPerWeek, in: 1...7) {
                        Text("Target: \(targetDaysPerWeek) days per week")
                    }
                }
            }
            
            Section(header: Text("Reminder")) {
                Toggle("Enable Reminder", isOn: $enableReminder)
                
                if enableReminder {
                    DatePicker("Time", selection: $reminderTime, displayedComponents: .hourAndMinute)
                }
            }
            
            Section {
                Button(action: saveHabit) {
                    Text("Save Changes")
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(10)
                }
                .buttonStyle(PlainButtonStyle())
                .listRowInsets(EdgeInsets())
            }
            
            Section {
                Button(action: {
                    showingDeleteAlert = true
                }) {
                    HStack {
                        Spacer()
                        Text("Delete Habit")
                            .foregroundColor(.red)
                        Spacer()
                    }
                }
            }
        }
        .alert(isPresented: $showingDeleteAlert) {
            Alert(
                title: Text("Delete Habit"),
                message: Text("Are you sure you want to delete this habit? This action cannot be undone."),
                primaryButton: .destructive(Text("Delete")) {
                    habitViewModel.deleteHabit(habit)
                    isPresented = false
                },
                secondaryButton: .cancel()
            )
        }
    }
    
    private func saveHabit() {
        // Update the habit object with the new values
        habit.name = name
        habit.descriptionText = description.isEmpty ? nil : description
        habit.category = category
        habit.frequency = frequency
        habit.targetDaysPerWeek = targetDaysPerWeek
        habit.reminderTime = enableReminder ? reminderTime : nil
        
        // Save changes
        habitViewModel.updateHabit(habit)
        
        // Update reminder notification if needed
        if enableReminder {
            NotificationManager.shared.scheduleHabitReminder(for: habit) { success in
                print("Reminder \(success ? "scheduled" : "failed to schedule")")
            }
        } else {
            NotificationManager.shared.cancelHabitReminder(habitId: habit.id)
        }
        
        isPresented = false
    }
}
