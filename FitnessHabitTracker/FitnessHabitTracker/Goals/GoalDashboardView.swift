//
//  GoalDashboardView.swift
//  FitnessHabitTracker
//
//  Created by Nikhil Av on 4/22/25.
//  Enhanced with improved visuals and animations
//

import SwiftUI
import Charts

struct GoalDashboardView: View {
    @EnvironmentObject var goalViewModel: GoalViewModel
    @State private var showingAddGoal = false
    @State private var showingGoalDetails: Goal? = nil
    @State private var showingGoalAnalytics = false
    @State private var animateCards = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header with summary
            HStack {
                VStack(alignment: .leading) {
                    Text("Goals & Progress")
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Text("Track your fitness journey")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: {
                    showingGoalAnalytics = true
                }) {
                    Image(systemName: "chart.bar.xaxis")
                        .font(.title3)
                        .foregroundColor(.white)
                        .padding(8)
                        .background(
                            Circle()
                                .fill(LinearGradient(
                                    gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .shadow(color: Color.blue.opacity(0.3), radius: 5, x: 0, y: 3)
                        )
                }
                
                Button(action: {
                    showingAddGoal = true
                }) {
                    Image(systemName: "plus")
                        .font(.title3)
                        .foregroundColor(.white)
                        .padding(8)
                        .background(
                            Circle()
                                .fill(LinearGradient(
                                    gradient: Gradient(colors: [Color.green, Color.blue]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .shadow(color: Color.blue.opacity(0.3), radius: 5, x: 0, y: 3)
                        )
                }
            }
            
            // Progress Summary
            if !goalViewModel.activeGoals.isEmpty {
                EnhancedGoalProgressSummary(goals: goalViewModel.activeGoals)
                    .scaleEffect(animateCards ? 1.0 : 0.95)
                    .opacity(animateCards ? 1.0 : 0.0)
            }
            
            // Goal Cards in Horizontal Scroll
            if !goalViewModel.activeGoals.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(Array(goalViewModel.activeGoals.enumerated()), id: \.element.id) { index, goal in
                            EnhancedGoalDashboardCard(goal: goal)
                                .scaleEffect(animateCards ? 1.0 : 0.9)
                                .opacity(animateCards ? 1.0 : 0.0)
                                .animation(
                                    Animation.spring(response: 0.6, dampingFraction: 0.8)
                                        .delay(Double(index) * 0.1 + 0.1),
                                    value: animateCards
                                )
                                .onTapGesture {
                                    showingGoalDetails = goal
                                }
                                .frame(width: 240)
                        }
                    }
                    .padding(.horizontal)
                }
            } else {
                VStack(spacing: 15) {
                    // Empty state with animated target
                    ZStack {
                        // Background circles
                        ForEach(0..<3) { i in
                            Circle()
                                .stroke(Color.blue.opacity(0.1), lineWidth: 3)
                                .frame(width: 80 + CGFloat(i) * 20, height: 80 + CGFloat(i) * 20)
                                .scaleEffect(animateCards ? 1.0 : 0.8)
                                .opacity(animateCards ? 0.6 - Double(i) * 0.2 : 0)
                                .animation(
                                    Animation.easeInOut(duration: 1.5)
                                        .repeatForever(autoreverses: true)
                                        .delay(Double(i) * 0.2),
                                    value: animateCards
                                )
                        }
                        
                        // Animated target icon
                        Image(systemName: "target")
                            .font(.system(size: 40))
                            .foregroundColor(.blue.opacity(0.7))
                            .scaleEffect(animateCards ? 1.0 : 0.8)
                            .animation(
                                Animation.easeInOut(duration: 1.2)
                                    .repeatForever(autoreverses: true),
                                value: animateCards
                            )
                    }
                    .frame(height: 100)
                    .padding(.vertical, 5)
                    
                    Text("No active goals yet")
                        .font(.headline)
                        .opacity(animateCards ? 1.0 : 0.0)
                        .animation(.easeIn(duration: 0.5).delay(0.2), value: animateCards)
                    
                    Button(action: {
                        showingAddGoal = true
                    }) {
                        Text("Create Your First Goal")
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.7)]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(10)
                            .shadow(color: Color.blue.opacity(0.3), radius: 3, x: 0, y: 2)
                    }
                    .scaleEffect(animateCards ? 1.0 : 0.9)
                    .opacity(animateCards ? 1.0 : 0.0)
                    .animation(.easeIn(duration: 0.5).delay(0.3), value: animateCards)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color.gray.opacity(0.1))
                )
            }
        }
        .padding(.horizontal)
        .onAppear {
            // Trigger animations when view appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation {
                    animateCards = true
                }
            }
        }
        .sheet(isPresented: $showingAddGoal) {
            NavigationView {
                GoalFormView(isPresented: $showingAddGoal)
                    .environmentObject(goalViewModel)
            }
        }
        .sheet(item: $showingGoalDetails) { goal in
            NavigationView {
                GoalDetailView(goal: goal)
                    .environmentObject(goalViewModel)
            }
        }
        .sheet(isPresented: $showingGoalAnalytics) {
            NavigationView {
                GoalAnalyticsView()
                    .environmentObject(goalViewModel)
            }
        }
    }
}

