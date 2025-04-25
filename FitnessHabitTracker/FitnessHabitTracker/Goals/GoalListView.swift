// Fix for tab bar oscillation issue

// Complete fix for tab bar oscillation issue using a different approach

import SwiftUI
import SwiftData

struct GoalListView: View {
    @EnvironmentObject var goalViewModel: GoalViewModel
    @EnvironmentObject var workoutViewModel: WorkoutViewModel
    @EnvironmentObject var habitViewModel: HabitViewModel
    
    @State private var showingAddGoal = false
    @State private var selectedTab = 0
    @State private var animateItems = false
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with enhanced styling
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Your Goals")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(getSubtitleText())
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .opacity(animateItems ? 1 : 0)
                }
                
                Spacer()
                
                Button(action: {
                    showingAddGoal = true
                }) {
                    Image(systemName: "plus")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(10)
                        .background(
                            Circle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.green, Color.blue]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: Color.blue.opacity(0.3), radius: 4, x: 0, y: 2)
                        )
                }
                .scaleEffect(animateItems ? 1.0 : 0.9)
            }
            .padding(.horizontal)
            .padding(.top)
            
            // COMPLETELY REVAMPED TAB BAR - Fixed version
            // This approach uses fixed heights and disables transitions completely
            ZStack(alignment: .top) {
                // Background and separator
                VStack(spacing: 0) {
                    Color.clear
                        .frame(height: 44) // Fixed height for tab bar
                    
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 1)
                }
                
                // Tab buttons - Using a fixed layout approach
                HStack(spacing: 0) {
                    // Active Tab
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedTab = 0
                        }
                    }) {
                        VStack(spacing: 8) {
                            Text("Active")
                                .font(.headline)
                                .foregroundColor(selectedTab == 0 ? .primary : .secondary)
                                .frame(maxWidth: .infinity)
                            
                            // Fixed size indicator that doesn't use transitions
                            Rectangle()
                                .fill(selectedTab == 0 ? Color.blue : Color.clear)
                                .frame(width: 30, height: 3)
                        }
                        .frame(height: 44) // Fixed height
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Completed Tab
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedTab = 1
                        }
                    }) {
                        VStack(spacing: 8) {
                            Text("Completed")
                                .font(.headline)
                                .foregroundColor(selectedTab == 1 ? .primary : .secondary)
                                .frame(maxWidth: .infinity)
                            
                            // Fixed size indicator that doesn't use transitions
                            Rectangle()
                                .fill(selectedTab == 1 ? Color.green : Color.clear)
                                .frame(width: 30, height: 3)
                        }
                        .frame(height: 44) // Fixed height
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .frame(height: 45) // Fixed height for entire tab container
            .padding(.top, 4)
            
            // Content based on selected tab - with animation only applied to content
            TabView(selection: $selectedTab) {
                // ACTIVE GOALS TAB
                Group {
                    if goalViewModel.activeGoals.isEmpty {
                        EnhancedEmptyGoalsView(isActive: true) {
                            showingAddGoal = true
                        }
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(Array(goalViewModel.activeGoals.enumerated()), id: \.element.id) { index, goal in
                                    EnhancedGoalCard(goal: goal)
                                        .scaleEffect(animateItems ? 1.0 : 0.96)
                                        .opacity(animateItems ? 1.0 : 0)
                                        .animation(
                                            .spring(response: 0.5, dampingFraction: 0.8)
                                            .delay(Double(index) * 0.05),
                                            value: animateItems
                                        )
                                }
                            }
                            .padding()
                        }
                    }
                }
                .tag(0)
                
                // COMPLETED GOALS TAB
                Group {
                    if goalViewModel.completedGoals.isEmpty {
                        EnhancedEmptyGoalsView(isActive: false) {
                            selectedTab = 0
                            showingAddGoal = true
                        }
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(Array(goalViewModel.completedGoals.enumerated()), id: \.element.id) { index, goal in
                                    EnhancedCompletedGoalCard(goal: goal)
                                        .scaleEffect(animateItems ? 1.0 : 0.96)
                                        .opacity(animateItems ? 1.0 : 0)
                                        .animation(
                                            .spring(response: 0.5, dampingFraction: 0.8)
                                            .delay(Double(index) * 0.05),
                                            value: animateItems
                                        )
                                }
                            }
                            .padding()
                        }
                    }
                }
                .tag(1)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .animation(nil, value: selectedTab) // Disable animation for tab switching
        }
        .sheet(isPresented: $showingAddGoal) {
            GoalFormView(isPresented: $showingAddGoal)
                .environmentObject(goalViewModel)
                .environmentObject(workoutViewModel)
                .environmentObject(habitViewModel)
        }
        .onAppear {
            goalViewModel.loadGoals()
            // Animate items when view appears - but only once
            if !animateItems {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation {
                        animateItems = true
                    }
                }
            }
        }
        .onDisappear {
            // Only reset animation state when truly leaving the view
            if !presentationMode.wrappedValue.isPresented {
                animateItems = false
            }
        }
    }
    
    // Get appropriate subtitle text based on goals
    private func getSubtitleText() -> String {
        let activeCount = goalViewModel.activeGoals.count
        let completedCount = goalViewModel.completedGoals.count
        
        if activeCount > 0 && completedCount > 0 {
            return "\(activeCount) active and \(completedCount) completed goals"
        } else if activeCount > 0 {
            return "\(activeCount) active goals"
        } else if completedCount > 0 {
            return "\(completedCount) completed goals"
        } else {
            return "Set goals to track your fitness journey"
        }
    }
}


