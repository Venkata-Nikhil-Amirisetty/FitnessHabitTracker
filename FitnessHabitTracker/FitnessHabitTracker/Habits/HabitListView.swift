//
//  HabitListView.swift
//  FitnessHabitTracker
//
//  Created by Nikhil Av on 4/16/25.
//

import SwiftUI
import SwiftData

struct HabitListView: View {
    @EnvironmentObject var habitViewModel: HabitViewModel
    @State private var showingAddHabit = false
    @State private var selectedFilter: HabitCategory? = nil
    @State private var showingCompletedOnly = false
    
    // Search and sort states
    @State private var searchText = ""
    @State private var isSearching = false
    @State private var sortOption: HabitSortOption = .streakDescending
    @State private var showingSortOptions = false
    
    var filteredHabits: [Habit] {
        var result = habitViewModel.filterHabits(by: selectedFilter, showCompleted: showingCompletedOnly)
        
        // Apply search if not empty
        if !searchText.isEmpty {
            result = result.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                ($0.descriptionText?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        
        // Apply sorting
        switch sortOption {
        case .nameAscending:
            result.sort { $0.name < $1.name }
        case .nameDescending:
            result.sort { $0.name > $1.name }
        case .categoryAscending:
            result.sort { $0.categoryName < $1.categoryName }
        case .categoryDescending:
            result.sort { $0.categoryName > $1.categoryName }
        case .streakDescending:
            result.sort { $0.currentStreak > $1.currentStreak }
        case .streakAscending:
            result.sort { $0.currentStreak < $1.currentStreak }
        case .startDateNewest:
            result.sort { $0.startDate > $1.startDate }
        case .startDateOldest:
            result.sort { $0.startDate < $1.startDate }
        }
        
        return result
    }
    
    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground)
                .ignoresSafeArea()
                
            VStack(spacing: 0) {
                // Search and Sort Bar
                HStack {
                    if isSearching {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.gray)
                            
                            TextField("Search habits", text: $searchText)
                                .disableAutocorrection(true)
                            
                            Button(action: {
                                withAnimation(.spring()) {
                                    searchText = ""
                                    isSearching = false
                                }
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                            .opacity(searchText.isEmpty ? 0 : 1)
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(UIColor.systemBackground))
                                .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
                        )
                        
                        Spacer()
                        
                        Button(action: {
                            showingSortOptions = true
                        }) {
                            HStack {
                                Text("Sort")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Image(systemName: "arrow.up.arrow.down")
                            }
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(UIColor.systemBackground))
                                    .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
                            )
                            .foregroundColor(.green)
                        }
                    } else {
                        Button(action: {
                            withAnimation(.spring()) {
                                isSearching = true
                            }
                        }) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.green)
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(UIColor.systemBackground))
                                        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
                                )
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            showingSortOptions = true
                        }) {
                            HStack {
                                Text("Sort: \(sortOption.description)")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Image(systemName: "arrow.up.arrow.down")
                            }
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(UIColor.systemBackground))
                                    .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
                            )
                            .foregroundColor(.green)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 16)
                .padding(.bottom, 12)
                
                // Filter options
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        // Special styling for the "All" button with green color
                        Button(action: {
                            withAnimation {
                                selectedFilter = nil
                            }
                        }) {
                            Text("All")
                                .font(.subheadline)
                                .fontWeight(selectedFilter == nil ? .semibold : .regular)
                                .padding(.vertical, 10)
                                .padding(.horizontal, 14)
                                .background(
                                    Capsule()
                                        .fill(selectedFilter == nil ? Color(red: 0.27, green: 0.68, blue: 0.32) : Color(UIColor.systemGray6))
                                        .shadow(color: selectedFilter == nil ? Color(red: 0.27, green: 0.68, blue: 0.32).opacity(0.3) : Color.clear, radius: 4, x: 0, y: 2)
                                )
                                .foregroundColor(selectedFilter == nil ? .white : .primary)
                        }
                        .animation(.spring(response: 0.3), value: selectedFilter == nil)
                        
                        // Category filters
                        ForEach(HabitCategory.allCases, id: \.self) { category in
                            FilterButton(
                                title: category.rawValue.capitalized,
                                icon: category.icon,
                                isSelected: selectedFilter == category
                            ) {
                                withAnimation {
                                    selectedFilter = category
                                }
                            }
                        }
                        
                        // Show completed toggle as a FilterButton
                        FilterButton(
                            title: "Completed",
                            icon: showingCompletedOnly ? "checkmark.circle.fill" : "circle",
                            isSelected: showingCompletedOnly
                        ) {
                            withAnimation {
                                showingCompletedOnly.toggle()
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                
                // Habit list or Empty State
                if filteredHabits.isEmpty {
                    VStack(spacing: 24) {
                        Spacer()
                        
                        Image(systemName: "list.bullet.clipboard")
                            .font(.system(size: 70))
                            .foregroundColor(.green.opacity(0.7))
                            .padding()
                            .background(
                                Circle()
                                    .fill(Color.green.opacity(0.1))
                                    .frame(width: 150, height: 150)
                            )
                        
                        if !searchText.isEmpty {
                            Text("No habits match your search")
                                .font(.title3)
                                .fontWeight(.medium)
                        } else if selectedFilter != nil {
                            Text("No \(selectedFilter!.rawValue) habits found")
                                .font(.title3)
                                .fontWeight(.medium)
                        } else {
                            Text("No habits yet")
                                .font(.title3)
                                .fontWeight(.medium)
                        }
                        
                        Button(action: {
                            showingAddHabit = true
                        }) {
                            HStack {
                                Image(systemName: "plus")
                                    .font(.headline)
                                Text("Add Habit")
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .padding(.vertical, 14)
                            .padding(.horizontal, 30)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color.green)
                                    .shadow(color: Color.green.opacity(0.3), radius: 5, x: 0, y: 3)
                            )
                        }
                        .padding(.top, 8)
                        
                        Spacer()
                    }
                    .padding()
                    .frame(maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(filteredHabits, id: \.id) { habit in
                                NavigationLink(destination: HabitDetailView(habit: habit)) {
                                    HabitRow(habit: habit) {
                                        habitViewModel.toggleHabitCompletion(habit)
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            .onDelete(perform: deleteHabit)
                        }
                        .padding(.vertical, 8)
                    }
                    .refreshable {
                        habitViewModel.loadHabits()
                    }
                    
                    // Summary Footer
                    VStack(spacing: 16) {
                        Text("\(filteredHabits.count) habits")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                        
                        HStack(spacing: 16) {
                            StatisticView(
                                label: "Active Habits",
                                value: "\(activeHabitsCount)",
                                icon: "checkmark.circle"
                            )
                            
                            StatisticView(
                                label: "Total Streaks",
                                value: "\(totalStreakCount)",
                                icon: "flame"
                            )
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 16)
                    }
                    .background(
                        Rectangle()
                            .fill(Color(UIColor.systemBackground))
                            .shadow(color: Color.black.opacity(0.05), radius: 5, y: -3)
                    )
                }
            }
        }
        .navigationTitle("Habits")
        .navigationBarItems(trailing: Button(action: {
            showingAddHabit = true
        }) {
            Image(systemName: "plus.circle.fill")
                .font(.system(size: 22))
                .foregroundColor(.green)
        })
        .sheet(isPresented: $showingAddHabit) {
            NavigationView {
                HabitFormView(isPresented: $showingAddHabit)
                    .environmentObject(habitViewModel)
            }
        }
        .actionSheet(isPresented: $showingSortOptions) {
            ActionSheet(
                title: Text("Sort Habits"),
                buttons: [
                    .default(Text(HabitSortOption.nameAscending.description)) {
                        sortOption = .nameAscending
                    },
                    .default(Text(HabitSortOption.nameDescending.description)) {
                        sortOption = .nameDescending
                    },
                    .default(Text(HabitSortOption.categoryAscending.description)) {
                        sortOption = .categoryAscending
                    },
                    .default(Text(HabitSortOption.categoryDescending.description)) {
                        sortOption = .categoryDescending
                    },
                    .default(Text(HabitSortOption.streakDescending.description)) {
                        sortOption = .streakDescending
                    },
                    .default(Text(HabitSortOption.streakAscending.description)) {
                        sortOption = .streakAscending
                    },
                    .default(Text(HabitSortOption.startDateNewest.description)) {
                        sortOption = .startDateNewest
                    },
                    .default(Text(HabitSortOption.startDateOldest.description)) {
                        sortOption = .startDateOldest
                    },
                    .cancel()
                ]
            )
        }
        .onAppear {
            habitViewModel.loadHabits()
        }
    }
    
    private func deleteHabit(at offsets: IndexSet) {
        for index in offsets {
            let habitToDelete = filteredHabits[index]
            habitViewModel.deleteHabit(habitToDelete)
        }
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    // Computed properties for stats
    private var activeHabitsCount: Int {
        filteredHabits.filter { !$0.isArchived }.count
    }
    
    private var totalStreakCount: Int {
        filteredHabits.reduce(0) { $0 + ($1.currentStreak > 0 ? 1 : 0) }
    }
}