// MARK: - Enhanced Goal Dashboard Card

struct EnhancedGoalDashboardCard: View {
    var goal: Goal
    @State private var animateProgress = false
    @State private var showDetails = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Card Header with Icon, Title and Type
            HStack(alignment: .top) {
                // Custom goal type icon with gradient background
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            gradient: getGoalTypeGradient(goal.type),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 42, height: 42)
                        .shadow(color: getGoalColor(goal.type).opacity(0.3), radius: 4, x: 0, y: 2)
                    
                    Image(systemName: goal.type.icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(goal.title)
                        .font(.headline)
                        .lineLimit(1)
                        .foregroundColor(.primary)
                    
                    Text(goal.type.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                .padding(.leading, 4)
                
                Spacer()
                
                // Progress percentage badge
                ZStack {
                    Circle()
                        .fill(getProgressBackgroundColor(goal.progress))
                        .frame(width: 36, height: 36)
                    
                    Text("\(Int(goal.progress * 100))%")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            
            // Show more details when tapped
            if showDetails {
                VStack(alignment: .leading, spacing: 8) {
                    // Divider with subtle gradient
                    Rectangle()
                        .fill(LinearGradient(
                            gradient: Gradient(colors: [
                                getGoalColor(goal.type).opacity(0.2),
                                getGoalColor(goal.type).opacity(0.0)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                        .frame(height: 1)
                    
                    // Progress metrics
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Progress")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text("\(Int(goal.currentValue))/\(Int(goal.targetValue))")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        
                        Spacer()
                        
                        // Time remaining badge
                        HStack(spacing: 4) {
                            Image(systemName: timeRemainingIcon)
                                .font(.system(size: 12))
                                .foregroundColor(timeRemainingColor)
                            
                            Text(timeRemainingText)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(timeRemainingColor)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(timeRemainingColor.opacity(0.1))
                        .cornerRadius(12)
                    }
                    
                    // Timeline indicator showing remaining and elapsed time
                    ZStack(alignment: .leading) {
                        // Background timeline
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.15))
                            .frame(height: 8)
                        
                        // Timeline progress (elapsed time)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(LinearGradient(
                                gradient: getTimelineGradient(),
                                startPoint: .leading,
                                endPoint: .trailing
                            ))
                            .frame(width: getTimeProgress() * UIScreen.main.bounds.width * 0.65, height: 8)
                        
                        // Today marker
                        Circle()
                            .fill(Color.white)
                            .frame(width: 12, height: 12)
                            .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 1)
                            .offset(x: getTimeProgress() * UIScreen.main.bounds.width * 0.65 - 6)
                    }
                }
                .padding(.top, 2)
            }
            
            // Enhanced progress visualization
            VStack(spacing: 8) {
                // Interactive progress bar
                ZStack(alignment: .leading) {
                    // Background track with subtle pattern
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.gray.opacity(0.15))
                        .overlay(
                            // Subtle pattern overlay
                            HStack(spacing: 4) {
                                ForEach(0..<15, id: \.self) { i in
                                    Rectangle()
                                        .fill(Color.white.opacity(0.15))
                                        .frame(width: 2, height: 12)
                                }
                            }
                        )
                        .frame(height: 12)
                    
                    // Progress with gradient and animation
                    RoundedRectangle(cornerRadius: 6)
                        .fill(LinearGradient(
                            gradient: getGoalTypeGradient(goal.type),
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                        .frame(width: animateProgress ? CGFloat(goal.progress) * UIScreen.main.bounds.width * 0.7 : 0, height: 12)
                    
                    // Milestone markers
                    if goal.type == .streak || goal.type == .habit {
                        HStack(spacing: 0) {
                            ForEach(getMilestones(), id: \.self) { milestone in
                                let position = CGFloat(milestone) / CGFloat(goal.targetValue)
                                
                                if position <= 1.0 {
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 6, height: 6)
                                        .shadow(color: Color.black.opacity(0.2), radius: 1, x: 0, y: 1)
                                        .padding(.leading, position * UIScreen.main.bounds.width * 0.7 - 3)
                                }
                            }
                        }
                    }
                }
                
                // Tap indicator
                HStack {
                    Spacer()
                    Image(systemName: showDetails ? "chevron.up" : "chevron.down")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(6)
                        .background(Color.gray.opacity(0.1))
                        .clipShape(Circle())
                    Spacer()
                }
                .padding(.top, -4)
            }
            
            // Days remaining info
            HStack {
                Image(systemName: "calendar.badge.clock")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text("\(goal.remainingDays) days left")
                    .font(.caption2)
                    .foregroundColor(goal.remainingDays < 3 ? .red : .secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.secondarySystemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 3)
        )
        .onTapGesture {
            withAnimation(.spring()) {
                showDetails.toggle()
            }
        }
        .onAppear {
            // Animate progress bar when view appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation {
                    animateProgress = true
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    // Get color based on goal type
    private func getGoalColor(_ type: GoalType) -> Color {
        switch type {
        case .workout: return Color.blue
        case .habit: return Color.green
        case .distance: return Color.orange
        case .duration: return Color.purple
        case .streak: return Color.red
        case .weight: return Color.gray
        }
    }
    
    // Get gradient based on goal type
    private func getGoalTypeGradient(_ type: GoalType) -> Gradient {
        switch type {
        case .workout:
            return Gradient(colors: [Color.blue, Color.blue.opacity(0.7)])
        case .habit:
            return Gradient(colors: [Color.green, Color(red: 0.0, green: 0.8, blue: 0.5)])
        case .distance:
            return Gradient(colors: [Color.orange, Color(red: 1.0, green: 0.6, blue: 0.2)])
        case .duration:
            return Gradient(colors: [Color.purple, Color(red: 0.5, green: 0.3, blue: 0.9)])
        case .streak:
            return Gradient(colors: [Color.red, Color(red: 1.0, green: 0.3, blue: 0.5)])
        case .weight:
            return Gradient(colors: [Color.gray, Color(white: 0.6)])
        }
    }
    
    // Get timeline gradient
    private func getTimelineGradient() -> Gradient {
        return Gradient(colors: [
            getGoalColor(goal.type).opacity(0.7),
            getGoalColor(goal.type)
        ])
    }
    
    // Get color based on progress
    private func getProgressBackgroundColor(_ progress: Double) -> Color {
        if progress >= 1.0 {
            return Color.green
        } else if progress >= 0.7 {
            return Color.blue
        } else if progress >= 0.3 {
            return Color.orange
        } else {
            return Color.red
        }
    }
    
    // Calculate progress of time (how much of the time period has elapsed)
    private func getTimeProgress() -> CGFloat {
        let calendar = Calendar.current
        let now = Date()
        
        let totalDuration = calendar.dateComponents([.day], from: goal.startDate, to: goal.endDate).day ?? 1
        let elapsedDuration = calendar.dateComponents([.day], from: goal.startDate, to: now).day ?? 0
        
        return min(CGFloat(elapsedDuration) / CGFloat(totalDuration), 1.0)
    }
    
    // Time remaining properties
    private var timeRemainingText: String {
        if goal.remainingDays <= 0 {
            return "Due today"
        } else if goal.remainingDays == 1 {
            return "1 day left"
        } else {
            return "\(goal.remainingDays) days left"
        }
    }
    
    private var timeRemainingColor: Color {
        if goal.remainingDays <= 1 {
            return Color.red
        } else if goal.remainingDays <= 3 {
            return Color.orange
        } else if goal.remainingDays <= 7 {
            return Color.blue
        } else {
            return Color.green
        }
    }
    
    private var timeRemainingIcon: String {
        if goal.remainingDays <= 1 {
            return "exclamationmark.triangle.fill"
        } else if goal.remainingDays <= 3 {
            return "clock.fill"
        } else {
            return "calendar.badge.clock"
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
                milestones.append(21) // Three weeks (habit formation)
            }
            if goal.targetValue >= 30 {
                milestones.append(30) // One month
            }
        } else if goal.type == .habit {
            // For habit completions, add milestones at 25%, 50%, 75%
            milestones.append(Int(goal.targetValue * 0.25))
            milestones.append(Int(goal.targetValue * 0.5))
            milestones.append(Int(goal.targetValue * 0.75))
        }
        
        return milestones
    }
}

// MARK: - Enhanced Goal Progress Summary

struct EnhancedGoalProgressSummary: View {
    var goals: [Goal]
    @State private var animateGradient = false
    
    var body: some View {
        ZStack {
            // Animated background gradient
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.1, green: 0.2, blue: 0.45),
                            Color(red: 0.3, green: 0.4, blue: 0.9)
                        ]),
                        startPoint: animateGradient ? .topLeading : .bottomTrailing,
                        endPoint: animateGradient ? .bottomTrailing : .topLeading
                    )
                )
                .onAppear {
                    // Start gradient animation
                    withAnimation(
                        Animation.linear(duration: 5.0)
                            .repeatForever(autoreverses: true)
                    ) {
                        animateGradient.toggle()
                    }
                }
            
            // Content
            VStack(spacing: 15) {
                HStack(spacing: 12) {
                    // Active Goals
                    EnhancedStatCard(
                        value: "\(goals.count)",
                        label: "Active",
                        icon: "target",
                        color: .blue
                    )
                    
                    // Completed Goals
                    EnhancedStatCard(
                        value: "\(completedGoalsCount)",
                        label: "Completed",
                        icon: "checkmark.circle",
                        color: .green
                    )
                    
                    // Average Progress
                    EnhancedStatCard(
                        value: "\(averageProgressPercentage)%",
                        label: "Progress",
                        icon: "chart.bar.fill",
                        color: .orange
                    )
                }
                
                // Progress visualization
                HStack(alignment: .center, spacing: 5) {
                    ForEach(goalTypeDistribution, id: \.type) { item in
                        ProgressPill(
                            type: item.type,
                            count: item.count,
                            color: getGoalColor(item.type)
                        )
                    }
                }
                .padding(.horizontal, 5)
            }
            .padding(.vertical, 15)
            .padding(.horizontal)
        }
        .frame(height: 150)
        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
    }
    
    private var completedGoalsCount: Int {
        goals.filter { $0.progress >= 1.0 }.count
    }
    
    private var averageProgressPercentage: Int {
        let totalProgress = goals.reduce(0.0) { $0 + $1.progress }
        return goals.isEmpty ? 0 : Int((totalProgress / Double(goals.count)) * 100)
    }
    
    // Distribution of goal types for the pill visualization
    private var goalTypeDistribution: [GoalTypeCount] {
        var counts: [GoalType: Int] = [:]
        
        for goal in goals {
            counts[goal.type, default: 0] += 1
        }
        
        return counts.map { GoalTypeCount(type: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
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
    
    struct GoalTypeCount {
        let type: GoalType
        let count: Int
    }
}

// MARK: - Progress Summary Components

// Enhanced stat card with icon and glowing effect
struct EnhancedStatCard: View {
    var value: String
    var label: String
    var icon: String
    var color: Color
    @State private var glowing = false
    
    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                // Glowing background
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 36, height: 36)
                    .scaleEffect(glowing ? 1.1 : 1.0)
                    .opacity(glowing ? 0.6 : 0.2)
                
                // Icon
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }
            .onAppear {
                // Start breathing animation
                withAnimation(
                    Animation.easeInOut(duration: 1.5)
                        .repeatForever(autoreverses: true)
                ) {
                    glowing = true
                }
            }
            
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }
}

