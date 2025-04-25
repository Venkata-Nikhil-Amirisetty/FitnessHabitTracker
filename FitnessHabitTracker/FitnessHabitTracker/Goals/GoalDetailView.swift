//
//  GoalDetailView.swift
//  FitnessHabitTracker
//
//  Created by Nikhil Av on 4/21/25.
//

import SwiftUI

struct GoalDetailView: View {
    var goal: Goal
    @EnvironmentObject var goalViewModel: GoalViewModel
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    @Environment(\.presentationMode) var presentationMode
    
    
    // Animation states
    @State private var isAnimating = false
    @State private var showContent = false
    @State private var progressTrimEnd: CGFloat = 0
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [Color(getGoalColor()).opacity(0.1), Color.white]),
                startPoint: .top,
                endPoint: .bottom
            )
            .edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header with animated progress circle
                    VStack(alignment: .center, spacing: 20) {
                        // Progress Circle with animation
                        ZStack {
                            // Background circle
                            Circle()
                                .stroke(Color.gray.opacity(0.2), lineWidth: 15)
                                .frame(width: 150, height: 150)
                                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                            
                            // Animated progress circle
                            Circle()
                                .trim(from: 0, to: progressTrimEnd)
                                .stroke(
                                    LinearGradient(
                                        gradient: Gradient(colors: [getGoalColor(), getGoalColor().opacity(0.7)]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ),
                                    style: StrokeStyle(lineWidth: 15, lineCap: .round)
                                )
                                .frame(width: 150, height: 150)
                                .rotationEffect(.degrees(-90))
                                .shadow(color: getGoalColor().opacity(0.3), radius: 3, x: 0, y: 0)
                                .animation(.spring(response: 1.5), value: progressTrimEnd)
                            
                            // Inner content with numbers
                            VStack(spacing: 5) {
                                Text("\(Int(goal.currentValue))")
                                    .font(.system(size: 44, weight: .bold, design: .rounded))
                                    .foregroundColor(getGoalColor())
                                    .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
                                    .scaleEffect(isAnimating ? 1.0 : 0.8)
                                    .animation(.spring(response: 0.6), value: isAnimating)
                                
                                Text("of \(Int(goal.targetValue))")
                                    .font(.system(size: 18, weight: .medium, design: .rounded))
                                    .foregroundColor(.secondary)
                                    .opacity(isAnimating ? 1.0 : 0.0)
                                    .animation(.easeIn(duration: 0.4).delay(0.3), value: isAnimating)
                            }
                        }
                        .padding(.top, 20)
                        
                        // Goal Title and Status
                        VStack(alignment: .center, spacing: 12) {
                            Text(goal.title)
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .multilineTextAlignment(.center)
                                .opacity(isAnimating ? 1.0 : 0.0)
                                .offset(y: isAnimating ? 0 : 20)
                                .animation(.easeOut(duration: 0.5).delay(0.2), value: isAnimating)
                            
                            Text(goal.type.displayName)
                                .font(.system(size: 18, weight: .medium, design: .rounded))
                                .foregroundColor(.secondary)
                                .opacity(isAnimating ? 1.0 : 0.0)
                                .animation(.easeIn(duration: 0.4).delay(0.3), value: isAnimating)
                            
                            StatusBadge(status: goal.status)
                                .padding(.top, 5)
                                .scaleEffect(isAnimating ? 1.0 : 0.8)
                                .opacity(isAnimating ? 1.0 : 0.0)
                                .animation(.spring(response: 0.5).delay(0.4), value: isAnimating)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 30)
                    .background(
                        RoundedRectangle(cornerRadius: 25)
                            .fill(Color.white)
                            .shadow(color: Color.black.opacity(0.1), radius: 15, x: 0, y: 5)
                    )
                    .padding(.horizontal)
                    .opacity(showContent ? 1.0 : 0.0)
                    .offset(y: showContent ? 0 : 30)
                    .animation(.easeOut(duration: 0.6), value: showContent)
                    
                    // Timeframe info with card design
                    InfoCard(title: "Timeframe", icon: "calendar") {
                        VStack(spacing: 15) {
                            GoalInfoRow(label: "Started", value: formatDate(goal.startDate), icon: "play.circle.fill")
                            GoalInfoRow(label: "Ends", value: formatDate(goal.endDate), icon: "flag.circle.fill")
                            GoalInfoRow(label: "Duration", value: goal.timeframe.displayName, icon: "clock.fill")
                            
                            if goal.status == .active {
                                GoalInfoRow(
                                    label: "Remaining",
                                    value: "\(goal.remainingDays) days",
                                    icon: "hourglass.circle.fill",
                                    highlight: goal.remainingDays < 3
                                )
                            }
                        }
                    }
                    .opacity(showContent ? 1.0 : 0.0)
                    .offset(y: showContent ? 0 : 30)
                    .animation(.easeOut(duration: 0.6).delay(0.1), value: showContent)
                    
                    // Linked items with card design
                    if goal.linkedWorkoutType != nil || goal.linkedHabitId != nil {
                        InfoCard(title: "Linked Items", icon: "link.circle") {
                            VStack(spacing: 15) {
                                if let workoutType = goal.linkedWorkoutType {
                                    GoalInfoRow(
                                        label: "Workout Type",
                                        value: WorkoutType(rawValue: workoutType)?.rawValue.capitalized ?? "Unknown",
                                        icon: "figure.walk.circle.fill"
                                    )
                                }
                                
                                if let habitId = goal.linkedHabitId {
                                    GoalInfoRow(
                                        label: "Habit",
                                        value: getHabitName(habitId),
                                        icon: "repeat.circle.fill"
                                    )
                                }
                            }
                        }
                        .opacity(showContent ? 1.0 : 0.0)
                        .offset(y: showContent ? 0 : 30)
                        .animation(.easeOut(duration: 0.6).delay(0.2), value: showContent)
                    }
                    
                    // Notes if any with card design
                    if let notes = goal.notes, !notes.isEmpty {
                        InfoCard(title: "Notes", icon: "note.text") {
                            Text(notes)
                                .font(.system(size: 16, design: .rounded))
                                .foregroundColor(.secondary)
                                .lineSpacing(5)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .opacity(showContent ? 1.0 : 0.0)
                        .offset(y: showContent ? 0 : 30)
                        .animation(.easeOut(duration: 0.6).delay(0.3), value: showContent)
                    }
                    
                    // Action buttons with improved design
                    VStack(spacing: 15) {
                        // Show different actions based on goal status
                        if goal.status == .active {
                            Button(action: {
                                withAnimation(.spring(response: 0.6)) {
                                    updateProgress()
                                }
                            }) {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 20))
                                    Text("Add Progress")
                                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [getGoalColor(), getGoalColor().opacity(0.8)]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .foregroundColor(.white)
                                .cornerRadius(16)
                                .shadow(color: getGoalColor().opacity(0.4), radius: 10, x: 0, y: 5)
                            }
                            .buttonStyle(SpringButtonStyle())
                            
                            Button(action: {
                                showingEditSheet = true
                            }) {
                                HStack {
                                    Image(systemName: "pencil.circle.fill")
                                        .font(.system(size: 20))
                                    Text("Edit Goal")
                                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.black.opacity(0.05))
                                .foregroundColor(.primary)
                                .cornerRadius(16)
                            }
                            .buttonStyle(SpringButtonStyle())
                        } else {
                            Button(action: {
                                goal.status = .archived
                                goalViewModel.updateGoal(goal)
                                presentationMode.wrappedValue.dismiss()
                            }) {
                                HStack {
                                    Image(systemName: "archivebox.circle.fill")
                                        .font(.system(size: 20))
                                    Text("Archive Goal")
                                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(16)
                            }
                            .buttonStyle(SpringButtonStyle())
                        }
                        
                        Button(action: {
                            showingDeleteAlert = true
                        }) {
                            HStack {
                                Image(systemName: "trash.circle.fill")
                                    .font(.system(size: 20))
                                Text("Delete Goal")
                                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.red.opacity(0.1))
                            .foregroundColor(.red)
                            .cornerRadius(16)
                        }
                        .buttonStyle(SpringButtonStyle())
                    }
                    .padding(.horizontal)
                    .opacity(showContent ? 1.0 : 0.0)
                    .animation(.easeOut(duration: 0.6).delay(0.4), value: showContent)
                }
                .padding(.vertical, 20)
            }
        }
        .navigationTitle("Goal Details")
        .navigationBarTitleDisplayMode(.inline)
        .alert(isPresented: $showingDeleteAlert) {
            Alert(
                title: Text("Delete Goal"),
                message: Text("Are you sure you want to delete this goal? This cannot be undone."),
                primaryButton: .destructive(Text("Delete")) {
                    goalViewModel.deleteGoal(goal)
                    presentationMode.wrappedValue.dismiss()
                },
                secondaryButton: .cancel()
            )
        }
        .sheet(isPresented: $showingEditSheet) {
            NavigationView {
                GoalEditFormView(goal: goal, isPresented: $showingEditSheet)
                    .environmentObject(goalViewModel)
            }
        }
        .onAppear {
            // Start animations when view appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation {
                    progressTrimEnd = CGFloat(goal.progress)
                    isAnimating = true
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    withAnimation {
                        showContent = true
                    }
                }
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    private func getGoalColor() -> Color {
        switch goal.type {
        case .workout: return .blue
        case .habit: return .green
        case .distance: return .orange
        case .duration: return .purple
        case .streak: return .red
        case .weight: return .gray
        }
    }
    
    private func getHabitName(_ habitId: String) -> String {
        // Get habit name from the habit view model
        let habitViewModel = HabitViewModel()
        return habitViewModel.habits.first(where: { $0.id == habitId })?.name ?? "Unknown Habit"
    }
    
    private func updateProgress() {
        // Manually increment progress with animation
        withAnimation(.spring(response: 0.6)) {
            goal.incrementProgress()
            progressTrimEnd = CGFloat(goal.progress)
            goalViewModel.updateGoal(goal)
        }
    }
}