struct HabitRow: View {
    var habit: Habit
    var toggleCompletion: () -> Void
    @State private var appear = false
    
    // Compute this directly from the habit
    var isCompletedToday: Bool {
        let today = Calendar.current.startOfDay(for: Date())
        return habit.completedDates.contains(where: { Calendar.current.isDate($0, inSameDayAs: today) })
    }
    
    var body: some View {
        VStack {
            HStack(spacing: 15) {
                Button(action: toggleCompletion) {
                    ZStack {
                        Image(systemName: habit.category.icon)
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 45, height: 45)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(isCompletedToday ? Color(red: 0.27, green: 0.68, blue: 0.32) : Color(red: 0.27, green: 0.68, blue: 0.32).opacity(0.6))
                                    .shadow(color: Color(red: 0.27, green: 0.68, blue: 0.32).opacity(0.3), radius: 4, x: 0, y: 2)
                            )
                        
                        if isCompletedToday {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                                .padding(4)
                                .background(Circle().fill(Color.white.opacity(0.3)))
                                .offset(x: 15, y: -15)
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(habit.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(isCompletedToday ? .secondary : .primary)
                        .strikethrough(isCompletedToday)
                    
                    HStack {
                        Text(formatDate(habit.startDate))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text("•")
                            .foregroundColor(.secondary)
                        
                        Text(habit.frequency.rawValue.capitalized)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 6) {
                    if habit.currentStreak > 0 {
                        HStack(spacing: 4) {
                            Text("\(habit.currentStreak)")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Image(systemName: "flame.fill")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                    
                    if habit.isWeatherSensitive {
                        HStack(spacing: 4) {
                            Image(systemName: "cloud.sun")
                                .font(.caption)
                                .foregroundColor(.blue)
                            Text("Weather")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .opacity(appear ? 1 : 0)
        .offset(y: appear ? 0 : 20)
        .onAppear {
            withAnimation(.easeOut(duration: 0.3).delay(0.1)) {
                appear = true
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}



// MARK: - Supporting Enums
enum HabitSortOption {
    case nameAscending
    case nameDescending
    case categoryAscending
    case categoryDescending
    case streakDescending
    case streakAscending
    case startDateNewest
    case startDateOldest
    
    var description: String {
        switch self {
        case .nameAscending: return "Name (A-Z)"
        case .nameDescending: return "Name (Z-A)"
        case .categoryAscending: return "Category (A-Z)"
        case .categoryDescending: return "Category (Z-A)"
        case .streakDescending: return "Streak (High-Low)"
        case .streakAscending: return "Streak (Low-High)"
        case .startDateNewest: return "Newest First"
        case .startDateOldest: return "Oldest First"
        }
    }
}

// MARK: - HabitFormView Components
// Breaking down the complex view into smaller components

// Basic details component
struct HabitDetailsSection: View {
    @Binding var name: String
    @Binding var description: String
    @Binding var category: HabitCategory
    
    var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        FormSection(title: "Habit Details") {
            // Name field
            FormField(title: "Name", required: true) {
                TextField("Enter habit name", text: $name)
                    .padding()
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(!isFormValid && name.isEmpty ? Color.red : Color.clear, lineWidth: 1)
                    )
            }
            
            // Description field
            FormField(title: "Description (Optional)") {
                TextField("What's this habit about?", text: $description)
                    .padding()
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(12)
            }
            
            // Category picker
            FormField(title: "Category") {
                Menu {
                    ForEach(HabitCategory.allCases, id: \.self) { category in
                        Button(action: {
                            self.category = category
                        }) {
                            HStack {
                                Image(systemName: category.icon)
                                Text(category.rawValue.capitalized)
                                
                                if self.category == category {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: category.icon)
                            .foregroundColor(.green)
                        
                        Text(category.rawValue.capitalized)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.down")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(12)
                }
            }
        }
    }
}

// Frequency section component
struct FrequencySection: View {
    @Binding var frequency: HabitFrequency
    @Binding var targetDaysPerWeek: Int
    
    var body: some View {
        FormSection(title: "Frequency") {
            // Frequency picker
            FormField(title: "Repeat") {
                Picker("", selection: $frequency) {
                    Text("Daily").tag(HabitFrequency.daily)
                    Text("Weekdays").tag(HabitFrequency.weekdays)
                    Text("Weekends").tag(HabitFrequency.weekends)
                    Text("Custom").tag(HabitFrequency.custom)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(4)
                .background(Color(UIColor.systemBackground))
                .cornerRadius(8)
            }
            
            // Days per week stepper (for custom frequency)
            if frequency == .custom {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Target Days Per Week")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("\(targetDaysPerWeek)")
                            .font(.headline)
                            .frame(width: 32, height: 32)
                            .background(Circle().fill(Color.green))
                            .foregroundColor(.white)
                    }
                    
                    HStack {
                        Button(action: {
                            if targetDaysPerWeek > 1 {
                                targetDaysPerWeek -= 1
                            }
                        }) {
                            Image(systemName: "minus")
                                .foregroundColor(targetDaysPerWeek > 1 ? .primary : .gray)
                                .padding(10)
                                .background(Color(UIColor.systemBackground))
                                .clipShape(Circle())
                        }
                        .disabled(targetDaysPerWeek <= 1)
                        
                        ZStack {
                            Rectangle()
                                .fill(Color(UIColor.systemBackground))
                                .cornerRadius(12)
                            
                            HStack(spacing: 0) {
                                ForEach(1...7, id: \.self) { day in
                                    Rectangle()
                                        .fill(day <= targetDaysPerWeek ? Color.green.opacity(0.8) : Color.clear)
                                        .frame(height: 8)
                                }
                            }
                            .padding(.horizontal, 2)
                        }
                        .frame(height: 40)
                        
                        Button(action: {
                            if targetDaysPerWeek < 7 {
                                targetDaysPerWeek += 1
                            }
                        }) {
                            Image(systemName: "plus")
                                .foregroundColor(targetDaysPerWeek < 7 ? .primary : .gray)
                                .padding(10)
                                .background(Color(UIColor.systemBackground))
                                .clipShape(Circle())
                        }
                        .disabled(targetDaysPerWeek >= 7)
                    }
                }
            }
        }
    }
}

// Reminder section component
struct ReminderSection: View {
    @Binding var enableReminder: Bool
    @Binding var reminderTime: Date
    
    var body: some View {
        FormSection(title: "Reminder") {
            Toggle(isOn: $enableReminder) {
                Text("Enable Daily Reminder")
            }
            .toggleStyle(SwitchToggleStyle(tint: .green))
            
            if enableReminder {
                DatePicker("Time", selection: $reminderTime, displayedComponents: .hourAndMinute)
                    .datePickerStyle(WheelDatePickerStyle())
                    .labelsHidden()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
        }
    }
}

// Weather settings section component
struct WeatherSettingsSection: View {
    @Binding var isWeatherSensitive: Bool
    @Binding var selectedWeatherConditions: Set<WeatherCondition>
    @Binding var indoorAlternative: String
    var weatherViewModel: WeatherViewModel
    
    var body: some View {
        FormSection(title: "Weather Settings") {
            Toggle(isOn: $isWeatherSensitive.animation()) {
                Text("Weather Sensitive Habit")
            }
            .toggleStyle(SwitchToggleStyle(tint: .green))
            
            if isWeatherSensitive {
                // Weather conditions navigation link
                NavigationLink {
                    WeatherConditionsSelectionView(selectedConditions: $selectedWeatherConditions)
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Preferred Weather Conditions")
                                .font(.subheadline)
                                .foregroundColor(.primary)
                            
                            if selectedWeatherConditions.isEmpty {
                                Text("None selected")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            } else {
                                Text("\(selectedWeatherConditions.count) conditions selected")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(12)
                }
                
                // Current weather preview
                if !selectedWeatherConditions.isEmpty,
                   let weather = weatherViewModel.currentWeather {
                    WeatherPreviewView(
                        weather: weather,
                        selectedConditions: selectedWeatherConditions
                    )
                }
                
                // Indoor alternative field
                FormField(title: "Indoor Alternative") {
                    TextField("What to do when weather isn't suitable", text: $indoorAlternative)
                        .padding()
                        .background(Color(UIColor.systemBackground))
                        .cornerRadius(12)
                }
            }
        }
    }
}

// Save button component
struct SaveButtonView: View {
    var isSaving: Bool
    var isFormValid: Bool
    var saveAction: () -> Void
    
    var body: some View {
        Button(action: saveAction) {
            if isSaving {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.green)
                    )
            } else {
                Text("Save Habit")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(isFormValid ? Color.green : Color.gray.opacity(0.5))
                            .shadow(color: isFormValid ? Color.green.opacity(0.3) : Color.clear, radius: 5, x: 0, y: 3)
                    )
            }
        }
        .disabled(!isFormValid || isSaving)
    }
}

// Form helper components
struct FormSection<Content: View>: View {
    var title: String
    @ViewBuilder var content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
                .padding(.leading, 4)
            
            VStack(spacing: 16) {
                content
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(UIColor.secondarySystemGroupedBackground))
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            )
        }
    }
}

struct FormField<Content: View>: View {
    var title: String
    var required: Bool = false
    @ViewBuilder var content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if required {
                    Text("*")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            
            content
        }
    }
}

// MARK: - Main HabitFormView
struct HabitFormView: View {
    @EnvironmentObject var habitViewModel: HabitViewModel
    @Binding var isPresented: Bool
    @Environment(\.modelContext) private var modelContext
    
    // Basic form state
    @State private var name = ""
    @State private var description = ""
    @State private var category: HabitCategory = .health
    @State private var frequency: HabitFrequency = .daily
    @State private var targetDaysPerWeek = 7
    @State private var enableReminder = false
    @State private var reminderTime = Date()
    
    // Weather-related state
    @State private var isWeatherSensitive: Bool
    @State private var selectedWeatherConditions: Set<WeatherCondition> = []
    @State private var indoorAlternative = ""
    
    // Validation
    @State private var showingValidationAlert = false
    @State private var validationMessage = ""
    @State private var isSaving = false
    
    // Initialize with default values, and optionally pre-set weather sensitivity
    init(isPresented: Binding<Bool>, isWeatherSensitive: Bool = false) {
        self._isPresented = isPresented
        self._isWeatherSensitive = State(initialValue: isWeatherSensitive)
    }
    
    var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 16) {
                    // Basic details
                    HabitDetailsSection(
                        name: $name,
                        description: $description,
                        category: $category
                    )
                    
                    // Frequency
                    FrequencySection(
                        frequency: $frequency,
                        targetDaysPerWeek: $targetDaysPerWeek
                    )
                    
                    // Reminder
                    ReminderSection(
                        enableReminder: $enableReminder,
                        reminderTime: $reminderTime
                    )
                    
                    // Weather settings
                    WeatherSettingsSection(
                        isWeatherSensitive: $isWeatherSensitive,
                        selectedWeatherConditions: $selectedWeatherConditions,
                        indoorAlternative: $indoorAlternative,
                        weatherViewModel: habitViewModel.weatherViewModel
                    )
                    
                    // Save button
                    SaveButtonView(
                        isSaving: isSaving,
                        isFormValid: isFormValid,
                        saveAction: saveHabit
                    )
                    .padding(.top, 8)
                    .padding(.bottom, 20)
                }
                .padding()
            }
        }
        .navigationTitle("Create Habit")
        .navigationBarItems(leading: Button("Cancel") {
            isPresented = false
        })
        .alert(isPresented: $showingValidationAlert) {
            Alert(
                title: Text("Validation Error"),
                message: Text(validationMessage),
                dismissButton: .default(Text("OK"))
            )
        }
        .onAppear {
            // Initialize location services for weather data
            LocationManager.shared.requestLocation()
        }
    }
    
    // Save habit method
    private func saveHabit() {
        // Validate form
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            validationMessage = "Please enter a habit name"
            showingValidationAlert = true
            return
        }
        
        isSaving = true
        
        let newHabit = Habit(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            descriptionText: description.isEmpty ? nil : description.trimmingCharacters(in: .whitespacesAndNewlines),
            category: category,
            frequency: frequency,
            targetDaysPerWeek: targetDaysPerWeek,
            reminderTime: enableReminder ? reminderTime : nil
        )
        
        // Set weather-related properties
        newHabit.isWeatherSensitive = isWeatherSensitive
        newHabit.preferredWeatherConditions = selectedWeatherConditions.map { $0.rawValue }
        newHabit.indoorAlternative = indoorAlternative.isEmpty ? nil : indoorAlternative
        
        // Schedule reminder if enabled
        if enableReminder {
            NotificationManager.shared.scheduleHabitReminder(for: newHabit) { success in
                if !success {
                    print("Failed to schedule notification for habit: \(newHabit.name)")
                }
            }
        }
        
        habitViewModel.addHabit(newHabit)
        
        // Slight delay before dismissing to ensure data is saved
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isSaving = false
            isPresented = false
        }
    }
}

struct WeatherConditionsSelectionView: View {
    @Binding var selectedConditions: Set<WeatherCondition>
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        List {
            Section(header: Text("Select Preferred Weather")) {
                ForEach(WeatherCondition.allCases) { condition in
                    Button(action: {
                        if selectedConditions.contains(condition) {
                            selectedConditions.remove(condition)
                        } else {
                            selectedConditions.insert(condition)
                        }
                    }) {
                        HStack {
                            Image(systemName: condition.systemIconName)
                                .foregroundColor(condition.color)
                                .frame(width: 32, height: 32)
                                .background(Circle().fill(condition.color.opacity(0.1)))
                            
                            Text(condition.rawValue)
                                .font(.body)
                            
                            Spacer()
                            
                            if selectedConditions.contains(condition) {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.green)
                            }
                        }
                    }
                    .foregroundColor(.primary)
                }
            }
            
            Section(footer: Text("Selecting no conditions means this habit can be done in any weather.")) {
                Button(action: {
                    selectedConditions.removeAll()
                }) {
                    HStack {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.red.opacity(0.8))
                        Text("Clear All Selections")
                            .foregroundColor(.red)
                    }
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle("Weather Preferences")
        .navigationBarItems(trailing: Button("Done") {
            presentationMode.wrappedValue.dismiss()
        })
    }
}

struct HabitListView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            HabitListView()
                .environmentObject(HabitViewModel())
        }
        .modelContainer(for: [Habit.self], inMemory: true)
    }
}