// Progress pill showing goal type distribution
struct ProgressPill: View {
    var type: GoalType
    var count: Int
    var color: Color
    @State private var appear = false
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: type.icon)
                .font(.system(size: 10))
                .foregroundColor(.white)
            
            Text("\(count)")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.white)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(
            Capsule()
                .fill(color)
        )
        .scaleEffect(appear ? 1.0 : 0.8)
        .opacity(appear ? 1.0 : 0.0)
        .onAppear {
            withAnimation(.spring().delay(0.3)) {
                appear = true
            }
        }
    }
}

// MARK: - Original Components (keeping for compatibility)

struct GoalProgressSummary: View {
    var goals: [Goal]
    
    var body: some View {
        HStack(spacing: 12) {
            ProgressStatCard(
                value: "\(goals.count)",
                label: "Active",
                icon: "target",
                color: .blue
            )
            
            ProgressStatCard(
                value: "\(completedGoalsCount)",
                label: "Complete",
                icon: "checkmark.circle",
                color: .green
            )
            
            ProgressStatCard(
                value: "\(averageProgressPercentage)%",
                label: "Progress",
                icon: "chart.bar.fill",
                color: .orange
            )
        }
    }
    
    private var completedGoalsCount: Int {
        goals.filter { $0.progress >= 1.0 }.count
    }
    
