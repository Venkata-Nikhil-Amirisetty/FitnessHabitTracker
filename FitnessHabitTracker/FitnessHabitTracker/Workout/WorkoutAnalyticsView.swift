//
//  WorkoutAnalyticsView.swift
//  FitnessHabitTracker
//
//  Created by Nikhil Av on 4/16/25.
//  Enhanced with Calendar view integration

import SwiftUI
import SwiftData
import Charts

struct WorkoutAnalyticsView: View {
    @EnvironmentObject var workoutViewModel: WorkoutViewModel
    @State private var selectedPeriod: TimePeriod = .month
    @State private var selectedMetric: AnalyticsMetric = .calories
    @State private var selectedChartType: ChartType = .bar
    @Binding var isPresented: Bool
    
    // View selection state
    @State private var selectedTab: AnalyticsTab = .charts
    
    // Calendar view state
    @State private var selectedDate = Date()
    @State private var monthOffset = 0
    
    private let calendar = Calendar.current
    
    // Add an initializer with default value for preview support
    init(isPresented: Binding<Bool> = .constant(false)) {
        self._isPresented = isPresented
    }
    
    private var workouts: [Workout] {
        workoutViewModel.workouts
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // View selector tabs
            Picker("View", selection: $selectedTab) {
                ForEach(AnalyticsTab.allCases, id: \.self) { tab in
                    Text(tab.title).tag(tab)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            .padding(.vertical, 8)
            
            // Show selected view
            if selectedTab == .charts {
                analyticsView
            } else {
                calendarView
            }
        }
        .navigationTitle("Workout Insights")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(leading: Button(action: {
            isPresented = false
        }) {
            HStack {
                Image(systemName: "chevron.left")
                Text("Back")
            }
        })
    }
    
    // MARK: - Analytics View
    
    var analyticsView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Time Period Picker
                Picker("Time Period", selection: $selectedPeriod) {
                    ForEach(TimePeriod.allCases, id: \.self) { period in
                        Text(period.rawValue).tag(period)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                // Summary Cards
                HStack(spacing: 15) {
                    SummaryCard(
                        value: String(format: "%.0f", totalCalories),
                        label: "Calories",
                        icon: "flame.fill",
                        color: .orange
                    )
                    
                    SummaryCard(
                        value: formatDuration(totalDuration),
                        label: "Duration",
                        icon: "clock.fill",
                        color: .blue
                    )
                    
                    SummaryCard(
                        value: "\(filteredWorkouts.count)",
                        label: "Workouts",
                        icon: "figure.walk",
                        color: .green
                    )
                }
                .padding(.horizontal)
                
                // Chart Options
                HStack {
                    Picker("Metric", selection: $selectedMetric) {
                        ForEach(AnalyticsMetric.allCases, id: \.self) { metric in
                            Text(metric.displayName).tag(metric)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    Picker("Chart Type", selection: $selectedChartType) {
                        ForEach(ChartType.allCases, id: \.self) { type in
                            Image(systemName: type.icon).tag(type)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .frame(width: 120)
                }
                .padding(.horizontal)
                
                // Chart View
                VStack(alignment: .leading, spacing: 10) {
                    Text("\(selectedMetric.displayName) by \(getChartGroupingLabel())")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    if chartData.isEmpty {
                        VStack {
                            Text("No data available for the selected period")
                                .foregroundColor(.gray)
                                .frame(height: 300)
                        }
                    } else {
                        Chart {
                            ForEach(chartData) { item in
                                switch selectedChartType {
                                case .bar:
                                    BarMark(
                                        x: .value("Category", item.label),
                                        y: .value(selectedMetric.displayName, item.value)
                                    )
                                    .foregroundStyle(Color.blue.gradient)
                                
                                case .line:
                                    LineMark(
                                        x: .value("Category", item.label),
                                        y: .value(selectedMetric.displayName, item.value)
                                    )
                                    .foregroundStyle(Color.green.gradient)
                                    .interpolationMethod(.catmullRom)
                                    .symbol(Circle().strokeBorder(lineWidth: 2))
                                }
                            }
                        }
                        .frame(height: 300)
                        .padding()
                    }
                }
                .background(Color.gray.opacity(0.1))
                .cornerRadius(15)
                .padding(.horizontal)
                
                // Workout Type Breakdown
                VStack(alignment: .leading, spacing: 10) {
                    Text("Workout Type Breakdown")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    if filteredWorkouts.isEmpty {
                        VStack {
                            Text("No data available for the selected period")
                                .foregroundColor(.gray)
                                .frame(height: 150)
                        }
                    } else {
                        VStack(spacing: 15) {
                            ForEach(typeBreakdownData, id: \.type) { data in
                                HStack {
                                    Image(systemName: data.type.icon)
                                        .foregroundColor(.white)
                                        .padding(8)
                                        .background(getColorForWorkoutType(data.type))
                                        .cornerRadius(8)
                                    
                                    Text(data.type.rawValue.capitalized)
                                        .font(.subheadline)
                                    
                                    Spacer()
                                    
                                    Text("\(data.count) workouts")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                    
                                    Text("\(Int(data.percentage))%")
                                        .font(.headline)
                                }
                            }
                        }
                        .padding()
                    }
                }
                .background(Color.gray.opacity(0.1))
                .cornerRadius(15)
                .padding(.horizontal)
                
                // Progress Insights
                VStack(alignment: .leading, spacing: 10) {
                    Text("Progress Insights")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    Text(getInsightText())
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .background(Color.gray.opacity(0.1))
                .cornerRadius(15)
                .padding(.horizontal)
            }
            .padding(.bottom, 30)
        }
    }
    
    // MARK: - Calendar View
    
    var calendarView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Summary cards
                HStack(spacing: 15) {
                    SummaryCard(
                        value: "\(workoutViewModel.workouts.count)",
                        label: "Total Workouts",
                        icon: "figure.walk",
                        color: .blue
                    )
                    
                    SummaryCard(
                        value: "\(activeDaysCount)",
                        label: "Active Days",
                        icon: "flame.fill",
                        color: .orange
                    )
                }
                .padding(.horizontal)
                
                // Calendar header with month navigation
                HStack {
                    Button(action: {
                        monthOffset -= 1
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.title3)
                            .foregroundColor(.blue)
                    }
                    
                    Spacer()
                    
                    Text(monthYearString(from: currentMonth))
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    Button(action: {
                        monthOffset += 1
                    }) {
                        Image(systemName: "chevron.right")
                            .font(.title3)
                            .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal)
                
                // Days of week header
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7)) {
                    ForEach(["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"], id: \.self) { day in
                        Text(day)
                            .font(.caption)
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal)
                
                // Calendar grid
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7)) {
                    ForEach(daysInMonth(), id: \.self) { date in
                        if let date = date {
                            // Using your existing CalendarDayView
                            CalendarDayView(
                                date: date,
                                selectedDate: $selectedDate,
                                hasWorkout: hasWorkoutOn(date: date),
                                workoutCount: workoutCountOn(date: date)
                            )
                            .onTapGesture {
                                selectedDate = date
                            }
                        } else {
                            // Empty cell for padding
                            Rectangle()
                                .fill(Color.clear)
                                .frame(height: 40)
                        }
                    }
                }
                .padding(.horizontal)
                
                // Selected day header
                HStack {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 1)
                        .padding(.horizontal)
                    
                    Text("Workouts on \(dayMonthString(from: selectedDate))")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 1)
                        .padding(.horizontal)
                }
                .padding(.vertical)
                
                // Workouts for selected day
                if let workoutsForDay = workoutsForSelectedDay(), !workoutsForDay.isEmpty {
                    VStack(spacing: 12) {
                        ForEach(workoutsForDay, id: \.id) { workout in
                            NavigationLink(destination: WorkoutDetailView(workout: workout)) {
                                // Using your existing CalendarWorkoutRow
                                CalendarWorkoutRow(workout: workout)
                            }
                        }
                    }
                    .padding(.horizontal)
                } else {
                    VStack(spacing: 15) {
                        Image(systemName: "calendar.badge.exclamationmark")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        
                        Text("No workouts on this day")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        Text("Add a workout to track your progress")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .frame(height: 200)
                }
                
                // Activity heatmap analysis
                VStack(alignment: .leading, spacing: 10) {
                    Text("Activity Pattern")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    Text(getActivityPatternInsight())
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .background(Color.gray.opacity(0.1))
                .cornerRadius(15)
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var filteredWorkouts: [Workout] {
        filterWorkoutsByPeriod(workouts, period: selectedPeriod)
    }
    
    private var totalCalories: Double {
        filteredWorkouts.reduce(0) { $0 + $1.caloriesBurned }
    }
    
    private var totalDuration: Double {
        filteredWorkouts.reduce(0) { $0 + $1.duration }
    }
    
    private var chartData: [ChartDataPoint] {
        switch selectedPeriod {
        case .today, .week:
            return getDailyData()
        case .month:
            return getWeeklyData()
        case .year:
            return getMonthlyData()
        case .allTime:
            return getMonthlyData()
        }
    }
    
    private var typeBreakdownData: [TypeBreakdown] {
        let totalCount = filteredWorkouts.count
        guard totalCount > 0 else { return [] }
        
        var workoutsByType: [WorkoutType: Int] = [:]
        
        for workout in filteredWorkouts {
            workoutsByType[workout.type, default: 0] += 1
        }
        
        return workoutsByType.map { (type, count) in
            let percentage = Double(count) / Double(totalCount) * 100
            return TypeBreakdown(type: type, count: count, percentage: percentage)
        }.sorted(by: { $0.count > $1.count })
    }
    
    private var activeDaysCount: Int {
        // Count unique days with workouts
        let uniqueDays = Set(workoutViewModel.workouts.map {
            calendar.startOfDay(for: $0.date)
        })
        return uniqueDays.count
    }
    
    // MARK: - Calendar Helper Methods
    
    private var currentMonth: Date {
        let today = Date()
        let components = calendar.dateComponents([.year, .month], from: today)
        let currentMonth = calendar.date(from: components)!
        return calendar.date(byAdding: .month, value: monthOffset, to: currentMonth)!
    }
    
    private func daysInMonth() -> [Date?] {
        let firstDayOfMonth = firstDay(of: currentMonth)
        let daysInMonth = calendar.range(of: .day, in: .month, for: currentMonth)!.count
        
        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth)
        let leadingEmptyCells = firstWeekday - 1
        
        var days = [Date?](repeating: nil, count: leadingEmptyCells)
        
        for day in 1...daysInMonth {
            if let date = calendar.date(bySetting: .day, value: day, of: firstDayOfMonth) {
                days.append(date)
            }
        }
        
        // Add trailing empty cells to complete the last week if needed
        let trailingEmptyCells = (7 - (days.count % 7)) % 7
        days.append(contentsOf: [Date?](repeating: nil, count: trailingEmptyCells))
        
        return days
    }
    
    private func firstDay(of month: Date) -> Date {
        let components = calendar.dateComponents([.year, .month], from: month)
        return calendar.date(from: components)!
    }
    
    private func monthYearString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }
    
    private func dayMonthString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter.string(from: date)
    }
    
