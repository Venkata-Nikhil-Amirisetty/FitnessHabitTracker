//
//  HabitStatsView.swift
//  FitnessHabitTracker
//
//  Created by Nikhil Av on 4/17/25.
//


import SwiftUI
import SwiftData
import Charts

struct HabitStatsView: View {
    var habit: Habit
    
    @State private var selectedTimeFrame: TimeFrame = .month
    private let calendar = Calendar.current
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Time Frame Selector
                Picker("Time Frame", selection: $selectedTimeFrame) {
                    ForEach(TimeFrame.allCases, id: \.self) { timeFrame in
                        Text(timeFrame.rawValue).tag(timeFrame)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                // Progress Toward Goal
                ProgressSection(habit: habit, timeFrame: selectedTimeFrame)
                    .padding(.horizontal)
                
                // Heat Map - Using the updated HeatMapView that contains its own title
                VStack(alignment: .leading, spacing: 0) {
                    HeatMapView(completedDates: habit.completedDates, timeFrame: selectedTimeFrame)
                        .frame(height: 280)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(15)
                .padding(.horizontal)
                
                // Streak Statistics
                StreakStatsView(habit: habit)
                    .padding(.horizontal)
                
                // Completion Chart
                VStack(alignment: .leading, spacing: 8) {
                    Text("Completion History")
                        .font(.headline)
                        .padding(.bottom, 5)
                    
                    CompletionChartView(habit: habit, timeFrame: selectedTimeFrame)
                        .frame(height: 200)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(15)
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle("Habit Stats")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Time Frame Enum
enum TimeFrame: String, CaseIterable {
    case week = "Week"
    case month = "Month"
    case quarter = "3 Months"
    case year = "Year"
    
    var days: Int {
        switch self {
        case .week: return 7
        case .month: return 30
        case .quarter: return 90
        case .year: return 365
        }
    }
}

// MARK: - Progress Section
struct ProgressSection: View {
    var habit: Habit
    var timeFrame: TimeFrame
    
    private let calendar = Calendar.current
    
    var body: some View {
        let progressStats = calculateProgress()
        
        VStack(alignment: .leading, spacing: 12) {
            Text("Progress Toward Goal")
                .font(.headline)
                .padding(.bottom, 5)
            
            HStack(spacing: 15) {
                // Progress Circle
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 10)
                        .frame(width: 90, height: 90)
                    
                    Circle()
                        .trim(from: 0, to: progressStats.progressPercentage)
                        .stroke(progressColor(progressStats.progressPercentage), lineWidth: 10)
                        .frame(width: 90, height: 90)
                        .rotationEffect(Angle(degrees: -90))
                    
                    VStack(spacing: 0) {
                        Text("\(Int(progressStats.progressPercentage * 100))%")
                            .font(.title3)
                            .fontWeight(.bold)
                            
                        Text("\(progressStats.completedDays)/\(progressStats.goalDays)")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Current Period")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    Text(progressStats.periodDescription)
                        .font(.callout)
                    
                    if habit.frequency == .custom {
                        Text("Target: \(habit.targetDaysPerWeek) days per week")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(15)
        }
    }
    
    private func calculateProgress() -> (completedDays: Int, goalDays: Int, progressPercentage: Double, periodDescription: String) {
        let now = Date()
        let startDate: Date
        let periodDescription: String
        
        // Calculate the start date based on time frame
        switch timeFrame {
        case .week:
            startDate = calendar.date(byAdding: .day, value: -7, to: now)!
            periodDescription = "Last 7 days"
        case .month:
            startDate = calendar.date(byAdding: .day, value: -30, to: now)!
            periodDescription = "Last 30 days"
        case .quarter:
            startDate = calendar.date(byAdding: .day, value: -90, to: now)!
            periodDescription = "Last 90 days"
        case .year:
            startDate = calendar.date(byAdding: .day, value: -365, to: now)!
            periodDescription = "Last 365 days"
        }
        
        // Count completed days in the period
        let completedDaysInPeriod = habit.completedDates.filter { date in
            date >= startDate && date <= now
        }.count
        
        // Calculate goal days based on habit frequency
        var goalDays: Int
        
        switch habit.frequency {
        case .daily:
            goalDays = calendar.dateComponents([.day], from: startDate, to: now).day ?? 0
        case .weekdays:
            // Count weekdays in the period
            goalDays = 0
            var currentDate = startDate
            while currentDate <= now {
                let weekday = calendar.component(.weekday, from: currentDate)
                if weekday >= 2 && weekday <= 6 { // Mon-Fri
                    goalDays += 1
                }
                currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
            }
        case .weekends:
            // Count weekend days in the period
            goalDays = 0
            var currentDate = startDate
            while currentDate <= now {
                let weekday = calendar.component(.weekday, from: currentDate)
                if weekday == 1 || weekday == 7 { // Sun or Sat
                    goalDays += 1
                }
                currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
            }
        case .custom:
            // Calculate based on targetDaysPerWeek
            let totalWeeks = Double(calendar.dateComponents([.day], from: startDate, to: now).day ?? 0) / 7.0
            goalDays = Int(totalWeeks * Double(habit.targetDaysPerWeek))
        }
        
        // Ensure we don't divide by zero
        let progressPercentage = goalDays > 0 ? min(1.0, Double(completedDaysInPeriod) / Double(goalDays)) : 0.0
        
        return (completedDaysInPeriod, goalDays, progressPercentage, periodDescription)
    }
    
    private func progressColor(_ percentage: Double) -> Color {
        if percentage < 0.3 {
            return .red
        } else if percentage < 0.7 {
            return .orange
        } else {
            return .green
        }
    }
}

// MARK: - Heat Map View

struct HeatMapView: View {
    var completedDates: [Date]
    var timeFrame: TimeFrame

    @State private var currentMonthOffset = 0
    private let calendar = Calendar.current
    private let weekdays = ["S", "M", "T", "W", "T", "F", "S"]

    private var days: Int {
        timeFrame.days
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Section header
            HStack {
                Text("Completion Pattern")
                    .font(.headline)
                Spacer()
            }
            .padding(.bottom, 2)

            // Month navigation
            HStack {
                if shouldShowMonthNavigation() {
                    Button(action: {
                        currentMonthOffset -= 1
                    }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.blue)
                            .padding(6)
                    }

                    Spacer()

                    Text(monthYearString())
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Spacer()

                    Button(action: {
                        currentMonthOffset += 1
                        if currentMonthOffset > 0 {
                            currentMonthOffset = 0
                        }
                    }) {
                        Image(systemName: "chevron.right")
                            .foregroundColor(currentMonthOffset < 0 ? .blue : .gray)
                            .padding(6)
                    }
                    .disabled(currentMonthOffset >= 0)
                } else {
                    Text(monthYearString())
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 4)

            // Weekday headers
            HStack(spacing: 0) {
                ForEach(weekdays, id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 4)

            // Calendar Grid with improved spacing and alignment
            let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 7)

            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(generateDatesForCurrentView(), id: \.self) { date in
                    if let date = date {
                        let isCompleted = completedDates.contains { calendar.isDate($0, inSameDayAs: date) }
                        let isToday = calendar.isDateInToday(date)
                        let intensity = calculateIntensity(for: date)

                        ZStack {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(cellColor(isCompleted: isCompleted, intensity: intensity, isToday: isToday))
                                .frame(height: 28)

                            Text("\(calendar.component(.day, from: date))")
                                .font(.system(size: 11, weight: isToday ? .bold : .medium))
                                .foregroundColor(isCompleted ? .white : (isToday ? .blue : .primary))
                        }
                    } else {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.clear)
                            .frame(height: 28)
                    }
                }
            }
            .padding(.horizontal, 4)
        }
    }

    private func generateDatesForCurrentView() -> [Date?] {
        let today = Date()

        if !shouldShowMonthNavigation() {
            let startDate = calendar.date(byAdding: .day, value: -(days - 1), to: today)!

            var result: [Date?] = []

            let weekday = calendar.component(.weekday, from: startDate)
            for _ in 1..<weekday {
                result.append(nil)
            }

            var currentDate = startDate
            while currentDate <= today {
                result.append(currentDate)
                currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
            }

            return result
        }

        let currentMonth = getCurrentMonthDate()
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth))!

        var result: [Date?] = []

        let weekday = calendar.component(.weekday, from: startOfMonth)
        for _ in 1..<weekday {
            result.append(nil)
        }

        let range = calendar.range(of: .day, in: .month, for: startOfMonth)!
        for day in 1...range.count {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth) {
                result.append(date)
            }
        }

        return result
    }

    private func shouldShowMonthNavigation() -> Bool {
        switch timeFrame {
        case .week:
            return false
        case .month, .quarter, .year:
            return true
        }
    }

    private func getCurrentMonthDate() -> Date {
        let today = Date()
        let components = calendar.dateComponents([.year, .month], from: today)
        guard let currentMonth = calendar.date(from: components) else { return today }

        return calendar.date(byAdding: .month, value: currentMonthOffset, to: currentMonth) ?? today
    }

    private func monthYearString() -> String {
        let dateFormatter = DateFormatter()

        if shouldShowMonthNavigation() {
            dateFormatter.dateFormat = "MMMM yyyy"
            return dateFormatter.string(from: getCurrentMonthDate())
        } else {
            let today = Date()
            let startDate = calendar.date(byAdding: .day, value: -(days - 1), to: today)!

            dateFormatter.dateFormat = "MMM d"
            let startString = dateFormatter.string(from: startDate)

            dateFormatter.dateFormat = "d, yyyy"
            let endString = dateFormatter.string(from: today)

            return "\(startString) - \(endString)"
        }
    }

    private func calculateIntensity(for date: Date) -> Double {
        let yesterday = calendar.date(byAdding: .day, value: -1, to: date)!
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: date)!

        let isYesterdayCompleted = completedDates.contains { calendar.isDate($0, inSameDayAs: yesterday) }
        let isTomorrowCompleted = completedDates.contains { calendar.isDate($0, inSameDayAs: tomorrow) }

        if isYesterdayCompleted && isTomorrowCompleted {
            return 1.0
        } else if isYesterdayCompleted || isTomorrowCompleted {
            return 0.7
        } else {
            return 0.4
        }
    }