// MARK: - Enhanced Goal Card

struct EnhancedGoalCard: View {
    var goal: Goal
    @EnvironmentObject var goalViewModel: GoalViewModel
    @State private var showingDetail = false
    @State private var animateProgress = false
    
    var body: some View {
        Button(action: {
            showingDetail = true
        }) {
            VStack(alignment: .leading, spacing: 15) {
                // Header with icon and info
                HStack(alignment: .center) {
                    // Type icon with gradient background
                    ZStack {
                        Circle()
                            .fill(LinearGradient(
                                gradient: Gradient(colors: [getGoalColor(), getGoalColor().opacity(0.7)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 46, height: 46)
                            .shadow(color: getGoalColor().opacity(0.3), radius: 3, x: 0, y: 2)
                        
                        Image(systemName: goal.type.icon)
                            .font(.system(size: 22))
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(goal.title)
                            .font(.headline)
                            .lineLimit(1)
                            .foregroundColor(.primary)
                        
                        Text(goal.type.displayName)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.leading, 4)
                    
                    Spacer()
                    
                    // Status pill
                    HStack(spacing: 4) {
                        Image(systemName: getRemainingIcon())
                            .font(.system(size: 12))
                        
                        Text("\(goal.remainingDays)d left")
                            .font(.caption)
                            .bold()
                    }
                    .foregroundColor(getRemainingColor())
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(getRemainingColor().opacity(0.15))
                    .cornerRadius(12)
                }
                
                // Progress section
                VStack(alignment: .leading, spacing: 8) {
                    // Progress metrics with fraction and percentage
                    HStack {
                        Text("Progress")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        HStack(spacing: 4) {
                            Text("\(Int(goal.currentValue))/\(Int(goal.targetValue))")
                                .font(.callout)
                                .fontWeight(.medium)
                            
                            Text("(\(Int(goal.progress * 100))%)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Enhanced progress bar - FIX: Now with better percentage positioning
                    ZStack(alignment: .leading) {
                        // Background track
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.gray.opacity(0.15))
                            .frame(height: 12)
                        
                        // Progress fill
                        RoundedRectangle(cornerRadius: 6)
                            .fill(LinearGradient(
                            gradient: Gradient(colors: [getGoalColor(), getGoalColor().opacity(0.7)]),
                            startPoint: .leading,
                            endPoint: .trailing
                                ))
                                .frame(width: animateProgress ? (goal.progress > 0 ? CGFloat(goal.progress) * UIScreen.main.bounds.width * 0.8 : 0) : 0, height: 12)
                                .animation(.spring().delay(0.1), value: animateProgress)
                        
                        // Milestone indicators for streak and habit goals
                        if goal.type == .streak || goal.type == .habit {
                            HStack(spacing: 0) {
                                ForEach(getMilestones(), id: \.self) { milestone in
                                    let position = CGFloat(milestone) / CGFloat(goal.targetValue)
                                    if position <= 1.0 {
                                        Circle()
                                            .fill(Color.white)
                                            .frame(width: 5, height: 5)
                                            .opacity(0.8)
                                            .shadow(color: Color.black.opacity(0.2), radius: 1, x: 0, y: 1)
                                            .offset(x: position * UIScreen.main.bounds.width * 0.8 - 2.5)
                                    }
                                }
                            }
                        }
                    }
                }
                
                // Footer with linked items
                if let linkedType = goal.linkedWorkoutType, let workoutTypeName = WorkoutType(rawValue: linkedType)?.rawValue.capitalized {
                    HStack(spacing: 6) {
                        Image(systemName: "link")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        
                        Text("Linked to \(workoutTypeName) workouts")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 4)
                } else if let linkedHabitId = goal.linkedHabitId {
                    HStack(spacing: 6) {
                        Image(systemName: "link")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        
                        Text("Linked to habit")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 4)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(UIColor.secondarySystemBackground))
                    .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 3)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingDetail) {
            GoalDetailView(goal: goal)
                .environmentObject(goalViewModel)
        }
        .onAppear {
            // Animate progress when view appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation {
                    animateProgress = true
                }
            }
        }
    }
    
    // Helper methods
    
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
    
    private func getRemainingIcon() -> String {
        if goal.remainingDays <= 1 {
            return "exclamationmark.triangle.fill"
        } else if goal.remainingDays <= 3 {
            return "clock.fill"
        } else {
            return "calendar.badge.clock"
        }
    }
    
    private func getRemainingColor() -> Color {
        if goal.remainingDays <= 1 {
            return .red
        } else if goal.remainingDays <= 3 {
            return .orange
        } else if goal.remainingDays <= 7 {
            return .blue
        } else {
            return .green
        }
    }
    
    // Get milestone values (for streak and habit goals)
    private func getMilestones() -> [Int] {
        var milestones: [Int] = []
        
        if goal.type == .streak {
            if goal.targetValue >= 7 {
                milestones.append(7) // One week
            }
            if goal.targetValue >= 14 {
                milestones.append(14) // Two weeks
            }
            if goal.targetValue >= 21 {
                milestones.append(21) // Habit formation
            }
            if goal.targetValue >= 30 {
                milestones.append(30) // One month
            }
        } else if goal.type == .habit {
            // Add milestones at 25%, 50%, 75%
            milestones.append(Int(goal.targetValue * 0.25))
            milestones.append(Int(goal.targetValue * 0.5))
            milestones.append(Int(goal.targetValue * 0.75))
        }
        
        return milestones
    }
}

// MARK: - Enhanced Completed Goal Card

struct EnhancedCompletedGoalCard: View {
    var goal: Goal
    @EnvironmentObject var goalViewModel: GoalViewModel
    @State private var showingDetail = false
    @State private var appear = false
    
    var body: some View {
        Button(action: {
            showingDetail = true
        }) {
            HStack(spacing: 15) {
                // Status icon with decoration
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    goal.status == .completed ? Color.green : Color.orange,
                                    goal.status == .completed ? Color.green.opacity(0.7) : Color.orange.opacity(0.7)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 46, height: 46)
                        .shadow(color: (goal.status == .completed ? Color.green : Color.orange).opacity(0.3), radius: 3, x: 0, y: 2)
                    
                    Image(systemName: goal.status == .completed ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(goal.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                        
                        Text("\(formatDate(goal.lastUpdated))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(getGoalColor(goal.type))
                            .frame(width: 8, height: 8)
                        
                        Text(goal.type.displayName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Text("\(Int(goal.targetValue)) \(getUnitLabel(goal.type))")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.leading, 2)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(UIColor.secondarySystemBackground))
                    .shadow(color: Color.black.opacity(0.1), radius: 6, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingDetail) {
            GoalDetailView(goal: goal)
                .environmentObject(goalViewModel)
        }
    }
    
    // Helper methods
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    private func getGoalColor(_ type: GoalType) -> Color {
        switch type {
        case .workout: return .blue
        case .habit: return .green
        case .distance: return .orange
        case .duration: return .purple
        case .streak: return .red
        case .weight: return .gray
        }
    }
    
    private func getUnitLabel(_ type: GoalType) -> String {
        switch type {
        case .workout: return "workouts"
        case .habit: return "completions"
        case .distance: return "km"
        case .duration: return "minutes"
        case .streak: return "days"
        case .weight: return "kg"
        }
    }
}

// MARK: - Enhanced Empty State

struct EnhancedEmptyGoalsView: View {
    var isActive: Bool
    var addAction: () -> Void
    @State private var animatePulse = false
    
    var body: some View {
        VStack(spacing: 25) {
            // Animated target illustration
            ZStack {
                // Pulse circles
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .stroke(Color.blue.opacity(0.1), lineWidth: 3)
                        .frame(width: 80 + CGFloat(i * 20), height: 80 + CGFloat(i * 20))
                        .scaleEffect(animatePulse ? 1.1 : 0.9)
                        .opacity(animatePulse ? 0.4 - Double(i) * 0.1 : 0.7 - Double(i) * 0.2)
                }
                
                // Main icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.blue.opacity(0.7), Color.blue.opacity(0.3)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 70, height: 70)
                    
                    Image(systemName: isActive ? "target" : "checkmark.circle")
                        .font(.system(size: 30))
                        .foregroundColor(.white)
                }
            }
            .frame(height: 120)
            .onAppear {
                withAnimation(
                    Animation.easeInOut(duration: 1.5)
                        .repeatForever(autoreverses: true)
                ) {
                    animatePulse = true
                }
            }
            
            VStack(spacing: 10) {
                Text(isActive ? "No Active Goals Yet" : "No Completed Goals Yet")
                    .font(.title3)
                    .fontWeight(.bold)
                
                Text(isActive ? "Set goals to track your fitness journey" : "Complete your active goals to see them here")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 250)
                    .padding(.bottom, 5)
            }
            
            Button(action: addAction) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .font(.headline)
                    
                    Text(isActive ? "Create a Goal" : "Set a New Goal")
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .padding(.vertical, 12)
                .padding(.horizontal, 30)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(30)
                .shadow(color: Color.blue.opacity(0.3), radius: 5, x: 0, y: 3)
            }
        }
        .padding(30)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Original Views (keeping for compatibility)

struct EmptyGoalsView: View {
    var isActive: Bool
    var addAction: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "target")
                .font(.system(size: 60))
                .foregroundColor(.blue.opacity(0.7))
                .padding()
            
            Text(isActive ? "No active goals yet" : "No completed goals yet")
                .font(.title3)
                .fontWeight(.medium)
            
            Text(isActive ? "Set a goal to track your progress" : "Complete some goals to see them here")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: addAction) {
                Text(isActive ? "Create a Goal" : "Create Your First Goal")
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10)
                    .padding(.horizontal, 40)
            }
            .padding(.top)
        }
        .padding()
        .frame(maxHeight: .infinity)
    }
}

