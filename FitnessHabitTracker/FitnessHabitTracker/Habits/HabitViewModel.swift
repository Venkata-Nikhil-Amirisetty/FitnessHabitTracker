//
//  HabitViewModel.swift
//  FitnessHabitTracker
//
//  Created by Nikhil Av on 4/16/25.
//  Updated with import handling functionality and Goal integration


import SwiftUI
import Combine
import SwiftData
import FirebaseFirestore
import FirebaseAuth

@MainActor
class HabitViewModel: ObservableObject {
    @Published var errorMessage = ""
    @Published var showingError = false
    @Published var habits: [Habit] = []
    
    // Weather view model
    @Published var weatherViewModel = WeatherViewModel()
    
    private var modelContext: ModelContext?
    private var firestoreListener: ListenerRegistration?
    private var userId: String?
    private var cancellables = Set<AnyCancellable>()
    
    // Added reference to GoalViewModel for updating goals
    private weak var goalViewModel: GoalViewModel?
    
    var activeHabits: [Habit] {
        habits.filter { !$0.isArchived }
    }
    
    var topHabits: [Habit] {
        Array(activeHabits.sorted(by: { $0.currentStreak > $1.currentStreak }).prefix(5))
    }
    
    // Weather-sensitive habits
    var weatherSensitiveHabits: [Habit] {
        return activeHabits.filter { $0.isWeatherSensitive }
    }
    
    init(goalViewModel: GoalViewModel? = nil) {
        self.goalViewModel = goalViewModel
        
        // Listen for authentication changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(userDidChange),
            name: NSNotification.Name("UserDidChangeNotification"),
            object: nil
        )
        