    private func cellColor(isCompleted: Bool, intensity: Double, isToday: Bool) -> Color {
        if !isCompleted {
            return isToday ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1)
        }

        return Color.green.opacity(0.3 + (intensity * 0.7))
    }
}

// MARK: - Streak Stats View
struct StreakStatsView: View {
    var habit: Habit
    
    @State private var longestStreak: Int = 0
    @State private var totalCompletions: Int = 0
    @State private var completionRate: Double = 0.0
    
    private let calendar = Calendar.current
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Streak Statistics")
                .font(.headline)
                .padding(.bottom, 5)
            
            HStack(spacing: 15) {
                StatBoxView(value: "\(habit.currentStreak)", label: "Current Streak")
                
                StatBoxView(value: "\(longestStreak)", label: "Longest Streak")
                
                StatBoxView(value: "\(Int(completionRate * 100))%", label: "Completion Rate")
            }
        }
        .onAppear {
            calculateStats()
        }
    }
    
    private func calculateStats() {
        // Calculate longest streak
        longestStreak = calculateLongestStreak()
        
        // Calculate total completions
        totalCompletions = habit.completedDates.count
        
        // Calculate completion rate (based on days since habit started)
        let daysSinceStart = max(1, calendar.dateComponents([.day], from: habit.startDate, to: Date()).day ?? 1)
        completionRate = Double(totalCompletions) / Double(daysSinceStart)
    }
    
    private func calculateLongestStreak() -> Int {
        let sortedDates = habit.completedDates.sorted()
        guard !sortedDates.isEmpty else { return 0 }
        
        var currentStreak = 1
        var maxStreak = 1
        
        for i in 1..<sortedDates.count {
            let previousDate = calendar.startOfDay(for: sortedDates[i-1])
            let currentDate = calendar.startOfDay(for: sortedDates[i])
            
            // Check if dates are consecutive
            let daysBetween = calendar.dateComponents([.day], from: previousDate, to: currentDate).day ?? 0
            
            if daysBetween == 1 {
                currentStreak += 1
                maxStreak = max(maxStreak, currentStreak)
            } else {
                currentStreak = 1
            }
        }
        
        return maxStreak
    }
}