    private var averageProgressPercentage: Int {
        let totalProgress = goals.reduce(0.0) { $0 + $1.progress }
        return goals.isEmpty ? 0 : Int((totalProgress / Double(goals.count)) * 100)
    }
}

struct ProgressStatCard: View {
    var value: String
    var label: String
    var icon: String
    var color: Color
    
    var body: some View {
        VStack(spacing: 5) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundColor(color)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.1))
        .cornerRadius(10)
    }
}

// Original Card (keeping for reference)
struct GoalDashboardCard: View {
    var goal: Goal
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header with icon and title
            HStack {
                Image(systemName: goal.type.icon)
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(6)
                    .background(getGoalColor(goal.type))
                    .cornerRadius(8)
                
                Text(goal.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
            }
            
            // Progress bar and percentage
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("\(Int(goal.currentValue))/\(Int(goal.targetValue))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(Int(goal.progress * 100))%")
                        .font(.caption)
                        .fontWeight(.bold)
                }
                
                ProgressView(value: goal.progress)
                    .progressViewStyle(LinearProgressViewStyle())
                    .tint(getGoalColor(goal.type))
            }
            
            // Days remaining
            HStack {
                Image(systemName: "calendar.badge.clock")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text("\(goal.remainingDays) days left")
                    .font(.caption2)
                    .foregroundColor(goal.remainingDays < 3 ? .red : .secondary)
            }
        }
        .padding()
        .frame(width: 200)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
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
}

