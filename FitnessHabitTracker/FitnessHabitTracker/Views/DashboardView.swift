//
//  DashboardView.swift
//  FitnessHabitTracker
//
//  Updated with custom background image, nearby gyms feature, and CoreML integration

import SwiftUI
import SwiftData
import Charts

// Model for daily activity data
struct DayActivity {
    var id = UUID()
    var date: Date
    var dayLabel: String
    var calories: Double
}

struct DashboardView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var workoutViewModel: WorkoutViewModel
    @EnvironmentObject var habitViewModel: HabitViewModel
    @EnvironmentObject var goalViewModel: GoalViewModel
    
    @State private var selectedTab = 0
    @Environment(\.colorScheme) var colorScheme
    @State private var showingAddWorkout = false
    @State private var showingWorkoutTab = false
    @State private var showingWeatherDetail = false
    @State private var showingGoalsView = false
    @State private var showingAddGoal = false
    @State private var showingGoalAnalytics = false
    
    // New state for gyms feature
    @State private var showingAllGyms = false
    
    private let calendar = Calendar.current
    
    // MARK: - UI Constants
    private let cardCornerRadius: CGFloat = 15
    private let cardPadding: CGFloat = 16
    private let cardSpacing: CGFloat = 15
    private let sectionSpacing: CGFloat = 20
    
    var body: some View {
        // Approach #2: Using background modifier on the entire TabView
        TabView(selection: $selectedTab) {
            // Home Tab
            NavigationView {
                ScrollView {
                    VStack(alignment: .leading, spacing: sectionSpacing) {
                        // Welcome Section with enhanced styling
                        VStack(alignment: .leading) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Welcome, \(authViewModel.currentUser?.name.components(separatedBy: " ").first ?? "User")!")
                                        .font(.title)
                                        .fontWeight(.bold)
                                        .foregroundColor(.primary)
                                    
                                    Text("Here's your fitness and habit summary")
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 10)
                        
                        // Enhanced Weather Section
                        weatherSectionView
                        
                        // ML-Powered Workout Suggestions
                        WorkoutSuggestionsView()
                            .environmentObject(workoutViewModel)
                            .background(
                                RoundedRectangle(cornerRadius: cardCornerRadius)
                                    .fill(Color(UIColor.systemBackground).opacity(0.7))
                                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                            )
                            .padding(.horizontal)
                        
                        // NEW: Nearby Gyms Section
                        NearbyGymsDashboardView()
                            .background(
                                RoundedRectangle(cornerRadius: cardCornerRadius)
                                    .fill(Color(UIColor.systemBackground).opacity(0.7))
                                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                            )
                            .padding(.horizontal)
                        
                        // Goals Dashboard Section with improved visuals
                        goalsDashboardView
                            .background(
                                RoundedRectangle(cornerRadius: cardCornerRadius)
                                    .fill(Color(UIColor.systemBackground).opacity(0.7))
                                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                            )
                            .padding(.horizontal)
                        
                        // Weather-friendly Activities for Today
                        weatherFriendlyActivitiesView
                            .padding(.top, 5)
                        
                        // Fitness Activity Chart with improved styling
                        activityChartView
                            .background(
                                RoundedRectangle(cornerRadius: cardCornerRadius)
                                    .fill(Color(UIColor.systemBackground).opacity(0.7))
                                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                            )
                            .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
                .navigationBarItems(trailing:
                    NavigationLink(destination: ProfileView().environmentObject(authViewModel)) {
                        Image(systemName: "person.circle")
                            .font(.system(size: 22))
                    }
                )
                .sheet(isPresented: $showingAddWorkout) {
                    NavigationView {
                        WorkoutFormView(isPresented: $showingAddWorkout)
                            .environmentObject(workoutViewModel)
                    }
                }
                .sheet(isPresented: $showingWeatherDetail) {
                    NavigationView {
                        WeatherDetailView(weatherViewModel: habitViewModel.weatherViewModel)
                            .environmentObject(habitViewModel)
                    }
                }
                .fullScreenCover(isPresented: $showingWorkoutTab) {
                    NavigationView {
                        WorkoutAnalyticsView(isPresented: $showingWorkoutTab)
                            .environmentObject(workoutViewModel)
                    }
                }
                .sheet(isPresented: $showingGoalsView) {
                    NavigationView {
                        GoalListView()
                            .environmentObject(goalViewModel)
                    }
                }
                .sheet(isPresented: $showingAddGoal) {
                    NavigationView {
                        GoalFormView(isPresented: $showingAddGoal)
                            .environmentObject(goalViewModel)
                            .environmentObject(workoutViewModel)
                            .environmentObject(habitViewModel)
                    }
                }
                .sheet(isPresented: $showingGoalAnalytics) {
                    NavigationView {
                        GoalAnalyticsView()
                            .environmentObject(goalViewModel)
                    }
                }
                .sheet(isPresented: $showingAllGyms) {
                    NearbyGymsView()
                }
                .refreshable {
                    // Allow the user to manually refresh data
                    habitViewModel.weatherViewModel.refreshWeather()
                    workoutViewModel.loadWorkouts()
                    habitViewModel.loadHabits()
                    goalViewModel.loadGoals()
                    
                    // Also refresh gym data
                    GymFinderService.shared.refreshGyms()
                }
            }
            .tabItem {
                Label("Home", systemImage: "house")
            }
            .tag(0)
            
            // Workouts Tab
            NavigationView {
                WorkoutListView()
                    .environmentObject(workoutViewModel)
            }
            .tabItem {
                Label("Workouts", systemImage: "figure.walk")
            }
            .tag(1)
            
            // Habits Tab
            NavigationView {
                HabitListView()
                    .environmentObject(habitViewModel)
            }
            .tabItem {
                Label("Habits", systemImage: "checklist")
            }
            .tag(2)
            
            // Goals Tab
            NavigationView {
                GoalListView()
                    .environmentObject(goalViewModel)
            }
            .tabItem {
                Label("Goals", systemImage: "target")
            }
            .tag(3)
        }
        .background(
            Image("fitness_background")
                .resizable()
                .scaledToFill()
                .opacity(1)
                .ignoresSafeArea()
        )
        .onAppear {
            // Load data when dashboard appears
            workoutViewModel.loadWorkouts()
            habitViewModel.loadHabits()
            goalViewModel.loadGoals()
            
            // If no weather data yet or it's been more than 15 minutes, refresh
            if habitViewModel.weatherViewModel.currentWeather == nil ||
               (habitViewModel.weatherViewModel.lastUpdated != nil &&
                Date().timeIntervalSince(habitViewModel.weatherViewModel.lastUpdated!) > 900) {
                
                // Force a weather refresh
                habitViewModel.weatherViewModel.refreshWeather()
            }
            
            // Request location for weather and gyms when the view appears
            DispatchQueue.main.async {
                LocationManager.shared.requestLocation()
            }
            
            // Initialize gym finder service
            _ = GymFinderService.shared
            
            // Configure any notification permissions if needed
            UNUserNotificationCenter.current().getNotificationSettings { settings in
                if settings.authorizationStatus == .notDetermined {
                    NotificationManager.shared.requestAuthorization { _ in }
                }
            }
        }
    }
    
    // MARK: - Subviews
    
    private var weatherSectionView: some View {
        Group {
            if habitViewModel.weatherViewModel.isLoading {
                // Weather loading placeholder
                VStack(alignment: .center, spacing: 12) {
                    ProgressView()
                    Text("Loading weather data...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(cardPadding)
                .background(
                    RoundedRectangle(cornerRadius: cardCornerRadius)
                        .fill(Color.blue.opacity(0.1))
                        .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
                )
                .padding(.horizontal)
            } else if let weather = habitViewModel.weatherViewModel.currentWeather {
                Button(action: {
                    showingWeatherDetail = true
                }) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            if let iconURL = weather.weather.first?.iconURL {
                                AsyncImage(url: iconURL) { phase in
                                    switch phase {
                                    case .empty:
                                        ProgressView()
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                    case .failure:
                                        Image(systemName: weather.weather.first?.systemIconName ?? "cloud")
                                            .foregroundColor(.blue)
                                    @unknown default:
                                        EmptyView()
                                    }
                                }
                                .frame(width: 50, height: 50)
                            }
                            
                            VStack(alignment: .leading) {
                                Text(habitViewModel.weatherViewModel.locationName)
                                    .font(.headline)
                                
                                Text(weather.weather.first?.description.capitalized ?? "")
                                    .font(.subheadline)
                            }
                            
                            Spacer()
                            
                            Text("\(Int(weather.main.temp))°C")
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                        
                        // Additional weather details with enhanced styling
                        HStack(spacing: 20) {
                            WeatherDetailItem(
                                icon: "humidity",
                                value: "\(weather.main.humidity)%",
                                label: "Humidity"
                            )
                            
                            WeatherDetailItem(
                                icon: "wind",
                                value: "\(Int(weather.wind.speed * 3.6)) km/h",
                                label: "Wind"
                            )
                            
                            if weather.main.feelsLike != 0 {
                                WeatherDetailItem(
                                    icon: "thermometer",
                                    value: "\(Int(weather.main.feelsLike))°",
                                    label: "Feels like"
                                )
                            } else {
                                // Fallback
                                WeatherDetailItem(
                                    icon: "thermometer",
                                    value: "\(Int(weather.main.temp))°",
                                    label: "Temp"
                                )
                            }
                        }
                        
                        // Weather impact on today's habits
                        if let impactedHabits = getWeatherImpactedHabits(), !impactedHabits.isEmpty {
                            Divider()
                                .padding(.vertical, 6)
                                
                            Text("Weather impacts \(impactedHabits.count) of your habits today")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(cardPadding)
                    .background(
                        RoundedRectangle(cornerRadius: cardCornerRadius)
                            .fill(Color.blue.opacity(0.1))
                            .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
                    )
                    .padding(.horizontal)
                }
                .buttonStyle(PlainButtonStyle())
            } else if habitViewModel.weatherViewModel.errorMessage != nil {
                // Error state with retry button
                Button(action: {
                    habitViewModel.weatherViewModel.refreshWeather()
                }) {
                    VStack(alignment: .center, spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.title2)
                            .foregroundColor(.orange)
                        Text("Weather data unavailable")
                            .font(.subheadline)
                        Text("Tap to retry")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(cardPadding)
                    .background(
                        RoundedRectangle(cornerRadius: cardCornerRadius)
                            .fill(Color.blue.opacity(0.1))
                            .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
                    )
                    .padding(.horizontal)
                }
            } else {
                // Weather loading placeholder (fallback)
                VStack(alignment: .center, spacing: 12) {
                    ProgressView()
                    Text("Loading weather data...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(cardPadding)
                .background(
                    RoundedRectangle(cornerRadius: cardCornerRadius)
                        .fill(Color.blue.opacity(0.1))
                        .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
                )
                .padding(.horizontal)
            }
        }
    }
    
    private var goalsDashboardView: some View {
        VStack(alignment: .leading, spacing: 15) {
            // Header with title and buttons
            HStack {
                Text("Goals & Progress")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(action: {
                    showingGoalAnalytics = true
                }) {
                    Image(systemName: "chart.bar.xaxis")
                        .foregroundColor(.blue)
                        .padding(8)
                        .background(
                            Circle()
                                .fill(Color.blue.opacity(0.1))
                        )
                }
            }
            .padding(.horizontal)
            
            // Progress Overview with improved styling
            if !goalViewModel.activeGoals.isEmpty {
                HStack(spacing: 12) {
                    // Active Goals
                    VStack(spacing: 5) {
                        Text("\(goalViewModel.activeGoals.count)")
                            .font(.headline)
                            .fontWeight(.bold)
                        
                        Text("Active")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.blue.opacity(0.15))
                    )
                    
                    // Completed Goals
                    VStack(spacing: 5) {
                        Text("\(goalViewModel.completedGoals.count)")
                            .font(.headline)
                            .fontWeight(.bold)
                        
                        Text("Completed")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.green.opacity(0.15))
                    )
                    
                    // Average Progress
                    VStack(spacing: 5) {
                        Text("\(averageGoalProgress)%")
                            .font(.headline)
                            .fontWeight(.bold)
                        
                        Text("Progress")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.orange.opacity(0.15))
                    )
                }
                .padding(.horizontal)
            }
            
            // Goal Cards with improved visuals and uniform sizing
            if !goalViewModel.activeGoals.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: cardSpacing) {
                        ForEach(goalViewModel.activeGoals) { goal in
                            goalsCardView(goal)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 5)
            } else {
                // Empty state
                VStack(spacing: 15) {
                    Image(systemName: "target")
                        .font(.system(size: 40))
                        .foregroundColor(.blue.opacity(0.7))
                    
                    Text("No active goals yet")
                        .font(.headline)
                    
                    Button(action: {
                        showingAddGoal = true
                    }) {
                        Text("Create Your First Goal")
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.blue)
                            )
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
            }
        }
    }
    
    private func goalsCardView(_ goal: Goal) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header with icon and title
            HStack {
                Image(systemName: goal.type.icon)
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(8)
                    .background(goalColor(for: goal.type))
                    .cornerRadius(8)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(goal.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    
                    Text(goal.type.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Progress
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text("\(Int(goal.currentValue))/\(Int(goal.targetValue))")
                        .font(.subheadline)
                    
                    Spacer()
                    
                    Text("\(Int(goal.progress * 100))%")
                        .font(.subheadline)
                        .foregroundColor(progressColor(for: goal.progress))
                }
                
                // Progress bar with animation
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)
                        .cornerRadius(4)
                    
                    Rectangle()
                        .fill(progressColor(for: goal.progress))
                        .frame(width: max(CGFloat(goal.progress) * 170, 0), height: 8)
                        .cornerRadius(4)
                        .animation(.spring(response: 0.6, dampingFraction: 0.7), value: goal.progress)
                }
                
                // Time remaining
                HStack {
                    Image(systemName: "calendar")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if goal.remainingDays <= 0 {
                        Text("Due today!")
                            .font(.caption)
                            .foregroundColor(.red)
                    } else {
                        Text("\(goal.remainingDays) days left")
                            .font(.caption)
                            .foregroundColor(goal.remainingDays < 3 ? .red : .secondary)
                    }
                }
            }
        }
        .padding(cardPadding)
        .frame(width: 220, height: 160) // Fixed size for consistency
        .background(
            RoundedRectangle(cornerRadius: cardCornerRadius)
                .fill(Color(UIColor.secondarySystemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
        )
    }
    
    private var weatherFriendlyActivitiesView: some View {
        Group {
            if !habitViewModel.weatherSensitiveHabits.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Today's Weather-Friendly Activities")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: cardSpacing) {
                            ForEach(habitViewModel.weatherSensitiveHabits) { habit in
                                NavigationLink(destination: HabitDetailView(habit: habit)) {
                                    weatherHabitCardView(habit)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
        }
    }
    
    private func weatherHabitCardView(_ habit: Habit) -> some View {
        let isSuitable = habit.isWeatherSuitable(weatherData: habitViewModel.weatherViewModel.currentWeather)
        
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: habit.category.icon)
                    .font(.title3)
                    .foregroundColor(.white)
                    .padding(8)
                    .background(isSuitable ? Color.green : Color.orange)
                    .cornerRadius(8)
                
                Spacer()
                
                Text(isSuitable ? "Good Weather" : "Not Ideal")
                    .font(.caption)
                    .foregroundColor(isSuitable ? .green : .orange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(isSuitable ? Color.green.opacity(0.1) : Color.orange.opacity(0.1))
                    )
            }
            
            Text(habit.name)
                .font(.headline)
                .lineLimit(1)
            
            if habit.currentStreak > 0 {
                HStack {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                        .font(.caption)
                    
                    Text("\(habit.currentStreak) day streak")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if !isSuitable, let alternative = habit.indoorAlternative {
                Text("Try instead: \(alternative)")
                    .font(.caption)
                    .foregroundColor(.blue)
                    .lineLimit(1)
            }
        }
        .padding(cardPadding)
        .frame(width: 200, height: 140) // Fixed size for consistency
        .background(
            RoundedRectangle(cornerRadius: cardCornerRadius)
                .fill(Color(UIColor.secondarySystemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
        )
    }
    
    private var activityChartView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Activity Overview")
                .font(.headline)
                .padding(.horizontal)
            
            if workoutViewModel.workouts.isEmpty {
                Text("No workout data to display")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                VStack(spacing: 15) {
                    // Activity Chart
                    Chart {
                        ForEach(getLast7DaysActivity(), id: \.id) { data in
                            BarMark(
                                x: .value("Day", data.dayLabel),
                                y: .value("Calories", data.calories)
                            )
                            .foregroundStyle(Color.blue.gradient)
                        }
                    }
                    .frame(height: 180)
                    .padding(.horizontal)
                    
                    // Data insights with enhanced styling and consistent sizing
                    HStack {
                        weeklyInsightCardView(
                            title: "Total Duration",
                            value: formatDuration(calculateTotalDuration()),
                            iconName: "clock.fill",
                            color: .blue
                        )
                        
                        weeklyInsightCardView(
                            title: "Total Calories",
                            value: "\(Int(calculateTotalCalories())) kcal",
                            iconName: "flame.fill",
                            color: .orange
                        )
                    }
                    .padding(.horizontal)
                }
                
                // View More Button with enhanced styling
                Button(action: {
                    showingWorkoutTab = true
                }) {
                    Text("View Detailed Analytics")
                        .foregroundColor(.blue)
                        .font(.subheadline)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.blue.opacity(0.1))
                        )
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 10)
    }
    
    private func weeklyInsightCardView(title: String, value: String, iconName: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: iconName)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
        }
        .padding(cardPadding)
        .frame(height: 80) // Fixed height for consistency
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(color.opacity(0.1))
                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
    }
    
    // MARK: - Helper Methods
    
    // Get weather-impacted habits
    private func getWeatherImpactedHabits() -> [Habit]? {
        guard let weather = habitViewModel.weatherViewModel.currentWeather else { return nil }
        
        let impactedHabits = habitViewModel.weatherSensitiveHabits.filter { habit in
            !habit.isWeatherSuitable(weatherData: weather)
        }
        
        return impactedHabits.isEmpty ? nil : impactedHabits
    }
    
    // Get activity data for the last 7 days
    private func getLast7DaysActivity() -> [DayActivity] {
        var result: [DayActivity] = []
        let today = Date()
        
        for dayOffset in 0..<7 {
            let day = calendar.date(byAdding: .day, value: -dayOffset, to: today)!
            let dayStart = calendar.startOfDay(for: day)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
            
            // Get workouts for this day
            let dayWorkouts = workoutViewModel.workouts.filter {
                $0.date >= dayStart && $0.date < dayEnd
            }
            
            // Calculate total calories for the day
            let totalCalories = dayWorkouts.reduce(0) { $0 + $1.caloriesBurned }
            
            // Format day label
            let dayFormatter = DateFormatter()
            dayFormatter.dateFormat = dayOffset == 0 ? "Today" : "EEE"
            let dayLabel = dayOffset == 0 ? "Today" : dayFormatter.string(from: day)
            
            result.append(DayActivity(date: day, dayLabel: dayLabel, calories: totalCalories))
        }
        
        // Reverse so that "Today" is on the right
        return result.reversed()
    }
    
    // Calculate total duration for the last 7 days
    private func calculateTotalDuration() -> Double {
        let today = Date()
        let weekStart = calendar.date(byAdding: .day, value: -6, to: calendar.startOfDay(for: today))!
        
        return workoutViewModel.workouts
            .filter { $0.date >= weekStart }
            .reduce(0) { $0 + $1.duration }
    }
    
    // Calculate total calories for the last 7 days
    private func calculateTotalCalories() -> Double {
        let today = Date()
        let weekStart = calendar.date(byAdding: .day, value: -6, to: calendar.startOfDay(for: today))!
        
        return workoutViewModel.workouts
            .filter { $0.date >= weekStart }
            .reduce(0) { $0 + $1.caloriesBurned }
    }
    
    // Format duration in seconds to a readable string
    private func formatDuration(_ seconds: Double) -> String {
        let hours = Int(seconds / 3600)
        let minutes = Int((seconds.truncatingRemainder(dividingBy: 3600)) / 60)
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes) min"
        }
    }
    
    // Calculate average goal progress percentage
    private var averageGoalProgress: Int {
        if goalViewModel.activeGoals.isEmpty {
            return 0
        }
        
        let totalProgress = goalViewModel.activeGoals.reduce(0.0) { $0 + $1.progress }
        return Int((totalProgress / Double(goalViewModel.activeGoals.count)) * 100)
    }
    
    // Helper for goal type colors
    private func goalColor(for type: GoalType) -> Color {
        switch type {
        case .workout: return .blue
        case .habit: return .green
        case .distance: return .orange
        case .duration: return .purple
        case .streak: return .red
        case .weight: return .gray
        }
    }
    
    // Helper for progress colors
    private func progressColor(for progress: Double) -> Color {
        if progress < 0.3 {
            return .red
        } else if progress < 0.7 {
            return .orange
        } else {
            return .green
        }
    }
}

// Add a stub for WeatherDetailItem if it's not defined elsewhere
struct WeatherDetailItem: View {
    var icon: String
    var value: String
    var label: String
    
    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.blue)
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}