// MARK: - Stat Box View
struct StatBoxView: View {
    var value: String
    var label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}

// MARK: - Completion Chart View
struct CompletionChartView: View {
    var habit: Habit
    var timeFrame: TimeFrame
    
    private let calendar = Calendar.current
    
    var body: some View {
        Chart {
            ForEach(generateChartData(), id: \.date) { item in
                BarMark(
                    x: .value("Date", item.label),
                    y: .value("Completions", item.count)
                )
                .foregroundStyle(Color.green.gradient)
            }
        }
    }
    
    private func generateChartData() -> [ChartDataItem] {
        let now = Date()
        var result: [ChartDataItem] = []
        
        switch timeFrame {
        case .week:
            // Daily data for the week
            for i in 0..<7 {
                let date = calendar.date(byAdding: .day, value: -i, to: now)!
                let count = countCompletions(on: date)
                let dayFormatter = DateFormatter()
                dayFormatter.dateFormat = i == 0 ? "Today" : "EEE"
                let label = i == 0 ? "Today" : dayFormatter.string(from: date)
                
                result.append(ChartDataItem(date: date, label: label, count: count))
            }
            
        case .month:
            // Weekly data for the month
            for i in 0..<4 {
                let endDate = calendar.date(byAdding: .day, value: -(i * 7), to: now)!
                let startDate = calendar.date(byAdding: .day, value: -6, to: endDate)!
                let count = countCompletions(from: startDate, to: endDate)
                
                let weekLabel = i == 0 ? "This week" : "Week \(4-i)"
                result.append(ChartDataItem(date: endDate, label: weekLabel, count: count))
            }
            
        case .quarter:
            // Monthly data for the quarter
            for i in 0..<3 {
                let date = calendar.date(byAdding: .month, value: -i, to: now)!
                let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: date))!
                let nextMonthStart = calendar.date(byAdding: .month, value: 1, to: monthStart)!
                
                let count = countCompletions(from: monthStart, to: calendar.date(byAdding: .day, value: -1, to: nextMonthStart)!)
                
                let monthFormatter = DateFormatter()
                monthFormatter.dateFormat = "MMM"
                let label = monthFormatter.string(from: date)
                
                result.append(ChartDataItem(date: date, label: label, count: count))
            }
            