        // Add observer for imported habits from JSON
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleImportedHabits),
            name: NSNotification.Name("ImportHabitsNotification"),
            object: nil
        )
        
        // Add observer for imported habits from CSV
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleImportedHabitsFromCSV),
            name: NSNotification.Name("ImportHabitsFromCSVNotification"),
            object: nil
        )
        
        // If a user is already authenticated, load habits
        if let currentUser = Auth.auth().currentUser {
            self.userId = currentUser.uid
            loadHabits()
        }
        
        // Initialize location services for weather data
        LocationManager.shared.requestLocation()
    }
    
    // Set the GoalViewModel reference
    func setGoalViewModel(_ viewModel: GoalViewModel) {
        self.goalViewModel = viewModel
        print("GoalViewModel reference set in HabitViewModel")
    }
    
    deinit {
        firestoreListener?.remove()
        NotificationCenter.default.removeObserver(self)
        cancellables.removeAll()
    }
    
    @objc func userDidChange(_ notification: Notification) {
        if let userInfo = notification.userInfo,
           let userId = userInfo["userId"] as? String {
            self.userId = userId
            loadHabits()
        } else {
            // User logged out
            self.userId = nil
            self.habits = []
            firestoreListener?.remove()
        }
    }
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        print("ModelContext set in HabitViewModel")
        
        if let firebaseUser = Auth.auth().currentUser {
            self.userId = firebaseUser.uid
            loadHabits()
        }
    }
    
    // MARK: - Import Handling
    
    @objc func handleImportedHabits(_ notification: Notification) {
        guard let habitsData = notification.userInfo?["habits"] as? [[String: Any]] else {
            print("No habit data found in notification")
            return
        }
        
        print("Received \(habitsData.count) habits to import")
        
        // Convert dates from strings to Date objects
        let dateFormatter = ISO8601DateFormatter()
        
        for var habitData in habitsData {
            // Convert date strings to Date objects
            if let startDateString = habitData["startDate"] as? String {
                habitData["startDate"] = dateFormatter.date(from: startDateString) ?? Date()
            }
            // Convert completed dates array to Date objects
                        if let completedDatesStrings = habitData["completedDates"] as? [String] {
                            habitData["completedDates"] = completedDatesStrings.compactMap {
                                dateFormatter.date(from: $0)
                            }
                        }
                        
                        // Convert reminder time if present
                        if let reminderTimeString = habitData["reminderTime"] as? String {
                            habitData["reminderTime"] = dateFormatter.date(from: reminderTimeString)
                        }
                        
                        // Create habit from dictionary
                        if let habit = processHabitFromDictionary(habitData) {
                            print("Processing habit: \(habit.name)")
                            // Add to database (this will update the UI)
                            DispatchQueue.main.async {
                                self.addHabit(habit)
                            }
                        }
                    }
                    
                    // Force UI refresh
                    DispatchQueue.main.async {
                        self.objectWillChange.send()
                    }
                }
                
                @objc func handleImportedHabitsFromCSV(_ notification: Notification) {
                    guard let csvData = notification.userInfo?["csvData"] as? [String] else {
                        print("No CSV habit data found in notification")
                        return
                    }
                    
                    print("Received \(csvData.count) lines of CSV habit data to import")
                    
                    // First line should be headers
                    guard csvData.count > 1 else { return }
                    
                    let headers = csvData[0].components(separatedBy: ",")
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd"
                    
                    // Process each data row
                    for i in 1..<csvData.count {
                        let line = csvData[i]
                        let components = parseCSVLine(line)
                        
                        guard components.count >= 6 else { continue }
                        
                        // Map CSV components to habit properties using headers
                        var habitData: [String: Any] = [:]
                        
                        for (index, header) in headers.enumerated() {
                            if index < components.count {
                                let key = header.trimmingCharacters(in: .whitespacesAndNewlines)
                                let value = components[index].trimmingCharacters(in: .whitespacesAndNewlines)
                                
                                // Remove quotes if present
                                let cleanValue = value.replacingOccurrences(of: "\"", with: "")
                                
                                // Parse values correctly based on type
                                if key == "id" || key == "name" || key == "category" || key == "frequency" || key == "description" {
                                    habitData[key] = cleanValue
                                } else if key == "targetDaysPerWeek" {
                                    habitData[key] = Int(cleanValue) ?? 7
                                } else if key == "startDate" {
                                    habitData[key] = dateFormatter.date(from: cleanValue) ?? Date()
                                } else if key == "isArchived" || key == "isWeatherSensitive" {
                                    habitData[key] = cleanValue.lowercased() == "true"
                                }
                            }
                        }
                        
                        // Create habit from processed data
                        if let habit = processHabitFromCSV(habitData) {
                            print("Processed habit from CSV: \(habit.name)")
                            // Add to database
                            DispatchQueue.main.async {
                                self.addHabit(habit)
                            }
                        }
                    }
                    
                    // Force UI refresh
                    DispatchQueue.main.async {
                        self.objectWillChange.send()
                    }
                }
                
                private func parseCSVLine(_ line: String) -> [String] {
                    var result: [String] = []
                    var currentValue = ""
                    var inQuotes = false
                    
                    for char in line {
                        if char == "\"" {
                            inQuotes = !inQuotes
                        } else if char == "," && !inQuotes {
                            result.append(currentValue)
                            currentValue = ""
                        } else {
                            currentValue.append(char)
                        }
                    }
                    
                    // Add the last value
                    result.append(currentValue)
                    
                    return result
                }
                
                private func processHabitFromDictionary(_ data: [String: Any]) -> Habit? {
                    // Required fields
                    guard let id = data["id"] as? String,
                          let name = data["name"] as? String,
                          let categoryName = data["categoryName"] as? String,
                          let frequencyName = data["frequencyName"] as? String,
                          let targetDaysPerWeek = data["targetDaysPerWeek"] as? Int else {
                        print("Missing required fields for habit: id, name, categoryName, frequencyName, or targetDaysPerWeek")
                        if let id = data["id"] as? String {
                            print("Habit ID: \(id)")
                        }
                        if let name = data["name"] as? String {
                            print("Habit name: \(name)")
                        }
                        print("Available keys: \(data.keys.joined(separator: ", "))")
                        return nil
                    }
                    
                    // Get category and frequency
                    let category = HabitCategory(rawValue: categoryName) ?? .other
                    let frequency = HabitFrequency(rawValue: frequencyName) ?? .daily
                    
                    // Get optional fields
                    let description = data["descriptionText"] as? String
                    let isArchived = data["isArchived"] as? Bool ?? false
                    
                    // Get dates
                    let startDate = data["startDate"] as? Date ?? Date()
                    let completedDates = data["completedDates"] as? [Date] ?? []
                    let reminderTime = data["reminderTime"] as? Date
                    
                    // Create habit
                    let habit = Habit(
                        id: id,
                        name: name,
                        descriptionText: description,
                        category: category,
                        frequency: frequency,
                        targetDaysPerWeek: targetDaysPerWeek,
                        reminderTime: reminderTime,
                        startDate: startDate,
                        completedDates: completedDates,
                        isArchived: isArchived
                    )
                    
                    // Set weather sensitivity if present
                    if let isWeatherSensitive = data["isWeatherSensitive"] as? Bool {
                        habit.isWeatherSensitive = isWeatherSensitive
                    }
                    
                    // Set preferred weather conditions if present
                    if let preferredWeather = data["preferredWeatherConditions"] as? [String] {
                        habit.preferredWeatherConditions = preferredWeather
                    }
                    
                    // Set indoor alternative if present
                    if let indoorAlternative = data["indoorAlternative"] as? String {
                        habit.indoorAlternative = indoorAlternative
                    }
                    
                    return habit
                }
                
                private func processHabitFromCSV(_ data: [String: Any]) -> Habit? {
                    // Required fields
                    guard let id = data["id"] as? String,
                          let name = data["name"] as? String,
                          let categoryStr = data["category"] as? String,
                          let frequencyStr = data["frequency"] as? String else {
                        print("Missing required fields for habit from CSV")
                        return nil
                    }
                    
                    // Parse fields
                    let category = HabitCategory(rawValue: categoryStr) ?? .other
                    let frequency = HabitFrequency(rawValue: frequencyStr) ?? .daily
                    let targetDaysPerWeek = data["targetDaysPerWeek"] as? Int ?? 7
                    let startDate = data["startDate"] as? Date ?? Date()
                    let description = data["description"] as? String
                    let isArchived = data["isArchived"] as? Bool ?? false
                    let isWeatherSensitive = data["isWeatherSensitive"] as? Bool ?? false
                    
                    // Create habit with empty completed dates (CSV format limitation)
                    let habit = Habit(
                        id: id,
                        name: name,
                        descriptionText: description,
                        category: category,
                        frequency: frequency,
                        targetDaysPerWeek: targetDaysPerWeek,
                        reminderTime: nil, // CSV doesn't have reminder time format
                        startDate: startDate,
                        completedDates: [],
                        isArchived: isArchived
                    )
                    
                    // Set weather sensitivity
                    habit.isWeatherSensitive = isWeatherSensitive
                    
                    return habit
                }
                
                // MARK: - Data Operations
                
                func loadHabits() {
                    guard let userId = userId else {
                        // No authenticated user
                        self.habits = []
                        return
                    }
                    
                    print("Loading habits for user: \(userId)")
                    
                    // First, try to load from local SwiftData store
                    if let modelContext = modelContext {
                        do {
                            let descriptor = FetchDescriptor<Habit>()
                            let localHabits = try modelContext.fetch(descriptor)
                            
                            if !localHabits.isEmpty {
                                print("Found \(localHabits.count) habits in local storage")
                                self.habits = localHabits
                            }
                        } catch {
                            print("Error fetching local habits: \(error.localizedDescription)")
                        }
                    }
                    
                    // Remove any existing listener
                    firestoreListener?.remove()
                    
                    // Set up real-time listener for user's habits
                    let db = FirebaseManager.shared.firestore
                    let habitsRef = db.collection("users").document(userId).collection("habits")
                    
                    firestoreListener = habitsRef.addSnapshotListener { [weak self] snapshot, error in
                        guard let self = self else { return }
                        if let error = error {
                            DispatchQueue.main.async {
                                self.errorMessage = "Failed to load habits: \(error.localizedDescription)"
                                self.showingError = true
                            }
                            return
                        }
                        
                        guard let documents = snapshot?.documents else {
                            DispatchQueue.main.async {
                                self.habits = []
                            }
                            return
                        }
                        
                        // Parse Firestore documents into Habit objects
                        let firestoreHabits = documents.compactMap { document -> Habit? in
                            do {
                                let data = document.data()
                                return FirebaseManager.shared.habitFromDictionary(data)
                            } catch {
                                print("Error parsing document: \(error.localizedDescription)")
                                return nil
                            }
                        }
                        
                        // Convert to local Habit models and save to SwiftData
                        self.syncHabitsWithLocal(firestoreHabits)
                    }
                }
                
                private func syncHabitsWithLocal(_ firestoreHabits: [Habit]) {
                    guard let modelContext = modelContext else {
                        self.habits = firestoreHabits
                        return
                    }
                    
                    // Get existing habits from SwiftData
                    do {
                        let descriptor = FetchDescriptor<Habit>()
                        let existingHabits = try modelContext.fetch(descriptor)
                        
                        // Prepare ID sets for quick lookups
                        let existingIds = Set(existingHabits.map { $0.id })
                        let firestoreIds = Set(firestoreHabits.map { $0.id })
                        
                        // Add new habits
                        for firestoreHabit in firestoreHabits {
                            if !existingIds.contains(firestoreHabit.id) {
                                modelContext.insert(firestoreHabit)
                            }
                        }
                        
                        // Remove deleted habits
                        for habit in existingHabits {
                            if !firestoreIds.contains(habit.id) {
                                modelContext.delete(habit)
                            }
                        }
                        
                        // Update existing habits
                        for firestoreHabit in firestoreHabits {
                            if let existingHabit = existingHabits.first(where: { $0.id == firestoreHabit.id }) {
                                // Update properties
                                existingHabit.name = firestoreHabit.name
                                existingHabit.descriptionText = firestoreHabit.descriptionText
                                existingHabit.categoryName = firestoreHabit.categoryName
                                existingHabit.frequencyName = firestoreHabit.frequencyName
                                existingHabit.targetDaysPerWeek = firestoreHabit.targetDaysPerWeek
                                existingHabit.reminderTime = firestoreHabit.reminderTime
                                existingHabit.startDate = firestoreHabit.startDate
                                existingHabit.completedDates = firestoreHabit.completedDates
                                existingHabit.isArchived = firestoreHabit.isArchived
                            }
                        }
                        
                        // Make sure to save changes to persistent storage
                        try modelContext.save()
                        
                        // Update published property with latest data
                        let updatedDescriptor = FetchDescriptor<Habit>(sortBy: [SortDescriptor(\.name)])
                        self.habits = try modelContext.fetch(updatedDescriptor)
                    } catch {
                        self.errorMessage = "Failed to sync habits: \(error.localizedDescription)"
                        self.showingError = true
                        
                        // Fallback to memory-only if local storage fails
                        self.habits = firestoreHabits
                    }
                }
                
                func addHabit(_ habit: Habit) {
                    guard let userId = userId else {
                        self.errorMessage = "User not authenticated"
                        self.showingError = true
                        return
                    }
                    
                    print("Adding habit: \(habit.name)")
                    
                    // Add to local storage
                    if let modelContext = modelContext {
                        modelContext.insert(habit)
                        do {
                            try modelContext.save()
                            self.habits.append(habit)
                            self.objectWillChange.send()
                        } catch {
                            self.errorMessage = "Failed to save habit locally: \(error.localizedDescription)"
                            self.showingError = true
                        }
                    }
                    
                    // Save to Firestore
                    let db = FirebaseManager.shared.firestore
                    let habitRef = db.collection("users").document(userId).collection("habits").document(habit.id)
                    
                    // Convert Habit to Dictionary
                    let habitData = FirebaseManager.shared.dictionaryFromHabit(habit)
                    
                    // Save to Firestore
                    habitRef.setData(habitData) { [weak self] error in
                        if let error = error {
                            DispatchQueue.main.async {
                                self?.errorMessage = "Failed to save habit to cloud: \(error.localizedDescription)"
                                self?.showingError = true
                            }
                        } else {
                            // Log analytics event
                            FirebaseManager.shared.logEvent(name: "habit_added", parameters: ["habit_id": habit.id])
                            
                            // Check if we should suggest creating a goal
                            DispatchQueue.main.async {
                                self?.showHabitGoalCreationPrompt(for: habit)
                            }
                        }
                    }
                }
                
                func updateHabit(_ habit: Habit) {
                    guard let userId = userId else {
                        self.errorMessage = "User not authenticated"
                        self.showingError = true
                        return
                    }
                    
                    // Update in local storage
                    if let modelContext = modelContext {
                        do {
                            try modelContext.save()
                            self.objectWillChange.send()
                        } catch {
                            self.errorMessage = "Failed to update habit locally: \(error.localizedDescription)"
                            self.showingError = true
                        }
                    }
                    
                    // Update in Firestore
                    let db = FirebaseManager.shared.firestore
                    let habitRef = db.collection("users").document(userId).collection("habits").document(habit.id)
                    
                    // Convert Habit to Dictionary
                    let habitData = FirebaseManager.shared.dictionaryFromHabit(habit)
                    
                    // Update in Firestore
                    habitRef.setData(habitData) { [weak self] error in
                        if let error = error {
                            DispatchQueue.main.async {
                                self?.errorMessage = "Failed to update habit in cloud: \(error.localizedDescription)"
                                self?.showingError = true
                            }
                        } else {
                            // Log analytics event
                            FirebaseManager.shared.logEvent(name: "habit_updated", parameters: ["habit_id": habit.id])
                        }
                    }
                }
                
                func deleteHabit(_ habit: Habit) {
                    guard let userId = userId else {
                        self.errorMessage = "User not authenticated"
                        self.showingError = true
                        return
                    }
                    
                    // Delete from local storage
                    if let modelContext = modelContext {
                        modelContext.delete(habit)
                        do {
                            try modelContext.save()
                            if let index = self.habits.firstIndex(where: { $0.id == habit.id }) {
                                self.habits.remove(at: index)
                            }
                            self.objectWillChange.send()
                        } catch {
                            self.errorMessage = "Failed to delete habit locally: \(error.localizedDescription)"
                            self.showingError = true
                        }
                    }
                    
                    // Delete from Firestore
                    let db = FirebaseManager.shared.firestore
                    let habitRef = db.collection("users").document(userId).collection("habits").document(habit.id)
                    
                    habitRef.delete { [weak self] error in
                        if let error = error {
                            DispatchQueue.main.async {
                                self?.errorMessage = "Failed to delete habit from cloud: \(error.localizedDescription)"
                                self?.showingError = true
                            }
                        } else {
                            // Log analytics event
                            FirebaseManager.shared.logEvent(name: "habit_deleted", parameters: ["habit_id": habit.id])
                        }
                    }
                }
                
                // In HabitViewModel.swift
                func toggleHabitCompletion(_ habit: Habit) {
                    let today = Calendar.current.startOfDay(for: Date())
                    
                    // Check if habit is already completed today
                    let wasCompleted = habit.completedDates.contains(where: { Calendar.current.isDate($0, inSameDayAs: today) })
                    
                    if wasCompleted {
                        // If completed, remove the completion
                        habit.completedDates.removeAll(where: { Calendar.current.isDate($0, inSameDayAs: today) })
                    } else {
                        // If not completed, add completion for today
                        habit.completedDates.append(today)
                    }
                    
                    // Notify observers of change immediately before saving
                    self.objectWillChange.send()
                    
                    // Update the habit in both local and cloud storage
                    updateHabit(habit)
                    
                    // Key fix: Update goals when habit completion changes
                    // Update goals directly to increment by 1
                    if let goalViewModel = self.goalViewModel {
                        // If marking as complete, increment relevant goals
                        if !wasCompleted { // Important! Only increment when going from not completed to completed
                            // Find all habit-type goals linked to this habit
                            let linkedGoals = goalViewModel.activeGoals.filter { goal in
                                if goal.type == .habit {
                                    if let linkedHabitId = goal.linkedHabitId {
                                        return linkedHabitId == habit.id
                                    }
                                    return goal.linkedHabitId == nil // General habit goals
                                }
                                return false
                            }
                            
                            // Increment each linked goal
                            for goal in linkedGoals {
                                goal.incrementProgress()
                                goalViewModel.updateGoal(goal)
                            }
                        } else {
                            // If marking as incomplete, decrement relevant goals
                            // Find all habit-type goals linked to this habit
                            let linkedGoals = goalViewModel.activeGoals.filter { goal in
                                if goal.type == .habit {
                                    if let linkedHabitId = goal.linkedHabitId {
                                        return linkedHabitId == habit.id
                                    }
                                    return goal.linkedHabitId == nil // General habit goals
                                }
                                return false
                            }
                            
                            // Decrement each linked goal (never below zero)
                            for goal in linkedGoals {
                                let newValue = max(0, goal.currentValue - 1)
                                goal.updateProgress(newValue: newValue)
                                goalViewModel.updateGoal(goal)
                            }
                        }
                        
                        // Always update streak goals regardless of completion status
                        goalViewModel.updateStreakGoals(habit)
                    } else {
                        print("WARNING: GoalViewModel reference is nil, goals will not be updated")
                    }
                    
                    // Track analytics event
                    let eventName = wasCompleted ? "habit_uncompleted" : "habit_completed"
                    FirebaseManager.shared.logEvent(name: eventName, parameters: ["habit_id": habit.id])
                }
                
                func archiveHabit(_ habit: Habit) {
                    habit.isArchived = true
                    updateHabit(habit)
                    
                    // Track analytics event
                    FirebaseManager.shared.logEvent(name: "habit_archived", parameters: ["habit_id": habit.id])
                }
                
                // MARK: - Filtering Methods
                
                func filterHabits(by category: HabitCategory? = nil, showCompleted: Bool = false) -> [Habit] {
                    guard !habits.isEmpty else { return [] }
                    
                    var filtered = activeHabits
                    
                    // Filter by category if specified
                    if let category = category {
                        filtered = filtered.filter { $0.category == category }
                    }
                    
                    // Filter by completion status if needed
                    if showCompleted {
                        let today = Calendar.current.startOfDay(for: Date())
                        filtered = filtered.filter { habit in
                            habit.completedDates.contains(where: { Calendar.current.isDate($0, inSameDayAs: today) })
                        }
                    }
                    
                    return filtered
                }
                
                // MARK: - Weather-Related Methods
                
                // Update a habit with weather preferences
                func updateHabitWithWeatherPreferences(
                    habit: Habit,
                    isWeatherSensitive: Bool,
                    preferredWeatherConditions: [String],
                    indoorAlternative: String?
                ) {
                    habit.isWeatherSensitive = isWeatherSensitive
                    habit.preferredWeatherConditions = preferredWeatherConditions
                    habit.indoorAlternative = indoorAlternative
                    
                    // Update the habit in database
                    updateHabit(habit)
                }
                
                // Get weather recommendations for habits
                func getWeatherRecommendations() -> [String] {
                    var recommendations: [String] = []
                    
                    if let weather = weatherViewModel.currentWeather {
                        // General weather recommendations
                        if weather.main.isHot {
                            recommendations.append("It's hot today. Remember to stay hydrated during workouts.")
                        }
                        
                        if weather.weather.first?.isRainy == true {
                            recommendations.append("Rain expected. Consider indoor exercises today.")
                            
                            // Find outdoor habits that might be affected
                            let affectedHabits = habits.filter {
                                $0.isWeatherSensitive && !$0.isWeatherSuitable(weatherData: weather)
                            }
                            
                            if !affectedHabits.isEmpty {
                                recommendations.append("You have \(affectedHabits.count) weather-sensitive habits affected today.")
                            }
                        } else if weather.weather.first?.isClear == true && weather.main.temp > 15 && weather.main.temp < 25 {
                            recommendations.append("Perfect weather for outdoor activities today!")
                        }
                        
                        // If it's going to get hotter/colder, recommend appropriate timing
                        if let forecast = weatherViewModel.forecast.first,
                            forecast.main.temp > weather.main.temp + 5 {
                            recommendations.append("Temperature will rise later. Consider completing outdoor activities earlier.")
                        } else if let forecast = weatherViewModel.forecast.first,
                                  forecast.main.temp < weather.main.temp - 5 {
                            recommendations.append("Temperature will drop later. Consider planning outdoor activities accordingly.")
                        }
                    }
                    
                    return recommendations
                }
                
                // MARK: - Goal-related Methods
                
                // Check if the user has existing habit-related goals
                private func hasExistingHabitGoal(for habit: Habit) -> Bool {
                    guard let goalViewModel = goalViewModel else { return false }
                    
                    return goalViewModel.activeGoals.contains { goal in
                        if let linkedHabitId = goal.linkedHabitId {
                            return linkedHabitId == habit.id
                        }
                        return false
                    }
                }
                
                // Show goal creation prompt for habits
                func showHabitGoalCreationPrompt(for habit: Habit) {
                    // Only suggest if the user doesn't already have a goal for this habit
                    if !hasExistingHabitGoal(for: habit) {
                        // Create a notification to show goal suggestion UI
                        NotificationCenter.default.post(
                            name: NSNotification.Name("SuggestHabitGoal"),
                            object: nil,
                            userInfo: ["habit": habit]
                        )
                    }
                }
                
                // Create suggested goals for a habit
                func createSuggestedGoalsForHabit(_ habit: Habit) -> [Goal] {
                    guard let userId = userId else { return [] }
                    
                    var suggestedGoals: [Goal] = []
                    
                    // Create habit completion goal
                    let completionGoal = Goal(
                        userId: userId,
                        title: "Complete \(habit.name) 5 times",
                        type: .habit,
                        targetValue: 5,
                        timeframe: .weekly,
                        linkedHabitId: habit.id
                    )
                    suggestedGoals.append(completionGoal)
                    
                    // Create streak goal
                    let streakGoal = Goal(
                        userId: userId,
                        title: "Maintain a 7-day streak for \(habit.name)",
                        type: .streak,
                        targetValue: 7,
                        linkedHabitId: habit.id
                    )
                    suggestedGoals.append(streakGoal)
                    
                    return suggestedGoals
                }
            }
