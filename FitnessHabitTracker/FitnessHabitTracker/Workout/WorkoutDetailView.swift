//
//  WorkoutDetailView.swift
//  FitnessHabitTracker
//
//  Created by Nikhil Av on 4/16/25.
//  Updated with SwiftData implementation, Goal integration, and animations

import SwiftUI
import SwiftData

struct WorkoutDetailView: View {
    var workout: Workout
    @EnvironmentObject var workoutViewModel: WorkoutViewModel
    @EnvironmentObject var goalViewModel: GoalViewModel  // Add GoalViewModel
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    @State private var selectedDistanceUnit: DistanceUnit = .km
    
    // Animation states
    @State private var headerAppeared = false
    @State private var statsAppeared = false
    @State private var detailsAppeared = false
    @State private var goalsAppeared = false
    @State private var relatedAppeared = false
    @State private var buttonsAppeared = false
    
    // New color theme
    private let primaryColor = Color.blue
    private let secondaryColor = Color.blue.opacity(0.1)
    private let tertiaryColor = Color.gray.opacity(0.12)
    private let successColor = Color.green
    private let alertColor = Color.red
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                workoutHeader
                    .opacity(headerAppeared ? 1 : 0)
                    .offset(y: headerAppeared ? 0 : 20)
                
                // Main Stats Card
                mainStatsCard
                    .opacity(statsAppeared ? 1 : 0)
                    .scaleEffect(statsAppeared ? 1 : 0.95)
                
                // Pace and Distance (if applicable)
                if let distance = workout.distance, distance > 0 {
                    distanceSection(distance: distance)
                        .opacity(detailsAppeared ? 1 : 0)
                        .offset(y: detailsAppeared ? 0 : 15)
                }
                
                // Heart Rate (if available)
                if workout.averageHeartRate != nil || workout.maxHeartRate != nil {
                    heartRateSection
                        .opacity(detailsAppeared ? 1 : 0)
                        .offset(y: detailsAppeared ? 0 : 15)
                }
                
                // Notes
                if let notes = workout.notes, !notes.isEmpty {
                    notesSection(notes: notes)
                        .opacity(detailsAppeared ? 1 : 0)
                        .offset(y: detailsAppeared ? 0 : 15)
                }
                
                // Linked Goals Section
                linkedGoalsSection
                    .opacity(goalsAppeared ? 1 : 0)
                    .offset(y: goalsAppeared ? 0 : 15)
                
                // Related Workouts
                relatedWorkoutsSection
                    .opacity(relatedAppeared ? 1 : 0)
                    .offset(y: relatedAppeared ? 0 : 15)
                
                Spacer(minLength: 40)
                