struct GoalCard: View {
    var goal: Goal
    @EnvironmentObject var goalViewModel: GoalViewModel
    @State private var showingDetail = false
    
    var body: some View {
        Button(action: {
            showingDetail = true
        }) {
            VStack(alignment: .leading, spacing: 12) {
                // Goal Title and Type
                HStack {
                    Image(systemName: goal.type.icon)
                        .font(.title3)
                        .foregroundColor(.white)
                        .padding(8)
                        .background(getGoalColor())
                        .cornerRadius(8)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(goal.title)
                            .font(.headline)
                            .lineLimit(1)
                        
                        Text(goal.type.displayName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Time remaining
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(goal.remainingDays) days left")
                            .font(.subheadline)
                            .foregroundColor(goal.remainingDays < 3 ? .red : .primary)
                        
                        Text("\(Int(goal.currentValue))/\(Int(goal.targetValue))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Progress Bar
                ProgressView(value: goal.progress)
                    .progressViewStyle(LinearProgressViewStyle())
                    .tint(getGoalColor())
                
                // Linked item display (if any)
                if let linkedType = goal.linkedWorkoutType {
                    HStack {
                        Image(systemName: "link")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("Linked to \(WorkoutType(rawValue: linkedType)?.rawValue.capitalized ?? "Unknown") workouts")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else if let linkedHabitId = goal.linkedHabitId {
                    HStack {
                        Image(systemName: "link")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("Linked to habit")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(15)
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingDetail) {
            GoalDetailView(goal: goal)
                .environmentObject(goalViewModel)
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

struct CompletedGoalCard: View {
    var goal: Goal
    @EnvironmentObject var goalViewModel: GoalViewModel
    @State private var showingDetail = false
    
    var body: some View {
        Button(action: {
            showingDetail = true
        }) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                    .foregroundColor(.green)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(goal.title)
                        .font(.headline)
                        .lineLimit(1)
                    
                    Text("Completed \(formatDate(goal.lastUpdated))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(Int(goal.targetValue)) \(getUnitLabel())")
                        .font(.subheadline)
                    
                    Text("\(goal.timeframe.displayName)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(15)
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingDetail) {
            GoalDetailView(goal: goal)
                .environmentObject(goalViewModel)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    private func getUnitLabel() -> String {
        switch goal.type {
        case .workout: return "workouts"
        case .habit: return "completions"
        case .distance: return "km"
        case .duration: return "minutes"
        case .streak: return "days"
        case .weight: return "kg"
        }
    }
}