        case .year:
            // Quarterly data for the year
            for i in 0..<4 {
                let quarterEnd = calendar.date(byAdding: .month, value: -(i * 3), to: now)!
                let quarterStart = calendar.date(byAdding: .month, value: -2, to: quarterEnd)!
                
                let count = countCompletions(from: quarterStart, to: quarterEnd)
                
                let quarterLabel = "Q\(4-i)"
                result.append(ChartDataItem(date: quarterEnd, label: quarterLabel, count: count))
            }
        }
        
        // Reverse to show chronological order
        return result.reversed()
    }
    
    private func countCompletions(on date: Date) -> Int {
        let start = calendar.startOfDay(for: date)
        let end = calendar.date(byAdding: .day, value: 1, to: start)!
        
        return habit.completedDates.filter { $0 >= start && $0 < end }.count
    }
    
    private func countCompletions(from startDate: Date, to endDate: Date) -> Int {
        let start = calendar.startOfDay(for: startDate)
        let end = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: endDate))!
        
        return habit.completedDates.filter { $0 >= start && $0 < end }.count
    }
}

struct ChartDataItem {
    var date: Date
    var label: String
    var count: Int
}

struct HabitStatsView_Previews: PreviewProvider {
    static var previews: some View {
        let previewHabit = Habit(
            name: "Daily Meditation",
            descriptionText: "10 minutes of mindfulness meditation",
            category: .mindfulness,
            frequency: .daily,
            completedDates: [Date()]
        )
        
        // Add some sample completed dates
        let calendar = Calendar.current
        for i in 1...20 {
            if i % 3 != 0 { // Skip every 3rd day
                if let date = calendar.date(byAdding: .day, value: -i, to: Date()) {
                    previewHabit.completedDates.append(date)
                }
            }
        }
        
        return NavigationView {
            HabitStatsView(habit: previewHabit)
        }
        .modelContainer(for: [Habit.self], inMemory: true)
    }
}