                // Action buttons
                actionButtonsSection
                    .opacity(buttonsAppeared ? 1 : 0)
                    .offset(y: buttonsAppeared ? 0 : 20)
            }
            .padding(.vertical)
        }
        .navigationTitle("Workout Details")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingEditSheet) {
            NavigationView {
                WorkoutEditView(workout: workout, isPresented: $showingEditSheet)
                    .environmentObject(workoutViewModel)
            }
            .transition(.move(edge: .bottom))
            .animation(.spring(), value: showingEditSheet)
        }
        .alert(isPresented: $showingDeleteAlert) {
            Alert(
                title: Text("Delete Workout"),
                message: Text("Are you sure you want to delete this workout? This action cannot be undone."),
                primaryButton: .destructive(Text("Delete")) {
                    workoutViewModel.deleteWorkout(workout)
                },
                secondaryButton: .cancel()
            )
        }
        .onAppear {
            animateContent()
        }
    }
    
    // MARK: - View Components
    
    private var workoutHeader: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                // Icon and Type
                VStack(alignment: .center) {
                    Image(systemName: workout.type.icon)
                        .font(.system(size: 30))
                        .foregroundColor(.white)
                        .frame(width: 70, height: 70)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [primaryColor, primaryColor.opacity(0.7)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(18)
                        .shadow(color: primaryColor.opacity(0.3), radius: 5, x: 0, y: 3)
                        .scaleEffect(headerAppeared ? 1 : 0.8)
                        .rotationEffect(Angle(degrees: headerAppeared ? 0 : -10))
                }
                .padding(.trailing, 8)
                
                // Workout Name and Details
                VStack(alignment: .leading, spacing: 6) {
                    Text(workout.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    HStack(spacing: 12) {
                        // Type
                        HStack(spacing: 4) {
                            Text(workout.type.rawValue.capitalized)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.gray)
                        }
                        
                        // Intensity Pill
                        if let intensity = workout.intensity {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(intensity.color)
                                    .frame(width: 8, height: 8)
                                
                                Text(intensity.rawValue.capitalized)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(intensity.color.opacity(0.1))
                            .cornerRadius(12)
                            .scaleEffect(headerAppeared ? 1 : 0.8)
                        }
                    }
                    
                    // Date with icon
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(primaryColor)
                            .font(.system(size: 14))
                        
                        Text(formatDate(workout.date))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 4)
                }
                
                Spacer()
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 6)
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: headerAppeared)
    }
    
    private var mainStatsCard: some View {
        VStack(spacing: 12) {
            WorkoutStatRow(
                title: "Duration",
                value: formatDuration(workout.duration),
                icon: "clock.fill",
                iconColor: primaryColor
            )
            .opacity(statsAppeared ? 1 : 0)
            .offset(x: statsAppeared ? 0 : -20)
            
            Divider()
                .padding(.horizontal)
            
            WorkoutStatRow(
                title: "Calories Burned",
                value: "\(Int(workout.caloriesBurned)) cal",
                icon: "flame.fill",
                iconColor: alertColor
            )
            .opacity(statsAppeared ? 1 : 0)
            .offset(x: statsAppeared ? 0 : -20)
        }
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(tertiaryColor, lineWidth: 1)
        )
        .padding(.horizontal)
        .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1), value: statsAppeared)
    }
    
    private func distanceSection(distance: Double) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Title with unit toggle
            HStack {
                HStack {
                    Image(systemName: "figure.walk")
                        .foregroundColor(primaryColor)
                    
                    Text("Distance & Pace")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                Picker("", selection: $selectedDistanceUnit) {
                    ForEach(DistanceUnit.allCases, id: \.self) { unit in
                        Text(unit.rawValue).tag(unit)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 100)
                .scaleEffect(0.9)
            }
            .padding(.horizontal)
            
            // Distance and Pace Cards
            HStack(spacing: 12) {
                // Distance Card
                VStack(spacing: 8) {
                    Text(formatDistance(distance))
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .transition(.scale(scale: 0.8).combined(with: .opacity))
                        .id("distance-\(selectedDistanceUnit.rawValue)") // For animation when unit changes
                    
                    HStack(spacing: 5) {
                        Image(systemName: "ruler")
                            .font(.caption)
                            .foregroundColor(primaryColor)
                        
                        Text("Distance")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(UIColor.systemBackground))
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(tertiaryColor, lineWidth: 1)
                )
                .scaleEffect(detailsAppeared ? 1 : 0.9)
                
                // Pace Card
                if let pace = getPace(distance: distance) {
                    VStack(spacing: 8) {
                        Text(pace)
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .transition(.scale(scale: 0.8).combined(with: .opacity))
                            .id("pace-\(selectedDistanceUnit.rawValue)") // For animation when unit changes
                        
                        HStack(spacing: 5) {
                            Image(systemName: "speedometer")
                                .font(.caption)
                                .foregroundColor(primaryColor)
                            
                            Text("Pace")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(UIColor.systemBackground))
                            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(tertiaryColor, lineWidth: 1)
                    )
                    .scaleEffect(detailsAppeared ? 1 : 0.9)
                }
            }
            .padding(.horizontal)
            .animation(.spring(response: 0.4), value: selectedDistanceUnit)
        }
        .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2), value: detailsAppeared)
    }
    
    private var heartRateSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundColor(alertColor)
                
                Text("Heart Rate")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .padding(.horizontal)
            
            HStack(spacing: 12) {
                if let avgHR = workout.averageHeartRate {
                    VStack(spacing: 8) {
                        // Animated numeric counter
                        HStack(spacing: 0) {
                            CountingView(value: Double(Int(avgHR)), detailsAppeared: detailsAppeared)
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(alertColor)
                        }
                        
                        Text("BPM")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(alertColor.opacity(0.7))
                        
                        HStack(spacing: 5) {
                            Image(systemName: "heart")
                                .font(.caption)
                                .foregroundColor(alertColor)
                            
                            Text("Average")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(UIColor.systemBackground))
                            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(alertColor.opacity(0.2), lineWidth: 1)
                    )
                    .scaleEffect(detailsAppeared ? 1 : 0.9)
                }
                
                if let maxHR = workout.maxHeartRate {
                    VStack(spacing: 8) {
                        // Animated numeric counter
                        HStack(spacing: 0) {
                            CountingView(value: Double(Int(maxHR)), detailsAppeared: detailsAppeared)
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(alertColor)
                        }
                        
                        Text("BPM")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(alertColor.opacity(0.7))
                        
                        HStack(spacing: 5) {
                            Image(systemName: "heart.fill")
                                .font(.caption)
                                .foregroundColor(alertColor)
                                .scaleEffect(detailsAppeared ? 1 : 0.8)
                                .rotationEffect(Angle(degrees: detailsAppeared ? 0 : -15))
                                .animation(
                                    Animation.spring(response: 0.5, dampingFraction: 0.6)
                                        .repeatForever(autoreverses: true)
                                        .delay(0.5),
                                    value: detailsAppeared
                                )
                            
                            Text("Maximum")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(UIColor.systemBackground))
                            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(alertColor.opacity(0.2), lineWidth: 1)
                    )
                    .scaleEffect(detailsAppeared ? 1 : 0.9)
                }
            }
            .padding(.horizontal)
        }
        .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.3), value: detailsAppeared)
    }
    
    private func notesSection(notes: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "note.text")
                    .foregroundColor(primaryColor)
                
                Text("Notes")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            Text(notes)
                .font(.body)
                .foregroundColor(.secondary)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(tertiaryColor)
                .cornerRadius(12)
        }
        .padding(.horizontal)
    }
    
    // Linked Goals Section
    private var linkedGoalsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            let linkedGoals = goalViewModel.activeGoals.filter { $0.isLinkedToWorkout(workout) }
            
            if !linkedGoals.isEmpty {
                HStack {
                    Image(systemName: "target")
                        .foregroundColor(successColor)
                        .rotationEffect(Angle(degrees: goalsAppeared ? 0 : 360))
                        .animation(.spring(response: 1, dampingFraction: 0.6).delay(0.2), value: goalsAppeared)
                    
                    Text("Linked Goals")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .padding(.horizontal)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(Array(linkedGoals.enumerated()), id: \.element.id) { index, goal in
                            NavigationLink(destination: GoalDetailView(goal: goal)) {
                                LinkedGoalCard(goal: goal, progress: goal.progress)
                                    .offset(x: goalsAppeared ? 0 : 100 + CGFloat(index * 50))
                                    .animation(.spring(response: 0.7, dampingFraction: 0.7).delay(0.2 + Double(index) * 0.1), value: goalsAppeared)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }
            }
        }
    }
    
    private var relatedWorkoutsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "rectangle.on.rectangle")
                    .foregroundColor(primaryColor)
                    .opacity(relatedAppeared ? 1 : 0)
                    .scaleEffect(relatedAppeared ? 1 : 0.5)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: relatedAppeared)
                
                Text("Similar Workouts")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(Array(getSimilarWorkouts().enumerated()), id: \.element.id) { index, similarWorkout in
                        NavigationLink(destination: WorkoutDetailView(workout: similarWorkout)) {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack(spacing: 12) {
                                    Image(systemName: similarWorkout.type.icon)
                                        .foregroundColor(.white)
                                        .padding(8)
                                        .background(
                                            LinearGradient(
                                                gradient: Gradient(colors: [primaryColor, primaryColor.opacity(0.7)]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .cornerRadius(10)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(similarWorkout.name)
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.primary)
                                            .lineLimit(1)
                                        
                                        Text(formatShortDate(similarWorkout.date))
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                }
                                
                                Divider()
                                    .padding(.vertical, 4)
                                
                                HStack(spacing: 12) {
                                    // Duration
                                    HStack(spacing: 4) {
                                        Image(systemName: "clock")
                                            .font(.system(size: 10))
                                            .foregroundColor(.gray)
                                        
                                        Text("\(Int(similarWorkout.duration / 60)) min")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                    
                                    Spacer()
                                    
                                    // Calories
                                    HStack(spacing: 4) {
                                        Image(systemName: "flame")
                                            .font(.system(size: 10))
                                            .foregroundColor(.gray)
                                        
                                        Text("\(Int(similarWorkout.caloriesBurned)) cal")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                            .padding()
                            .frame(width: 240)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(UIColor.systemBackground))
                                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(tertiaryColor, lineWidth: 1)
                            )
                        }
                        .offset(x: relatedAppeared ? 0 : 300)
                        .opacity(relatedAppeared ? 1 : 0)
                        .animation(
                            .spring(response: 0.6, dampingFraction: 0.7)
                            .delay(0.3 + Double(index) * 0.1),
                            value: relatedAppeared
                        )
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
        }
    }
    
    private var actionButtonsSection: some View {
        VStack(spacing: 16) {
            Button(action: {
                withAnimation(.spring()) {
                    showingEditSheet = true
                }
            }) {
                HStack {
                    Image(systemName: "pencil")
                        .font(.headline)
                    Text("Edit Workout")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [primaryColor, primaryColor.opacity(0.8)]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundColor(.white)
                .cornerRadius(16)
                .shadow(color: primaryColor.opacity(0.3), radius: 5, x: 0, y: 3)
            }
            .scaleEffect(buttonsAppeared ? 1 : 0.95)
            .animation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.1), value: buttonsAppeared)
            .buttonStyle(BouncyButtonStyle())
            
            // Create Goal Button
//            if !hasLinkedGoal() {
//                Button(action: {
//                    withAnimation(.spring()) {
//                        createGoalForWorkout()
//                    }
//                }) {
//                    HStack {
//                        Image(systemName: "target")
//                            .font(.headline)
//                        Text("Create Goal")
//                            .font(.headline)
//                    }
//                    .frame(maxWidth: .infinity)
//                    .padding(.vertical, 16)
//                    .background(
//                        LinearGradient(
//                            gradient: Gradient(colors: [successColor, successColor.opacity(0.8)]),
//                            startPoint: .leading,
//                            endPoint: .trailing
//                        )
//                    )
//                    .foregroundColor(.white)
//                    .cornerRadius(16)
//                    .shadow(color: successColor.opacity(0.3), radius: 5, x: 0, y: 3)
//                }
//                .scaleEffect(buttonsAppeared ? 1 : 0.95)
//                .animation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.2), value: buttonsAppeared)
//                .buttonStyle(BouncyButtonStyle())
//            }
            
            Button(action: {
                withAnimation(.spring()) {
                    showingDeleteAlert = true
                }
            }) {
                HStack {
                    Image(systemName: "trash")
                        .font(.headline)
                    Text("Delete Workout")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color(UIColor.systemBackground))
                .foregroundColor(alertColor)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(alertColor, lineWidth: 1)
                )
            }
            .scaleEffect(buttonsAppeared ? 1 : 0.95)
            .animation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.3), value: buttonsAppeared)
            .buttonStyle(BouncyButtonStyle())
        }
        .padding(.horizontal)
    }
    
    // MARK: - Helper Methods
    
    private func animateContent() {
        // Staggered animation sequence
        withAnimation(.easeOut(duration: 0.5)) {
            headerAppeared = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.easeOut(duration: 0.5)) {
                statsAppeared = true
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.easeOut(duration: 0.5)) {
                detailsAppeared = true
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.easeOut(duration: 0.5)) {
                goalsAppeared = true
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.easeOut(duration: 0.5)) {
                relatedAppeared = true
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeOut(duration: 0.5)) {
                buttonsAppeared = true
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatShortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds / 3600)
        let minutes = Int((seconds.truncatingRemainder(dividingBy: 3600)) / 60)
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes) minutes"
        }
    }
    
    private func formatDistance(_ distanceInKm: Double) -> String {
        let value = selectedDistanceUnit == .km ? distanceInKm : distanceInKm / 1.60934
        return String(format: "%.2f %@", value, selectedDistanceUnit.rawValue)
    }
    
    private func getPace(distance: Double) -> String? {
        guard distance > 0 else { return nil }
        
        let distanceValue = selectedDistanceUnit == .km ?
            distance :
            distance / 1.60934
        
        let paceInSeconds = workout.duration / distanceValue
        let minutes = Int(paceInSeconds / 60)
        let seconds = Int(paceInSeconds.truncatingRemainder(dividingBy: 60))
        
        return String(format: "%d:%02d min/%@", minutes, seconds, selectedDistanceUnit.rawValue)
    }
    
    private func getSimilarWorkouts() -> [Workout] {
        return workoutViewModel.workouts
            .filter { $0.id != workout.id && $0.type == workout.type }
            .sorted(by: { $0.date > $1.date })
            .prefix(5)
            .map { $0 }
    }
    
    // Goal-related helper methods
    
    private func hasLinkedGoal() -> Bool {
        return goalViewModel.activeGoals.contains { $0.isLinkedToWorkout(workout) }
    }
    
    private func createGoalForWorkout() {
        // Present a sheet with suggested goals based on this workout
        let suggestedGoals = workoutViewModel.createSuggestedGoalsForWorkout(workout)
        
        // Post notification to show goal suggestion UI
        NotificationCenter.default.post(
            name: NSNotification.Name("ShowSuggestedGoals"),
            object: nil,
            userInfo: ["suggestedGoals": suggestedGoals]
        )
    }
}

