
//
//  WorkoutTabView.swift
//  FitnessHabitTracker
//
//  Created by Nikhil Av on 4/16/25.
//  SwiftData implementation

import SwiftUI
import SwiftData

struct WorkoutTabView: View {
    @EnvironmentObject var workoutViewModel: WorkoutViewModel
    @State private var selectedTab = 0
    @State private var showingAddWorkout = false
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Workouts List Tab
            NavigationView {
                WorkoutListView()
                    .environmentObject(workoutViewModel)
            }
            .tabItem {
                Label("All Workouts", systemImage: "list.bullet")
            }
            .tag(0)
            
            // Workout Calendar Tab
            NavigationView {
                WorkoutCalendarView()
                    .environmentObject(workoutViewModel)
            }
            .tabItem {
                Label("Calendar", systemImage: "calendar")
            }
            .tag(1)
            
            // Analytics Tab
            NavigationView {
                WorkoutAnalyticsView()
                    .environmentObject(workoutViewModel)
            }
            .tabItem {
                Label("Analytics", systemImage: "chart.bar.fill")
            }
            .tag(2)
        }
        // Removed the FloatingAddButton overlay
        .sheet(isPresented: $showingAddWorkout) {
            NavigationView {
                WorkoutFormView(isPresented: $showingAddWorkout)
                    .environmentObject(workoutViewModel)
            }
        }
    }
}

struct WorkoutCalendarView: View {
    @EnvironmentObject var workoutViewModel: WorkoutViewModel
    @State private var selectedDate = Date()
    @State private var monthOffset = 0
    
    private var calendar = Calendar.current
    
    var body: some View {
        VStack(spacing: 20) {
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
            
            // Divider with "Selected Day" label
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
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(workoutsForDay, id: \.id) { workout in
                            NavigationLink(destination: WorkoutDetailView(workout: workout)) {
                                CalendarWorkoutRow(workout: workout)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
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
                .frame(maxHeight: .infinity)
            }
            
            Spacer()
        }
        .navigationTitle("Workout Calendar")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Helper Methods
    
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
}

struct CalendarDayView: View {
    var date: Date
    @Binding var selectedDate: Date
    var hasWorkout: Bool
    var workoutCount: Int
    
    // Explicitly make the initializer public
    public init(date: Date, selectedDate: Binding<Date>, hasWorkout: Bool, workoutCount: Int) {
        self.date = date
        self._selectedDate = selectedDate
        self.hasWorkout = hasWorkout
        self.workoutCount = workoutCount
    }
    
    private var calendar = Calendar.current
    
    var isSelected: Bool {
        calendar.isDate(date, inSameDayAs: selectedDate)
    }
    
    var isToday: Bool {
        calendar.isDateInToday(date)
    }
    
    var body: some View {
        // Body remains unchanged
        VStack(spacing: 4) {
            Text("\(calendar.component(.day, from: date))")
                .font(.system(size: 16, weight: isSelected ? .bold : .regular))
                .foregroundColor(isSelected ? .white : (isToday ? .blue : .primary))
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(isSelected ? Color.blue : (isToday ? Color.blue.opacity(0.1) : Color.clear))
                )
            
            if hasWorkout {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.white : Color.green)
                        .frame(width: 16, height: 16)
                    
                    if workoutCount > 1 {
                        Text("\(workoutCount)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(isSelected ? .blue : .white)
                    }
                }
                .frame(height: 16)
            } else {
                Spacer()
                    .frame(height: 16)
            }
        }
        .frame(height: 60)
    }
}

struct CalendarWorkoutRow: View {
    var workout: Workout
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: workout.type.icon)
                .font(.title3)
                .foregroundColor(.white)
                .frame(width: 40, height: 40)
                .background(workout.intensity?.color ?? Color.blue)
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(workout.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(workout.type.rawValue.capitalized)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(Int(workout.duration / 60)) min")
                    .font(.subheadline)
                    .foregroundColor(.primary)
                
                Text("\(Int(workout.caloriesBurned)) cal")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

struct FloatingAddButton: View {
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 56, height: 56)
                    .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)
                
                Image(systemName: "plus")
                    .font(.title2)
                    .foregroundColor(.white)
            }
        }
    }
}

struct WorkoutTabView_Previews: PreviewProvider {
    static var previews: some View {
        WorkoutTabView()
            .environmentObject(WorkoutViewModel())
            .modelContainer(for: Workout.self, inMemory: true)
            .previewDisplayName("Preview with SwiftData")
    }
}