// Custom card component for info sections - FIXED to show proper chevron direction
struct InfoCard<Content: View>: View {
    var title: String
    var icon: String
    @ViewBuilder var content: Content
    @State private var isExpanded = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            // Card header with toggle
            Button(action: {
                withAnimation(.spring(response: 0.5)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text(title)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                    
                    Spacer()
                    
                    // FIXED: Now shows down chevron when collapsed, up chevron when expanded
                    Image(systemName: isExpanded ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                        .foregroundColor(.gray)
                        .font(.system(size: 18))
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            // Card content
            if isExpanded {
                content
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 5)
        )
        .padding(.horizontal)
    }
}

// Improved info row with icons
struct GoalInfoRow: View {
    var label: String
    var value: String
    var icon: String? = nil
    var highlight: Bool = false
    
    var body: some View {
        HStack(spacing: 12) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(highlight ? .red.opacity(0.8) : .gray.opacity(0.6))
                    .frame(width: 24)
            }
            
            Text(label)
                .font(.system(size: 16, design: .rounded))
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(highlight ? .red : .primary)
        }
    }
}

// Status badge with shadow and gradient
struct StatusBadge: View {
    var status: GoalStatus
    
    var body: some View {
        Text(status.rawValue.capitalized)
            .font(.system(size: 14, weight: .bold, design: .rounded))
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [getBadgeColor(), getBadgeColor().opacity(0.7)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .foregroundColor(.white)
            .cornerRadius(12)
            .shadow(color: getBadgeColor().opacity(0.3), radius: 3, x: 0, y: 2)
    }
    
    private func getBadgeColor() -> Color {
        switch status {
        case .active: return .blue
        case .completed: return .green
        case .failed: return .red
        case .archived: return .gray
        }
    }
}

// Custom button style with spring animation
struct SpringButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.spring(response: 0.3), value: configuration.isPressed)
    }
}