// The rest of the file remains unchanged
struct GoalAnalyticsView: View {
    @EnvironmentObject var goalViewModel: GoalViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedTimeRange: TimeRange = .month
    
    enum TimeRange: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case quarter = "3 Months"
        case year = "Year"
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Time Range Selector
                Picker("Time Range", selection: $selectedTimeRange) {
                    ForEach(TimeRange.allCases, id: \.self) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                // Goal Type Distribution Chart
                VStack(alignment: .leading, spacing: 10) {
                    Text("Goal Distribution")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    if goalViewModel.activeGoals.isEmpty {
                        Text("No active goals to analyze")
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    } else {
                        // Goal Type Distribution Chart
                        Chart {
                            ForEach(getGoalTypeDistribution(), id: \.type) { item in
                                SectorMark(
                                    angle: .value("Count", item.count),
                                    innerRadius: .ratio(0.5),
                                    angularInset: 1.5
                                )
                                .foregroundStyle(getGoalColor(item.type))
                                .cornerRadius(5)
                                .annotation(position: .overlay) {
                                    Text("\(item.count)")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                }
                            }
                        }
                        .frame(height: 200)
                        .padding()
                        
                        // Legend
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(getGoalTypeDistribution(), id: \.type) { item in
                                HStack {
                                    Circle()
                                        .fill(getGoalColor(item.type))
                                        .frame(width: 10, height: 10)
                                    
                                    Text(item.type.displayName)
                                        .font(.caption)
                                    
                                    Spacer()
                                    
                                    Text("\(item.count) goals")
                                        .font(.caption)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(15)
                .padding(.horizontal)
                
                // Progress By Goal Chart
                VStack(alignment: .leading, spacing: 10) {
                    Text("Goal Progress")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    if goalViewModel.activeGoals.isEmpty {
                        Text("No active goals to display")
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    } else {
                        Chart {
                            ForEach(goalViewModel.activeGoals.sorted(by: { $0.progress > $1.progress })) { goal in
                                BarMark(
                                    x: .value("Progress", goal.progress * 100),
                                    y: .value("Goal", goal.title)
                                )
                                .foregroundStyle(getGoalColor(goal.type))
                            }
                        }
                        .frame(height: 200)
                        .chartXAxis {
                            AxisMarks(values: .automatic(desiredCount: 5)) { value in
                                AxisGridLine()
                                AxisValueLabel {
                                    if let doubleValue = value.as(Double.self) {
                                        Text("\(Int(doubleValue))%")
                                    }
                                }
                            }
                        }
                        .chartYAxis {
                            AxisMarks { _ in
                                AxisValueLabel {
                                    // Empty to hide the labels
                                    Text("")
                                }
                            }
                        }
                        .padding()
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(15)
                .padding(.horizontal)
                
                // Goal Insights
                VStack(alignment: .leading, spacing: 10) {
                    Text("Insights")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    Text(getInsightText())
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(10)
                        .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Goal Analytics")
        .navigationBarItems(leading: Button("Close") {
            presentationMode.wrappedValue.dismiss()
        })
    }
    
    private struct GoalTypeCount {
        let type: GoalType
        let count: Int
    }
    
    private func getGoalTypeDistribution() -> [GoalTypeCount] {
        var counts: [GoalType: Int] = [:]
        
        for goal in goalViewModel.activeGoals {
            counts[goal.type, default: 0] += 1
        }
        
        return counts.map { GoalTypeCount(type: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
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
    
    private func getInsightText() -> String {
        guard !goalViewModel.activeGoals.isEmpty else {
            return "Add goals to track your fitness journey and see insights about your progress."
        }
        
        let topGoalType = getGoalTypeDistribution().first?.type.displayName ?? "unknown"
        let highestProgress = goalViewModel.activeGoals.max(by: { $0.progress < $1.progress })
        let lowestProgress = goalViewModel.activeGoals.min(by: { $0.progress < $1.progress })
        
        return "Your most common goal type is \(topGoalType). Your best performing goal is '\(highestProgress?.title ?? "")' at \(Int((highestProgress?.progress ?? 0) * 100))% completion. Consider breaking down '\(lowestProgress?.title ?? "")' which is at \(Int((lowestProgress?.progress ?? 0) * 100))% into smaller steps for better progress."
    }
}