// MARK: - Supporting Views

// Custom Button Style
struct BouncyButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// Animated Counter View
struct CountingView: View {
    let value: Double
    let detailsAppeared: Bool
    @State private var displayValue: Double = 0
    
    var body: some View {
        Text("\(Int(displayValue))")
            .onAppear {
                if detailsAppeared {
                    withAnimation(.spring(response: 1.5, dampingFraction: 0.8).delay(0.3)) {
                        displayValue = value
                    }
                } else {
                    displayValue = value
                }
            }
            .onChange(of: detailsAppeared) { appeared in
                if appeared {
                    withAnimation(.spring(response: 1.5, dampingFraction: 0.8)) {
                        displayValue = value
                    }
                } else {
                    displayValue = 0
                }
            }
    }
}

// LinkedGoalCard View
struct LinkedGoalCard: View {
    var goal: Goal
    var progress: Double
    @State private var showProgress = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: goal.type.icon)
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(8)
                    .background(getGoalColor())
                    .cornerRadius(10)
                
                Text(goal.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .lineLimit(1)
            }
            
            // Progress info
            HStack {
                Text("\(Int(goal.currentValue)) / \(Int(goal.targetValue))")
                    .font(.system(.subheadline, design: .rounded))
                    .fontWeight(.medium)
                
                Spacer()
                
                Text("\(Int(progress * 100))%")
                    .font(.system(.caption, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(getGoalColor())
            }
            
            // Progress Bar with custom styling and animation
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 8)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(getGoalColor())
                    .frame(width: showProgress ? max(CGFloat(progress) * 220, 8) : 0, height: 8)
                    .animation(.spring(response: 1, dampingFraction: 0.7).delay(0.3), value: showProgress)
            }
        }
        .padding()
        .frame(width: 240)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.12), lineWidth: 1)
        )
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation {
                    showProgress = true
                }
            }
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

struct WorkoutStatRow: View {
    var title: String
    var value: String
    var icon: String
    var iconColor: Color
    
    var body: some View {
        HStack {
            HStack {
                Image(systemName: icon)
                    .font(.headline)
                    .foregroundColor(iconColor)
                    .frame(width: 24, height: 24)
                
                Text(title)
                    .font(.headline)
            }
            
            Spacer()
            
            Text(value)
                .font(.system(.headline, design: .rounded))
                .fontWeight(.bold)
        }
        .padding(.horizontal)
    }
}

// MARK: - Preview
struct WorkoutDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            WorkoutDetailView(
                workout: Workout(
                    name: "Morning Run",
                    type: .running,
                    duration: 1800,
                    caloriesBurned: 320,
                    notes: "Felt great today!",
                    distance: 5.2,
                    intensity: .intense,
                    averageHeartRate: 145,
                    maxHeartRate: 175
                )
            )
            .environmentObject(WorkoutViewModel())
            .environmentObject(GoalViewModel())
        }
        .modelContainerPreview {
            Text("Preview with SwiftData")
        }
    }
}
