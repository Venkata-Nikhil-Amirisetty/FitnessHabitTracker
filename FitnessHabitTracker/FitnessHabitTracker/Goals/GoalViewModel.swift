//
//  GoalViewModel.swift
//  FitnessHabitTracker
//
//  Created by Nikhil Av on 4/21/25.
//  Updated with persistence fixes

import SwiftUI
import Combine
import SwiftData
import FirebaseFirestore
import FirebaseAuth

class GoalViewModel: ObservableObject {
    @Published var goals: [Goal] = []
    @Published var activeGoals: [Goal] = []
    @Published var completedGoals: [Goal] = []
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var showingError = false
    
    private var modelContext: ModelContext?
    private var firestoreListener: ListenerRegistration?
    private var userId: String?
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        print("Initializing GoalViewModel")
        // Listen for authentication changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(userDidChange),
            name: NSNotification.Name("UserDidChangeNotification"),
            object: nil
        )
        
        // If a user is already authenticated, load goals
        if let currentUser = Auth.auth().currentUser {
            self.userId = currentUser.uid
            print("User already authenticated, loading goals for: \(currentUser.uid)")
            loadGoals()
        } else {
            print("No authenticated user found during GoalViewModel init")
        }
        
        // Implement a direct auth state listener as a redundancy
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            if let user = user, self?.userId != user.uid {
                print("Auth state change detected: \(user.uid)")
                self?.userId = user.uid
                self?.loadGoals()
            } else if user == nil && self?.userId != nil {
                print("Auth state change: user logged out")
                self?.userId = nil
                self?.goals = []
                self?.activeGoals = []
                self?.completedGoals = []
                self?.firestoreListener?.remove()
            }
        }
    }
    
    deinit {
        firestoreListener?.remove()
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func userDidChange(_ notification: Notification) {
        if let userInfo = notification.userInfo,
           let userId = userInfo["userId"] as? String {
            print("User changed to: \(userId)")
            self.userId = userId
            loadGoals()
        } else {
            // User logged out
            print("User logged out, clearing goals")
            self.userId = nil
            self.goals = []
            self.activeGoals = []
            self.completedGoals = []
            firestoreListener?.remove()
        }
    }
    
    func setModelContext(_ context: ModelContext) {
        print("Setting model context for GoalViewModel")
        self.modelContext = context
        if let firebaseUser = Auth.auth().currentUser {
            self.userId = firebaseUser.uid
            print("Loading goals after modelContext was set")
            loadGoals()
        }
    }
    
    // MARK: - Data Operations
    
    func loadGoals() {
        guard let userId = userId else {
            // No authenticated user
            print("No user ID available, cannot load goals")
            self.goals = []
            self.activeGoals = []
            self.completedGoals = []
            return
        }
        
        print("Loading goals for user: \(userId)")
        isLoading = true
        
        // First, try to load from local SwiftData store
        if let modelContext = modelContext {
            do {
                let descriptor = FetchDescriptor<Goal>()
                let localGoals = try modelContext.fetch(descriptor)
                
                if !localGoals.isEmpty {
                    print("Found \(localGoals.count) goals in local storage")
                    self.goals = localGoals
                    self.updateFilteredGoals()
                }
            } catch {
                print("Error fetching local goals: \(error.localizedDescription)")
            }
        }
        
        // Remove any existing listener
        firestoreListener?.remove()
        
        // Set up real-time listener for user's goals from Firestore
        let db = FirebaseManager.shared.firestore
        let goalsRef = db.collection("users").document(userId).collection("goals")
        
        firestoreListener = goalsRef.addSnapshotListener { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Error loading goals from Firestore: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = "Failed to load goals: \(error.localizedDescription)"
                    self.showingError = true
                }
                return
            }
            
            guard let documents = snapshot?.documents else {
                print("No goal documents found")
                DispatchQueue.main.async {
                    self.isLoading = false
                    // Don't reset goals from local storage if no documents found
                    // This could mean no goals have been added yet, not that they've been deleted
                    if self.goals.isEmpty {
                        self.goals = []
                        self.activeGoals = []
                        self.completedGoals = []
                    }
                }
                return
            }
            
            print("Found \(documents.count) goal documents")
            
            // Parse Firestore documents into Goal objects
            let firestoreGoals = documents.compactMap { document -> Goal? in
                let data = document.data()
                let goal = FirebaseManager.shared.goalFromDictionary(data)
                if goal == nil {
                    print("Failed to parse goal from document: \(document.documentID)")
                    print("Document data: \(data)")
                }
                return goal
            }
            
            print("Successfully parsed \(firestoreGoals.count) goals")
            
            // Convert to local Goal models and save to SwiftData
            DispatchQueue.main.async {
                self.syncGoalsWithLocal(firestoreGoals)
                self.isLoading = false
            }
        }
    }
    
    private func syncGoalsWithLocal(_ firestoreGoals: [Goal]) {
        guard let modelContext = modelContext else {
            print("Warning: modelContext is nil, cannot sync goals with local storage")
            self.goals = firestoreGoals
            self.updateFilteredGoals()
            return
        }
        
        // Get existing goals from SwiftData
        do {
            let descriptor = FetchDescriptor<Goal>()
            let existingGoals = try modelContext.fetch(descriptor)
            
            print("Found \(existingGoals.count) existing goals in local storage")
            
            // Prepare ID sets for quick lookups
            let existingIds = Set(existingGoals.map { $0.id })
            let firestoreIds = Set(firestoreGoals.map { $0.id })
            
            // Add new goals
            for firestoreGoal in firestoreGoals {
                if !existingIds.contains(firestoreGoal.id) {
                    print("Inserting new goal: \(firestoreGoal.title)")
                    modelContext.insert(firestoreGoal)
                }
            }
            
            // Remove deleted goals
            for goal in existingGoals {
                if !firestoreIds.contains(goal.id) {
                    print("Deleting goal: \(goal.title)")
                    modelContext.delete(goal)
                }
            }
            
            // Update existing goals
            for firestoreGoal in firestoreGoals {
                if let existingGoal = existingGoals.first(where: { $0.id == firestoreGoal.id }) {
                    // Update properties
                    updateGoalProperties(existingGoal, from: firestoreGoal)
                }
            }
            
            // Make sure to save changes to persistent storage
            try modelContext.save()
            print("Successfully saved goals to local storage")
            
            // Update published property with latest data
            let updatedDescriptor = FetchDescriptor<Goal>(sortBy: [SortDescriptor(\.endDate)])
            self.goals = try modelContext.fetch(updatedDescriptor)
            print("Loaded \(self.goals.count) goals from local storage")
            self.updateFilteredGoals()
        } catch {
            print("Error syncing goals with local storage: \(error.localizedDescription)")
            self.errorMessage = "Failed to sync goals: \(error.localizedDescription)"
            self.showingError = true
            
            // Fallback to memory-only if local storage fails
            self.goals = firestoreGoals
            self.updateFilteredGoals()
        }
    }
    
    // Helper method to update goal properties
    private func updateGoalProperties(_ existingGoal: Goal, from firestoreGoal: Goal) {
        print("Updating existing goal: \(existingGoal.title)")
        existingGoal.title = firestoreGoal.title
        existingGoal.typeString = firestoreGoal.typeString
        existingGoal.targetValue = firestoreGoal.targetValue
        existingGoal.currentValue = firestoreGoal.currentValue
        existingGoal.startDate = firestoreGoal.startDate
        existingGoal.endDate = firestoreGoal.endDate
        existingGoal.timeframeString = firestoreGoal.timeframeString
        existingGoal.statusString = firestoreGoal.statusString
        existingGoal.notes = firestoreGoal.notes
        existingGoal.lastUpdated = firestoreGoal.lastUpdated
        existingGoal.linkedWorkoutType = firestoreGoal.linkedWorkoutType
        existingGoal.linkedHabitId = firestoreGoal.linkedHabitId
    }
    
    private func updateFilteredGoals() {
        // Filter goals into active and completed categories
        activeGoals = goals.filter { $0.status == .active }
        completedGoals = goals.filter { $0.status == .completed || $0.status == .failed || $0.status == .archived }
        
        print("Filtered goals: \(activeGoals.count) active, \(completedGoals.count) completed")
        
        // Check for expired goals and update their status
        let now = Date()
        for goal in activeGoals {
            if now > goal.endDate && goal.status == .active {
                print("Marking expired goal as failed: \(goal.title)")
                if goal.currentValue >= goal.targetValue {
                    goal.status = .completed
                } else {
                    goal.status = .failed
                }
                updateGoal(goal)
            }
        }
    }
    
    func addGoal(_ goal: Goal) {
        guard let userId = userId else {
            errorMessage = "User not authenticated"
            showingError = true
            return
        }
        
        // Add to local storage
        if let modelContext = modelContext {
            print("Adding goal to local storage: \(goal.title), ID: \(goal.id)")
            modelContext.insert(goal)
            do {
                try modelContext.save()
                print("Goal saved to local storage successfully")
                
                // Update the goals array
                self.goals.append(goal)
                
                // Important: Make sure to update filtered goals right away
                if goal.status == .active {
                    self.activeGoals.append(goal)
                } else if goal.status == .completed {
                    self.completedGoals.append(goal)
                }
                
                // Force UI update
                self.objectWillChange.send()
                
            } catch {
                print("Error saving goal locally: \(error.localizedDescription)")
                errorMessage = "Failed to save goal locally: \(error.localizedDescription)"
                showingError = true
            }
        } else {
            print("WARNING: modelContext is nil, goal will not be saved locally")
        }
        
        // Save to Firestore
        let db = FirebaseManager.shared.firestore
        let goalRef = db.collection("users").document(userId).collection("goals").document(goal.id)
        
        // Convert Goal to Dictionary
        let goalData = FirebaseManager.shared.dictionaryFromGoal(goal)
        
        // Save to Firestore
        print("Saving goal to Firestore: \(goal.title)")
        goalRef.setData(goalData) { [weak self] error in
            if let error = error {
                print("Error saving goal to Firestore: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self?.errorMessage = "Failed to save goal to cloud: \(error.localizedDescription)"
                    self?.showingError = true
                }
            } else {
                print("Goal saved to Firestore successfully")
                // Log analytics event
                FirebaseManager.shared.logEvent(name: "goal_added", parameters: ["goal_id": goal.id])
            }
        }
    }
    
    func updateGoal(_ goal: Goal) {
        guard let userId = userId else {
            errorMessage = "User not authenticated"
            showingError = true
            return
        }
        
        // Update in local storage
        if let modelContext = modelContext {
            do {
                try modelContext.save()
                print("Goal updated locally: \(goal.title)")
                self.updateFilteredGoals()
            } catch {
                print("Error updating goal locally: \(error.localizedDescription)")
                errorMessage = "Failed to update goal locally: \(error.localizedDescription)"
                showingError = true
            }
        }
        
        // Update in Firestore
        let db = FirebaseManager.shared.firestore
        let goalRef = db.collection("users").document(userId).collection("goals").document(goal.id)
        
        // Convert Goal to Dictionary
        let goalData = FirebaseManager.shared.dictionaryFromGoal(goal)
        
        // Update in Firestore
        goalRef.setData(goalData) { [weak self] error in
            if let error = error {
                print("Error updating goal in Firestore: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self?.errorMessage = "Failed to update goal in cloud: \(error.localizedDescription)"
                    self?.showingError = true
                }
            } else {
                print("Goal updated in Firestore successfully")
                // Log analytics event
                FirebaseManager.shared.logEvent(name: "goal_updated", parameters: ["goal_id": goal.id])
            }
        }
    }
    
    func deleteGoal(_ goal: Goal) {
        guard let userId = userId else {
            errorMessage = "User not authenticated"
            showingError = true
            return
        }
        
        // Delete from local storage
        if let modelContext = modelContext {
            modelContext.delete(goal)
            do {
                try modelContext.save()
                print("Goal deleted from local storage: \(goal.title)")
                if let index = self.goals.firstIndex(where: { $0.id == goal.id }) {
                    self.goals.remove(at: index)
                }
                self.updateFilteredGoals()
            } catch {
                print("Error deleting goal locally: \(error.localizedDescription)")
                errorMessage = "Failed to delete goal locally: \(error.localizedDescription)"
                showingError = true
            }
        }
        
        // Delete from Firestore
        let db = FirebaseManager.shared.firestore
        let goalRef = db.collection("users").document(userId).collection("goals").document(goal.id)
        
        goalRef.delete { [weak self] error in
            if let error = error {
                print("Error deleting goal from Firestore: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self?.errorMessage = "Failed to delete goal from cloud: \(error.localizedDescription)"
                    self?.showingError = true
                }
            } else {
                print("Goal deleted from Firestore successfully")
                // Log analytics event
                FirebaseManager.shared.logEvent(name: "goal_deleted", parameters: ["goal_id": goal.id])
            }
        }
    }
    
    // MARK: - Progress Tracking
    
    // Update goals based on a completed workout
    func updateGoalsForWorkout(_ workout: Workout) {
        print("Updating goals for workout: \(workout.name)")
        for goal in activeGoals {
            // For workout count goals
            if goal.type == .workout {
                // If linked to a specific workout type
                if let linkedType = goal.linkedWorkoutType {
                    if workout.typeName == linkedType {
                        print("Updating linked workout type goal: \(goal.title)")
                        goal.incrementProgress()
                        updateGoal(goal)
                    }
                } else {
                    // Goal for any workout type
                    print("Updating general workout goal: \(goal.title)")
                    goal.incrementProgress()
                    updateGoal(goal)
                }
            }
            
            // For distance goals
            if goal.type == .distance, let workoutDistance = workout.distance {
                print("Updating distance goal: \(goal.title)")
                goal.incrementProgress(by: workoutDistance)
                updateGoal(goal)
            }
            
            // For duration goals
            if goal.type == .duration {
                print("Updating duration goal: \(goal.title)")
                goal.incrementProgress(by: workout.duration / 60.0)  // Convert seconds to minutes
                updateGoal(goal)
            }
        }
        
        // Log analytics for workout goal progress
        FirebaseManager.shared.logEvent(name: "workout_goal_progress", parameters: [
            "workout_type": workout.typeName,
            "duration": workout.duration,
            "distance": workout.distance ?? 0
        ])
    }
    
    // Update goals based on habit completion
    func updateGoalsForHabit(_ habit: Habit, completed: Bool) {
        print("Updating goals for habit: \(habit.name), completed: \(completed)")
        for goal in activeGoals {
            // For habit completion goals
            if goal.type == .habit {
                // If linked to a specific habit
                if let linkedHabitId = goal.linkedHabitId {
                    if habit.id == linkedHabitId && completed {
                        print("Updating linked habit goal: \(goal.title)")
                        goal.incrementProgress()
                        updateGoal(goal)
                    }
                } else if completed {
                    // Goal for any habit completion
                    print("Updating general habit goal: \(goal.title)")
                    goal.incrementProgress()
                    updateGoal(goal)
                }
            }
            
            // For streak goals
            if goal.type == .streak && habit.currentStreak > Int(goal.currentValue) {
                print("Updating streak goal: \(goal.title), new streak: \(habit.currentStreak)")
                goal.updateProgress(newValue: Double(habit.currentStreak))
                updateGoal(goal)
            }
        }
    }
    
    // New method specifically for streak goals
    func updateStreakGoals(_ habit: Habit) {
        print("Updating streak goals for habit: \(habit.name), current streak: \(habit.currentStreak)")
        for goal in activeGoals where goal.type == .streak {
            // If goal is linked to a specific habit
            if let linkedHabitId = goal.linkedHabitId {
                if habit.id == linkedHabitId && habit.currentStreak > Int(goal.currentValue) {
                    print("Updating linked streak goal: \(goal.title) to \(habit.currentStreak)")
                    goal.updateProgress(newValue: Double(habit.currentStreak))
                    updateGoal(goal)
                }
            }
            // For general streak goals (not linked to specific habit)
            else if goal.linkedHabitId == nil && habit.currentStreak > Int(goal.currentValue) {
                print("Updating general streak goal: \(goal.title) to \(habit.currentStreak)")
                goal.updateProgress(newValue: Double(habit.currentStreak))
                updateGoal(goal)
            }
        }
        
        // Log streak milestone events
        if habit.currentStreak % 7 == 0 {
            FirebaseManager.shared.logEvent(name: "habit_streak_milestone", parameters: [
                "habit_id": habit.id,
                "streak": habit.currentStreak,
                "category": habit.categoryName
            ])
        }
    }
    
    // MARK: - Helper Methods
    
    // Suggested goals for different user levels
    func getSuggestedGoals() -> [Goal] {
        guard let userId = userId else { return [] }
        
        let calendar = Calendar.current
        let now = Date()
        let oneWeekLater = calendar.date(byAdding: .day, value: 7, to: now)!
        
        return [
            Goal(userId: userId, title: "Complete 3 workouts this week", type: .workout, targetValue: 3, startDate: now, endDate: oneWeekLater),
            Goal(userId: userId, title: "Run 10km this week", type: .distance, targetValue: 10, startDate: now, endDate: oneWeekLater, linkedWorkoutType: WorkoutType.running.rawValue),
            Goal(userId: userId, title: "Maintain a 7-day streak for one habit", type: .streak, targetValue: 7, startDate: now, endDate: oneWeekLater)
        ]
    }
}