    private func hasWorkoutOn(date: Date) -> Bool {
        return workoutViewModel.workouts.contains { workout in
            calendar.isDate(workout.date, inSameDayAs: date)
        }
    }
    
    private func workoutCountOn(date: Date) -> Int {
        return workoutViewModel.workouts.filter { workout in
            calendar.isDate(workout.date, inSameDayAs: date)
        }.count
    }
    
    private func workoutsForSelectedDay() -> [Workout]? {
        let workoutsForDay = workoutViewModel.workouts.filter { workout in
            calendar.isDate(workout.date, inSameDayAs: selectedDate)
        }
        return workoutsForDay.sorted(by: { $0.date > $1.date })
    }
    
    private func getActivityPatternInsight() -> String {
        guard !workoutViewModel.workouts.isEmpty else {
            return "No workout history yet. Start adding workouts to see your activity patterns."
        }
        
        // Find most active day of week
        var dayOfWeekCounts: [Int: Int] = [:]
        for workout in workoutViewModel.workouts {
            let dayOfWeek = calendar.component(.weekday, from: workout.date)
            dayOfWeekCounts[dayOfWeek, default: 0] += 1
        }
        
        let mostActiveDay = dayOfWeekCounts.max(by: { $0.value < $1.value })
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "EEEE" // Full day name
        
        // Get day name from weekday number
        let dayNames = ["", "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        let mostActiveDayName = mostActiveDay != nil ? dayNames[mostActiveDay!.key] : "none"
        
        // Find most common workout time
        var hourCounts: [Int: Int] = [:]
        for workout in workoutViewModel.workouts {
            let hour = calendar.component(.hour, from: workout.date)
            hourCounts[hour, default: 0] += 1
        }
        
        let mostCommonHour = hourCounts.max(by: { $0.value < $1.value })
        var timeOfDay = "varies"
        if let hour = mostCommonHour?.key {
            if hour >= 5 && hour < 12 {
                timeOfDay = "morning"
            } else if hour >= 12 && hour < 17 {
                timeOfDay = "afternoon"
            } else if hour >= 17 && hour < 21 {
                timeOfDay = "evening"
            } else {
                timeOfDay = "night"
            }
        }
        
        // Current month stats
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: Date()))!
        let currentMonthWorkouts = workoutViewModel.workouts.filter { $0.date >= startOfMonth }
        let workoutsThisMonth = currentMonthWorkouts.count
        