// Form enhancement
struct GoalEditFormView: View {
    var goal: Goal
    @EnvironmentObject var goalViewModel: GoalViewModel
    @Binding var isPresented: Bool
    
    // Form state variables
    @State private var title: String
    @State private var targetValue: String
    @State private var notes: String
    @State private var endDate: Date
    
    // Validation
    @State private var showingValidationAlert = false
    @State private var validationMessage = ""
    
    // Initialize with the goal's values
    init(goal: Goal, isPresented: Binding<Bool>) {
        self.goal = goal
        self._isPresented = isPresented
        
        // Initialize state with goal's current values
        self._title = State(initialValue: goal.title)
        self._targetValue = State(initialValue: String(Int(goal.targetValue)))
        self._notes = State(initialValue: goal.notes ?? "")
        self._endDate = State(initialValue: goal.endDate)
    }
    
    var body: some View {
        ZStack {
            // Form background
            Color(UIColor.systemGroupedBackground)
                .edgesIgnoringSafeArea(.all)
            
            Form {
                Section(header: Text("Goal Details").font(.system(size: 16, weight: .semibold, design: .rounded))) {
                    HStack {
                        Image(systemName: "target")
                            .foregroundColor(getGoalColor())
                            .font(.system(size: 18))
                        TextField("Goal Title", text: $title)
                            .font(.system(size: 17, design: .rounded))
                    }
                    
                    HStack {
                        Image(systemName: "number.circle")
                            .foregroundColor(getGoalColor())
                            .font(.system(size: 18))
                        
                        Text("Target Value")
                            .font(.system(size: 17, design: .rounded))
                        
                        Spacer()
                        
                        TextField("0", text: $targetValue)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                            .font(.system(size: 17, weight: .medium, design: .rounded))
                        
                        Text(getUnitLabel())
                            .foregroundColor(.secondary)
                            .font(.system(size: 15, design: .rounded))
                    }
                    
                    if goal.timeframe == .custom {
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(getGoalColor())
                                .font(.system(size: 18))
                            
                            DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                                .font(.system(size: 17, design: .rounded))
                        }
                    }
                }
                
                Section(header: Text("Notes (Optional)").font(.system(size: 16, weight: .semibold, design: .rounded))) {
                    HStack(alignment: .top) {
                        Image(systemName: "note.text")
                            .foregroundColor(getGoalColor())
                            .font(.system(size: 18))
                            .padding(.top, 5)
                        
                        TextEditor(text: $notes)
                            .frame(height: 120)
                            .font(.system(size: 17, design: .rounded))
                    }
                }
                
                Section {
                    Button(action: saveGoal) {
                        HStack {
                            Spacer()
                            Text("Save Changes")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                            Spacer()
                        }
                        .padding(.vertical, 5)
                    }
                    .listRowBackground(getGoalColor().opacity(0.15))
                }
            }
        }
        .navigationTitle("Edit Goal")
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
        
        // Update goal properties
        goal.title = title
        goal.targetValue = targetDouble
        goal.endDate = endDate
        goal.notes = notes.isEmpty ? nil : notes
        
        // Save changes
        goalViewModel.updateGoal(goal)
        
        // Close the form
        isPresented = false
    }
    
    private func getUnitLabel() -> String {
        switch goal.type {
        case .workout: return "workouts"
        case .habit: return "completions"
        case .distance: return "kilometers"
        case .duration: return "minutes"
        case .streak: return "days"
        case .weight: return "kilograms"
        }
    }
    
    private func getGoalColor() -> Color {
        switch goal.type {
        case .workout: return .blue
        case .habit: return .green
        case .distance: return .orange
        case .duration: return .purple
        case .streak: return .red
        case .weight: return .gray
        }
    }
}
