//
//  SuggestedGoalsView.swift
//  FitnessHabitTracker
//
//  Created by Nikhil Av on 4/21/25.
//  Enhanced for Workout and Habit Integration

import SwiftUI

struct SuggestedGoalsView: View {
    @EnvironmentObject var goalViewModel: GoalViewModel
    @EnvironmentObject var workoutViewModel: WorkoutViewModel
    @EnvironmentObject var habitViewModel: HabitViewModel
    @Binding var isPresented: Bool
    @Binding var parentPresented: Bool
    
    // NEW: Add parameters for specific workout or habit
    var specificWorkout: Workout? = nil
    var specificHabit: Habit? = nil
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Title and intro text
                if specificWorkout != nil {
                    Text("Create a goal based on your \(specificWorkout?.type.rawValue ?? "workout")")
                        .font(.headline)
                        .padding(.horizontal)
                } else if specificHabit != nil {
                    Text("Create a goal for \(specificHabit?.name ?? "this habit")")
                        .font(.headline)
                        .padding(.horizontal)
                } else {
                    Text("Need some ideas? Here are some goals to get you started:")
                        .font(.headline)
                        .padding(.horizontal)
                }
                
                // Display suggested goals
                let suggestedGoals = getSuggestedGoals()
                
                ForEach(suggestedGoals, id: \.id) { goal in
                    Button(action: {
                        goalViewModel.addGoal(goal)
                        isPresented = false
                        parentPresented = false
                    }) {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Image(systemName: goal.type.icon)
                                    .font(.title3)
                                    .foregroundColor(.white)
                                    .padding(8)
                                    .background(getGoalColor(goal.type))
                                    .cornerRadius(8)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(goal.title)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    
                                    Text("\(Int(goal.targetValue)) \(getUnitLabel(goal.type))")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "plus.circle")
                                    .font(.title3)
                                    .foregroundColor(.blue)
                            }
                            
                            Text(getGoalDescription(goal))
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.leading)
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(15)
                        .padding(.horizontal)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                Button(action: {
                    isPresented = false
                }) {
                    Text("Custom Goal")
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(10)
                        .padding(.horizontal)
                }
                .padding(.top)
            }
            .padding(.vertical)
        }
        .navigationTitle("Suggested Goals")
        .navigationBarItems(trailing: Button("Cancel") {
            isPresented = false
        })
    }
    
    // MARK: - Helper Methods
    
    private func getSuggestedGoals() -> [Goal] {
        // If we have a specific workout, generate goals for it
        if let workout = specificWorkout {
            return workoutViewModel.createSuggestedGoalsForWorkout(workout)
        }
        
        // If we have a specific habit, generate goals for it
        if let habit = specificHabit {
            return habitViewModel.createSuggestedGoalsForHabit(habit)
        }
        
        // Otherwise, use the default suggested goals
        return goalViewModel.getSuggestedGoals()
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
    
    private func getGoalDescription(_ goal: Goal) -> String {
        switch goal.type {
        case .workout:
            return "Boost your fitness routine by completing regular workouts. Track your progress to stay motivated!"
        case .habit:
            return "Consistency is key! Complete your habits regularly to build healthy routines."
        case .distance:
            return "Set distance goals for running, walking, or cycling to improve your endurance and cardiovascular health."
        case .duration:
            return "Track your total activity minutes to ensure you're getting enough movement throughout the week."
        case .streak:
            return "Challenge yourself to maintain a streak! This helps build consistency and turn activities into habits."
        case .weight:
            return "Set realistic weight goals and track your progress over time."
        }
    }
}

// MARK: - Goal Suggestion Coordinator

// NEW: A coordinator to handle goal suggestions from workouts and habits
class GoalSuggestionCoordinator: ObservableObject {
    @Published var showingSuggestions = false
    @Published var suggestedGoals: [Goal] = []
    @Published var sourceWorkout: Workout? = nil
    @Published var sourceHabit: Habit? = nil
    
    init() {
        setupObservers()
    }
    
    private func setupObservers() {
        // Listen for workout goal suggestions
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("SuggestWorkoutGoal"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self else { return }
            
            if let workout = notification.userInfo?["workout"] as? Workout {
                self.sourceWorkout = workout
                self.sourceHabit = nil
                self.showingSuggestions = true
            }
        }
        
        // Listen for habit goal suggestions
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("SuggestHabitGoal"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self else { return }
            
            if let habit = notification.userInfo?["habit"] as? Habit {
                self.sourceHabit = habit
                self.sourceWorkout = nil
                self.showingSuggestions = true
            }
        }
    }
}