        return "You tend to be most active on \(mostActiveDayName)s, typically in the \(timeOfDay). You've completed \(workoutsThisMonth) workouts this month across \(activeDaysCount) active days. To improve consistency, consider scheduling workouts on your less active days."
    }
    
    // MARK: - Analytics Helper Methods
    
    private func filterWorkoutsByPeriod(_ workouts: [Workout], period: TimePeriod) -> [Workout] {
        let calendar = Calendar.current
        let now = Date()
        
        switch period {
        case .today:
            let startOfDay = calendar.startOfDay(for: now)
            return workouts.filter { $0.date >= startOfDay }
            
        case .week:
            let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
            return workouts.filter { $0.date >= startOfWeek }
            
        case .month:
            let components = calendar.dateComponents([.year, .month], from: now)
            let startOfMonth = calendar.date(from: components)!
            return workouts.filter { $0.date >= startOfMonth }
            
        case .year:
            let components = calendar.dateComponents([.year], from: now)
            let startOfYear = calendar.date(from: components)!
            return workouts.filter { $0.date >= startOfYear }
            
        case .allTime:
            return workouts
        }
    }
    
    private func getDailyData() -> [ChartDataPoint] {
        let calendar = Calendar.current
        let now = Date()
        
        // For today, show hourly breakdown
        if selectedPeriod == .today {
            var hourlyData: [Int: Double] = [:]
            let startOfDay = calendar.startOfDay(for: now)
            
            for hour in 0..<24 {
                hourlyData[hour] = 0
            }
            
            for workout in filteredWorkouts {
                let hourComponent = calendar.component(.hour, from: workout.date)
                let value = getValue(for: workout)
                hourlyData[hourComponent, default: 0] += value
            }
            
            return hourlyData.map { (hour, value) in
                let formatter = DateFormatter()
                formatter.dateFormat = "ha"
                let date = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: startOfDay)!
                return ChartDataPoint(label: formatter.string(from: date), value: value)
            }.sorted {
                guard let hour1 = Int($0.label.dropLast()), let hour2 = Int($1.label.dropLast()) else {
                    return false
                }
                return hour1 < hour2
            }
        }
        
        // For week, show daily breakdown
        var startDate: Date
        if selectedPeriod == .week {
            startDate = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
        } else {
            startDate = calendar.date(byAdding: .day, value: -6, to: now)!
        }
        
        var currentDate = startDate
        var dailyData: [ChartDataPoint] = []
        
        while currentDate <= now {
            let dayStart = calendar.startOfDay(for: currentDate)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
            
            let dayWorkouts = filteredWorkouts.filter {
                $0.date >= dayStart && $0.date < dayEnd
            }
            
            let dayValue = dayWorkouts.reduce(0) { $0 + getValue(for: $1) }
            
            let formatter = DateFormatter()
            formatter.dateFormat = "EEE"
            
            dailyData.append(ChartDataPoint(
                label: formatter.string(from: currentDate),
                value: dayValue
            ))
            
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }
        
        return dailyData
    }
    
    private func getWeeklyData() -> [ChartDataPoint] {
        let calendar = Calendar.current
        let now = Date()
        
        // Get start of month
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        
        // Calculate how many weeks in this month
        let weekRange = calendar.range(of: .weekOfMonth, in: .month, for: now)!
        let weekCount = weekRange.count
        
        var weeklyData: [ChartDataPoint] = []
        
        for weekOffset in 0..<weekCount {
            guard let weekStart = calendar.date(byAdding: .weekOfMonth, value: weekOffset, to: startOfMonth) else {
                continue
            }
            
            let nextWeekStart = calendar.date(byAdding: .weekOfMonth, value: 1, to: weekStart)!
            
            // Don't include future weeks
            if weekStart > now {
                break
            }
            
            let weekWorkouts = filteredWorkouts.filter {
                $0.date >= weekStart && $0.date < nextWeekStart
            }
            
            let weekValue = weekWorkouts.reduce(0) { $0 + getValue(for: $1) }
            
            let formatter = DateFormatter()
            formatter.dateFormat = "d"
            let weekLabel = "Week \(weekOffset + 1)"
            
            weeklyData.append(ChartDataPoint(
                label: weekLabel,
                value: weekValue
            ))
        }
        
        return weeklyData
    }
    
    private func getMonthlyData() -> [ChartDataPoint] {
        let calendar = Calendar.current
        let now = Date()
        
        // For yearly data, show monthly breakdown
        var monthlyData: [ChartDataPoint] = []
        
        let components = calendar.dateComponents([.year], from: now)
        let startOfYear = calendar.date(from: components)!
        
        for monthOffset in 0..<12 {
            guard let monthStart = calendar.date(byAdding: .month, value: monthOffset, to: startOfYear) else {
                continue
            }
            
            let nextMonthStart = calendar.date(byAdding: .month, value: 1, to: monthStart)!
            
            // Don't include future months
            if monthStart > now {
                break
            }
            
            let monthWorkouts = filteredWorkouts.filter {
                $0.date >= monthStart && $0.date < nextMonthStart
            }
            
            let monthValue = monthWorkouts.reduce(0) { $0 + getValue(for: $1) }
            
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM"
            
            monthlyData.append(ChartDataPoint(
                label: formatter.string(from: monthStart),
                value: monthValue
            ))
        }
        
        return monthlyData
    }
    
    private func getValue(for workout: Workout) -> Double {
        switch selectedMetric {
        case .calories:
            return workout.caloriesBurned
        case .duration:
            return workout.duration / 60 // in minutes
        case .count:
            return 1
        }
    }
    
    private func formatDuration(_ seconds: Double) -> String {
        let hours = Int(seconds / 3600)
        let minutes = Int((seconds.truncatingRemainder(dividingBy: 3600)) / 60)
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    private func getChartGroupingLabel() -> String {
        switch selectedPeriod {
        case .today:
            return "Hour"
        case .week:
            return "Day"
        case .month:
            return "Week"
        case .year, .allTime:
            return "Month"
        }
    }
    
    private func getColorForWorkoutType(_ type: WorkoutType) -> Color {
        switch type {
        case .running:
            return .blue
        case .walking:
            return .green
        case .cycling:
            return .orange
        case .swimming:
            return .cyan
        case .weightTraining:
            return .purple
        case .yoga:
            return .indigo
        case .hiit:
            return .red
        case .other:
            return .gray
        }
    }
    
    private func getInsightText() -> String {
        guard !filteredWorkouts.isEmpty else {
            return "No workouts available for analysis in the selected period."
        }
        
        // Generate some basic insights
        let mostCommonType = typeBreakdownData.first?.type.rawValue.capitalized ?? "None"
        let avgCaloriesPerWorkout = totalCalories / Double(filteredWorkouts.count)
        let avgDurationPerWorkout = totalDuration / Double(filteredWorkouts.count) / 60 // in minutes
        
        var insights = [
            "Your most frequent workout type is \(mostCommonType).",
            "You burn an average of \(Int(avgCaloriesPerWorkout)) calories per workout.",
            "Your average workout duration is \(Int(avgDurationPerWorkout)) minutes."
        ]
        
        // Add comparison to previous period if possible
        let calendar = Calendar.current
        var previousPeriodStartDate: Date?
        let now = Date()
        
        switch selectedPeriod {
        case .today:
            previousPeriodStartDate = calendar.date(byAdding: .day, value: -1, to: calendar.startOfDay(for: now))
        case .week:
            previousPeriodStartDate = calendar.date(byAdding: .weekOfMonth, value: -1, to: calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!)
        case .month:
            previousPeriodStartDate = calendar.date(byAdding: .month, value: -1, to: calendar.date(from: calendar.dateComponents([.year, .month], from: now))!)
        case .year:
            previousPeriodStartDate = calendar.date(byAdding: .year, value: -1, to: calendar.date(from: calendar.dateComponents([.year], from: now))!)
        case .allTime:
            previousPeriodStartDate = nil
        }
        
        if let previousStart = previousPeriodStartDate, let periodEnd = calendar.date(from: calendar.dateComponents([.year, .month, .day], from: now)) {
            let previousPeriodWorkouts = workouts.filter {
                $0.date >= previousStart && $0.date < periodEnd
            }
            
            if !previousPeriodWorkouts.isEmpty {
                let prevTotalCalories = previousPeriodWorkouts.reduce(0) { $0 + $1.caloriesBurned }
                let caloriesDiff = totalCalories - prevTotalCalories
                let caloriesChange = (caloriesDiff / prevTotalCalories) * 100
                
                if abs(caloriesChange) > 5 {
                    let direction = caloriesChange > 0 ? "up" : "down"
                    insights.append("Your calorie burn is \(direction) \(abs(Int(caloriesChange)))% compared to the previous period.")
                }
                
                let prevCount = previousPeriodWorkouts.count
                let countDiff = filteredWorkouts.count - prevCount
                if countDiff != 0 {
                    let direction = countDiff > 0 ? "more" : "fewer"
                    insights.append("You completed \(abs(countDiff)) \(direction) workouts than in the previous period.")
                }
            }
        }
        
        return insights.joined(separator: " ")
    }
}

// MARK: - Supporting Types

struct ChartDataPoint: Identifiable {
    let id = UUID()
    let label: String
    let value: Double
}

struct TypeBreakdown {
    let type: WorkoutType
    let count: Int
    let percentage: Double
}

struct SummaryCard: View {
    var value: String
    var label: String
    var icon: String
    var color: Color
    
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(15)
    }
}

enum AnalyticsMetric: String, CaseIterable {
    case calories
    case duration
    case count
    
    var displayName: String {
        switch self {
        case .calories:
            return "Calories"
        case .duration:
            return "Duration (min)"
        case .count:
            return "Workout Count"
        }
    }
}

enum ChartType: String, CaseIterable {
    case bar
    case line
    
    var icon: String {
        switch self {
        case .bar:
            return "chart.bar"
        case .line:
            return "chart.line.uptrend.xyaxis"
        }
    }
}

enum AnalyticsTab: String, CaseIterable {
    case charts
    case calendar
    
    var title: String {
        switch self {
        case .charts:
            return "Analytics"
        case .calendar:
            return "Calendar"
        }
    }
}

struct WorkoutAnalyticsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            WorkoutAnalyticsView()
                .environmentObject(WorkoutViewModel())
        }
        .modelContainerPreview {
            Text("Preview with SwiftData")
        }
    }
}
