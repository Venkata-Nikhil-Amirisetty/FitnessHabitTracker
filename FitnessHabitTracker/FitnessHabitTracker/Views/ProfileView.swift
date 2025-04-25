//
//  ProfileView.swift
//  FitnessHabitTracker
//
//  Updated with improved UI while maintaining existing functionality
//

import SwiftUI
import SwiftData
import UserNotifications

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var workoutViewModel: WorkoutViewModel
    @EnvironmentObject var habitViewModel: HabitViewModel
    @EnvironmentObject var goalViewModel: GoalViewModel
    
    @State private var showingEditProfile = false
    @State private var showingSettings = false
    @State private var showingLogoutAlert = false
    @State private var showingNotifications = false
    @State private var showingGoalsView = false
    @State private var showingFAQView = false
    @State private var showingBMIDetails = false
    
    // Notification states
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("reminderTimeHour") private var reminderTimeHour = 20
    @AppStorage("reminderTimeMinute") private var reminderTimeMinute = 0
    @State private var savedReminders: [ReminderNotification] = []
    
    // Add this for notification handling
    @State private var reminderToShow: ReminderNotification? = nil
    @State private var selectedReminder: ReminderNotification?
    @State private var showingReminderDetails = false
    @Environment(\.colorScheme) var colorScheme
    
    // Add ProfileImageManager for proper image refreshing
    @ObservedObject private var imageManager = ProfileImageManager.shared
    
    // Colors
    private var primaryAccentColor: Color { Color.blue }
    private var secondaryAccentColor: Color { colorScheme == .dark ? Color.blue.opacity(0.2) : Color.blue.opacity(0.1) }
    private var backgroundColor: Color { colorScheme == .dark ? Color(UIColor.systemBackground) : Color(UIColor.systemBackground) }
    private var cardBackgroundColor: Color { colorScheme == .dark ? Color(UIColor.systemGray6) : Color.white }
    private var textColor: Color { colorScheme == .dark ? .white : .primary }
    private var secondaryTextColor: Color { .gray }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Profile Header with Card Style
                profileHeaderSection
                
                // BMI Card Section (New)
                if let bmiValue = calculateBMI() {
                    bmiCardSection(bmiValue: bmiValue)
                }
                
                // Stats Section with Grid Layout
                statsSection
                
                // Menu Section with Better Styling
                menuSection
                
                // Logout Button with Improved Styling
                logoutButton
                
                // Add extra padding at the bottom to ensure the logout button is visible
                Spacer(minLength: 60)
            }
            .padding(.vertical)
            .padding(.bottom, 30) // Additional bottom padding for the logout button
        }
        .background(colorScheme == .dark ? Color(UIColor.systemBackground) : Color(UIColor.systemGray6).opacity(0.3))
        .edgesIgnoringSafeArea(.bottom)
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .alert(isPresented: $showingLogoutAlert) {
            Alert(
                title: Text("Log Out"),
                message: Text("Are you sure you want to log out?"),
                primaryButton: .destructive(Text("Log Out")) {
                    authViewModel.logout()
                },
                secondaryButton: .cancel()
            )
        }
        .sheet(isPresented: $showingEditProfile) {
            NavigationView {
                if let user = authViewModel.currentUser {
                    EditProfileView(user: user)
                        .environmentObject(authViewModel)
                }
            }
        }
        .sheet(isPresented: $showingSettings) {
            NavigationView {
                SettingsView()
                    .environmentObject(authViewModel)
            }
        }
        .sheet(isPresented: $showingGoalsView) {
            NavigationView {
                GoalListView()
                    .environmentObject(goalViewModel)
            }
        }
        .sheet(isPresented: $showingNotifications) {
            NavigationView {
                NotificationsView(
                    notificationsEnabled: $notificationsEnabled,
                    savedReminders: $savedReminders,
                    reminderTimeHour: $reminderTimeHour,
                    reminderTimeMinute: $reminderTimeMinute
                )
                .navigationTitle("Notifications")
                .navigationBarItems(leading: Button("Done") {
                    showingNotifications = false
                })
                .onDisappear {
                    saveReminders()
                }
            }
        }
        .sheet(isPresented: $showingReminderDetails) {
            if let selectedReminder = selectedReminder {
                NavigationView {
                    ReminderDetailView(reminder: selectedReminder, onUpdate: { updatedReminder in
                        updateReminder(updatedReminder)
                    })
                    .navigationBarItems(leading: Button("Done") {
                        showingReminderDetails = false
                    })
                }
            }
        }
        .sheet(isPresented: $showingFAQView) {
            NavigationView {
                FAQView()
                    .navigationTitle("Help & Support")
                    .navigationBarItems(leading: Button("Done") {
                        showingFAQView = false
                    })
            }
        }
        .sheet(isPresented: $showingBMIDetails) {
            NavigationView {
                if let bmiValue = calculateBMI() {
                    BMIDetailView(bmiValue: bmiValue)
                        .navigationTitle("BMI Details")
                        .navigationBarItems(leading: Button("Done") {
                            showingBMIDetails = false
                        })
                }
            }
        }
        .onAppear {
            imageManager.notifyImageUpdated()
            
            NotificationCenter.default.addObserver(
                forName: NSNotification.Name("OpenReminderDetail"),
                object: nil,
                queue: .main
            ) { notification in
                if let reminderId = notification.userInfo?["reminderId"] as? String {
                    loadReminderFromNotification(reminderId: reminderId)
                }
            }
        }
    }
    
    // MARK: - UI Components
    
    private var profileHeaderSection: some View {
        VStack(spacing: 16) {
            // Profile Image
            ZStack(alignment: .bottomTrailing) {
                Group {
                    if let profileImageURL = authViewModel.currentUser?.profileImageURL, !profileImageURL.isEmpty {
                        ProfileImageView(imageURL: profileImageURL)
                            .frame(width: 110, height: 110)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(primaryAccentColor.opacity(0.3), lineWidth: 2))
                            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                            .id("\(profileImageURL)-\(imageManager.lastUpdated.timeIntervalSince1970)")
                    } else {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .foregroundColor(.gray)
                            .frame(width: 110, height: 110)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(primaryAccentColor.opacity(0.3), lineWidth: 2))
                            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                    }
                }
                
                Button(action: {
                    showingEditProfile = true
                }) {
                    Image(systemName: "pencil")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .padding(8)
                        .background(primaryAccentColor)
                        .clipShape(Circle())
                        .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 1)
                }
            }
            .padding(.top, 10)
            
            // User Info
            VStack(spacing: 5) {
                Text(authViewModel.currentUser?.name ?? "User")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(textColor)
                
                Text(authViewModel.currentUser?.email ?? "")
                    .font(.subheadline)
                    .foregroundColor(secondaryTextColor)
            }
            
            // User Stats - Always show the container, with conditional content
            HStack(spacing: 24) {
                if let weight = authViewModel.currentUser?.weight {
                    VStack(spacing: 6) {
                        HStack(spacing: 5) {
                            Image(systemName: "scalemass")
                                .font(.system(size: 14))
                                .foregroundColor(primaryAccentColor)
                            Text("\(String(format: "%.1f", weight))")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(textColor)
                        }
                        Text("kg")
                            .font(.caption)
                            .foregroundColor(secondaryTextColor)
                    }
                } else {
                    VStack(spacing: 6) {
                        HStack(spacing: 5) {
                            Image(systemName: "scalemass")
                                .font(.system(size: 14))
                                .foregroundColor(primaryAccentColor)
                            Text("--")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(textColor)
                        }
                        Text("kg")
                            .font(.caption)
                            .foregroundColor(secondaryTextColor)
                    }
                }
                
                Divider().frame(height: 30)
                
                if let height = authViewModel.currentUser?.height {
                    VStack(spacing: 6) {
                        HStack(spacing: 5) {
                            Image(systemName: "ruler")
                                .font(.system(size: 14))
                                .foregroundColor(primaryAccentColor)
                            Text("\(String(format: "%.1f", height))")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(textColor)
                        }
                        Text("cm")
                            .font(.caption)
                            .foregroundColor(secondaryTextColor)
                    }
                } else {
                    VStack(spacing: 6) {
                        HStack(spacing: 5) {
                            Image(systemName: "ruler")
                                .font(.system(size: 14))
                                .foregroundColor(primaryAccentColor)
                            Text("--")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(textColor)
                        }
                        Text("cm")
                            .font(.caption)
                            .foregroundColor(secondaryTextColor)
                    }
                }
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 20)
            .background(cardBackgroundColor)
            .cornerRadius(15)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
        .padding(.horizontal)
        .padding(.vertical, 14)
        .background(backgroundColor)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        .padding(.horizontal)
    }
    
    // New BMI Card Section
    private func bmiCardSection(bmiValue: Double) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("BMI Information")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(textColor)
                
                Spacer()
                
                Button(action: {
                    showingBMIDetails = true
                }) {
                    Image(systemName: "info.circle")
                        .foregroundColor(primaryAccentColor)
                }
            }
            .padding(.horizontal)
            
            VStack(spacing: 15) {
                HStack {
                    // BMI Value Display
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Your BMI")
                            .font(.subheadline)
                            .foregroundColor(secondaryTextColor)
                        
                        Text(String(format: "%.1f", bmiValue))
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(bmiCategoryColor(for: bmiValue))
                    }
                    
                    Spacer()
                    
                    // BMI Category
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Category")
                            .font(.subheadline)
                            .foregroundColor(secondaryTextColor)
                        
                        Text(bmiCategory(for: bmiValue))
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(bmiCategoryColor(for: bmiValue))
                    }
                }
                .padding(.horizontal)
                
                // BMI Indicator
                VStack(spacing: 8) {
                    // BMI Scale visualization
                    bmiScaleView(bmiValue: bmiValue)
                    
                    // BMI Range labels
                    HStack {
                        Text("Underweight")
                            .font(.system(size: 10))
                            .foregroundColor(secondaryTextColor)
                        
                        Spacer()
                        
                        Text("Normal")
                            .font(.system(size: 10))
                            .foregroundColor(secondaryTextColor)
                        
                        Spacer()
                        
                        Text("Overweight")
                            .font(.system(size: 10))
                            .foregroundColor(secondaryTextColor)
                        
                        Spacer()
                        
                        Text("Obese")
                            .font(.system(size: 10))
                            .foregroundColor(secondaryTextColor)
                    }
                    .padding(.horizontal)
                }
                .padding(.top, 10)
                
                // Brief interpretation and tap to learn more
                HStack {
                    Text(bmiInterpretation(for: bmiValue))
                        .font(.caption)
                        .foregroundColor(secondaryTextColor)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                    
                    Button(action: {
                        showingBMIDetails = true
                    }) {
                        Text("View Details")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(primaryAccentColor)
                            .cornerRadius(15)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 6)
            }
            .padding(.vertical, 16)
            .background(cardBackgroundColor)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            .padding(.horizontal)
        }
        .padding(.vertical, 16)
        .background(backgroundColor)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        .padding(.horizontal)
        .onTapGesture {
            showingBMIDetails = true
        }
    }
    
    // BMI Scale Visualization
    private func bmiScaleView(bmiValue: Double) -> some View {
        ZStack(alignment: .leading) {
            // BMI Scale background
            HStack(spacing: 0) {
                Rectangle()
                    .fill(Color.blue.opacity(0.7))
                    .frame(height: 12)
                
                Rectangle()
                    .fill(Color.green.opacity(0.7))
                    .frame(height: 12)
                
                Rectangle()
                    .fill(Color.orange.opacity(0.7))
                    .frame(height: 12)
                
                Rectangle()
                    .fill(Color.red.opacity(0.7))
                    .frame(height: 12)
            }
            .cornerRadius(6)
            
            // BMI Indicator (position is calculated based on BMI value)
            GeometryReader { geometry in
                Circle()
                    .fill(Color.white)
                    .frame(width: 20, height: 20)
                    .overlay(
                        Circle()
                            .stroke(bmiCategoryColor(for: bmiValue), lineWidth: 3)
                    )
                    .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 1)
                    .position(
                        x: min(max(bmiIndicatorPosition(bmiValue: bmiValue, width: geometry.size.width), 10), geometry.size.width - 10),
                        y: 6
                    )
            }
            .frame(height: 12)
        }
        .padding(.horizontal)
    }
    
    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Activity Stats")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(textColor)
                .padding(.horizontal)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                EnhancedStatBox(
                    title: "Workouts",
                    value: "\(workoutViewModel.workouts.count)",
                    icon: "figure.walk",
                    iconBackground: .orange
                )
                
                EnhancedStatBox(
                    title: "Habits",
                    value: "\(habitViewModel.activeHabits.count)",
                    icon: "checkmark.circle",
                    iconBackground: .green
                )
                
                EnhancedStatBox(
                    title: "Streak",
                    value: "\(habitViewModel.topHabits.isEmpty ? 0 : habitViewModel.topHabits.first!.currentStreak)",
                    icon: "flame.fill",
                    iconBackground: .red
                )
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 16)
        .background(backgroundColor)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        .padding(.horizontal)
    }
    
    private var menuSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Settings")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(textColor)
                .padding(.horizontal)
            
            VStack(spacing: 0) {
                EnhancedSettingsRow(
                    icon: "gear",
                    title: "App Settings",
                    iconBackground: .blue
                ) {
                    showingSettings = true
                }
                
                Divider()
                    .padding(.leading, 60)
                    .padding(.trailing, 16)
                
                EnhancedSettingsRow(
                    icon: "bell",
                    title: "Notifications",
                    iconBackground: .purple
                ) {
                    loadSavedReminders()
                    showingNotifications = true
                }
                
                Divider()
                    .padding(.leading, 60)
                    .padding(.trailing, 16)
                
//                EnhancedSettingsRow(
//                    icon: "trophy",
//                    title: "Goals Tracker",
//                    iconBackground: .orange
//                ) {
//                    showingGoalsView = true
//                }
//
//                Divider()
//                    .padding(.leading, 60)
//                    .padding(.trailing, 16)
                
                EnhancedSettingsRow(
                    icon: "questionmark.circle",
                    title: "Help & Support",
                    iconBackground: .green
                ) {
                    showingFAQView = true
                }
            }
            .background(cardBackgroundColor)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.2 : 0.05), radius: 5, x: 0, y: 2)
            .padding(.horizontal)
        }
        .padding(.vertical, 16)
        .background(backgroundColor)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        .padding(.horizontal)
    }
    
    private var logoutButton: some View {
        Button(action: {
            showingLogoutAlert = true
        }) {
            HStack {
                Image(systemName: "arrow.right.square")
                    .font(.system(size: 16, weight: .semibold))
                Text("Log Out")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(.white)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(LinearGradient(
                gradient: Gradient(colors: [.red.opacity(0.8), .red]),
                startPoint: .leading,
                endPoint: .trailing
            ))
            .cornerRadius(15)
            .shadow(color: Color.red.opacity(0.3), radius: 5, x: 0, y: 3)
        }
        .padding(.horizontal)
    }
    
    // MARK: - Helper Functions
    
    private func calculateTotalStreaks() -> Int {
        return habitViewModel.activeHabits.reduce(0) { total, habit in
            return total + (habit.currentStreak > 0 ? 1 : 0)
        }
    }
    
    // BMI Helper Functions
    private func calculateBMI() -> Double? {
        guard let weight = authViewModel.currentUser?.weight,
              let height = authViewModel.currentUser?.height,
              height > 0 else {
            return nil
        }
        
        // BMI formula: weight(kg) / (height(m) * height(m))
        return weight / ((height/100) * (height/100))
    }
    
    private func bmiCategory(for bmi: Double) -> String {
        switch bmi {
        case ..<18.5:
            return "Underweight"
        case 18.5..<25:
            return "Normal"
        case 25..<30:
            return "Overweight"
        default:
            return "Obese"
        }
    }
    
    private func bmiCategoryColor(for bmi: Double) -> Color {
        switch bmi {
        case ..<18.5:
            return Color.blue
        case 18.5..<25:
            return Color.green
        case 25..<30:
            return Color.orange
        default:
            return Color.red
        }
    }
    
    private func bmiInterpretation(for bmi: Double) -> String {
        switch bmi {
        case ..<18.5:
            return "Consider consulting a healthcare professional about healthy weight gain strategies."
        case 18.5..<25:
            return "Your BMI indicates a healthy weight. Maintain your current habits."
        case 25..<30:
            return "Moderate weight loss through diet and exercise may be beneficial."
        default:
            return "Consider consulting a healthcare professional about weight management strategies."
        }
    }
    
    private func bmiIndicatorPosition(bmiValue: Double, width: CGFloat) -> CGFloat {
        // Map BMI value to position on the scale
        // We'll use 15 as the minimum BMI and 40 as the maximum for the scale
        let minBMI: Double = 15.0
        let maxBMI: Double = 40.0
        
        // Calculate the position percentage
        let percentage = min(max((bmiValue - minBMI) / (maxBMI - minBMI), 0), 1)
        
        // Return the position along the width
        return width * CGFloat(percentage)
    }
    
    // MARK: - Notification Helper Functions
    
    func loadReminderFromNotification(reminderId: String) {
        // Load reminders if not already loaded
        if savedReminders.isEmpty {
            loadSavedReminders()
        }
        
        if let reminder = savedReminders.first(where: { $0.id == reminderId }) {
            self.selectedReminder = reminder
            self.showingReminderDetails = true
        } else {
            // Reminder not found, try loading from UserDefaults
            if let savedRemindersData = UserDefaults.standard.data(forKey: "savedReminders") {
                do {
                    let decodedReminders = try JSONDecoder().decode([ReminderNotification].self, from: savedRemindersData)
                    if let reminder = decodedReminders.first(where: { $0.id == reminderId }) {
                        // Found the reminder, add it to our array and show it
                        self.savedReminders.append(reminder)
                        self.selectedReminder = reminder
                        self.showingReminderDetails = true
                    }
                } catch {
                    print("Error loading reminder from notification: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func updateReminder(_ reminder: ReminderNotification) {
        if let index = savedReminders.firstIndex(where: { $0.id == reminder.id }) {
            // Cancel existing notification
            cancelReminderNotification(savedReminders[index].id)
            
            // Update the reminder
            savedReminders[index] = reminder
            
            // Schedule new notification if active
            if notificationsEnabled && reminder.isActive {
                scheduleReminderNotification(reminder)
            }
            
            // Save reminders
            saveReminders()
        }
    }
    
    // MARK: - Reminders Functions
    
    private func loadSavedReminders() {
        if let savedRemindersData = UserDefaults.standard.data(forKey: "savedReminders") {
            do {
                let decodedReminders = try JSONDecoder().decode([ReminderNotification].self, from: savedRemindersData)
                self.savedReminders = decodedReminders
                
                // Initialize with default reminder if none exist
                if self.savedReminders.isEmpty {
                    createDefaultReminder()
                }
            } catch {
                print("Error loading saved reminders: \(error.localizedDescription)")
                
                // Create default reminder if decoding fails
                createDefaultReminder()
            }
        } else {
            // Create default reminder if no data exists
            createDefaultReminder()
        }
    }
    
    private func createDefaultReminder() {
        // Create a default daily reminder
        var components = DateComponents()
        components.hour = reminderTimeHour
        components.minute = reminderTimeMinute
        
        if let reminderTime = Calendar.current.date(from: components) {
            let defaultReminder = ReminderNotification(
                title: "Fitness Reminder",
                message: "Time to check your fitness progress!",
                time: reminderTime,
                isActive: notificationsEnabled,
                repeatPattern: .daily
            )
            
            savedReminders.append(defaultReminder)
            saveReminders()
            
            // Schedule the notification if enabled
            if notificationsEnabled {
                scheduleReminderNotification(defaultReminder)
            }
        }
    }
    
    private func saveReminders() {
        do {
            let encodedData = try JSONEncoder().encode(savedReminders)
            UserDefaults.standard.set(encodedData, forKey: "savedReminders")
            
            // Schedule all active reminders
            if notificationsEnabled {
                for reminder in savedReminders where reminder.isActive {
                    scheduleReminderNotification(reminder)
                }
            }
        } catch {
            print("Error saving reminders: \(error.localizedDescription)")
        }
    }
    
    private func scheduleReminderNotification(_ reminder: ReminderNotification) {
        NotificationManager.shared.scheduleReminderNotification(reminder)
    }
    
    private func cancelReminderNotification(_ reminderId: String) {
        NotificationManager.shared.cancelReminderNotifications(for: reminderId)
    }
}

// MARK: - Supporting Views

struct EnhancedStatBox: View {
    var title: String
    var value: String
    var icon: String
    var iconBackground: Color
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 12) {
            // Icon with colored background
            ZStack {
                Circle()
                    .fill(iconBackground.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(iconBackground)
            }
            
            // Value with large font
            Text(value)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(colorScheme == .dark ? .white : .primary)
            
            // Title with smaller font
            Text(title)
                .font(.system(size: 14))
                .foregroundColor(colorScheme == .dark ? .gray : .gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(colorScheme == .dark ? Color(UIColor.systemGray6) : Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct EnhancedSettingsRow: View {
    var icon: String
    var title: String
    var iconBackground: Color
    var action: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Button(action: action) {
            HStack {
                // Colored icon with background
                ZStack {
                    Circle()
                        .fill(iconBackground.opacity(0.2))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundColor(iconBackground)
                }
                .padding(.leading, 8)
                
                Text(title)
                    .font(.system(size: 16))
                    .foregroundColor(colorScheme == .dark ? .white : .primary)
                    .padding(.leading, 8)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .padding(.trailing, 8)
            }
            .padding(.vertical, 16)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Add a new BMI Detail View
struct BMIDetailView: View {
    let bmiValue: Double
    @Environment(\.colorScheme) var colorScheme
    
    private var textColor: Color { colorScheme == .dark ? .white : .primary }
    private var secondaryTextColor: Color { .gray }
    private var backgroundColor: Color { colorScheme == .dark ? Color(UIColor.systemBackground) : Color(UIColor.systemBackground) }
    private var cardBackgroundColor: Color { colorScheme == .dark ? Color(UIColor.systemGray6) : Color.white }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // BMI Value and Category
                VStack(alignment: .center, spacing: 10) {
                    Text("Your BMI")
                        .font(.headline)
                        .foregroundColor(secondaryTextColor)
                    
                    Text(String(format: "%.1f", bmiValue))
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(bmiCategoryColor(for: bmiValue))
                    
                    Text(bmiCategory(for: bmiValue))
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(bmiCategoryColor(for: bmiValue))
                        .padding(.vertical, 2)
                        .padding(.horizontal, 16)
                        .background(bmiCategoryColor(for: bmiValue).opacity(0.1))
                        .cornerRadius(20)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                
                // BMI Explanation Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("What is BMI?")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(textColor)
                    
                    Text("Body Mass Index (BMI) is a measure of body fat based on height and weight that applies to adult men and women. It's a simple calculation that helps assess health risks associated with weight.")
                        .font(.body)
                        .foregroundColor(textColor)
                        .lineSpacing(4)
                }
                .padding(16)
                .background(cardBackgroundColor)
                .cornerRadius(16)
                
                // BMI Categories Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("BMI Categories")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(textColor)
                    
                    VStack(spacing: 12) {
                        bmiCategoryRow(
                            category: "Underweight",
                            range: "Less than 18.5",
                            color: .blue,
                            description: "May indicate nutritional deficiency or other health issues."
                        )
                        
                        bmiCategoryRow(
                            category: "Normal Weight",
                            range: "18.5 - 24.9",
                            color: .green,
                            description: "Associated with the lowest health risks for most people."
                        )
                        
                        bmiCategoryRow(
                            category: "Overweight",
                            range: "25.0 - 29.9",
                            color: .orange,
                            description: "May increase risk of heart disease and other conditions."
                        )
                        
                        bmiCategoryRow(
                            category: "Obesity",
                            range: "30.0 or higher",
                            color: .red,
                            description: "Associated with increased risks of multiple health conditions."
                        )
                    }
                }
                .padding(16)
                .background(cardBackgroundColor)
                .cornerRadius(16)
                
                // BMI Limitations Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("BMI Limitations")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(textColor)
                    
                    Text("BMI is a useful screening tool, but it has limitations. It doesn't directly measure body fat, distinguish between muscle and fat, or account for factors like age, sex, ethnicity, and muscle mass. Athletes with high muscle mass might have a high BMI without health risks.")
                        .font(.body)
                        .foregroundColor(textColor)
                        .lineSpacing(4)
                    
                    Text("Always consult healthcare professionals for personalized health assessments.")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                        .padding(.top, 4)
                }
                .padding(16)
                .background(cardBackgroundColor)
                .cornerRadius(16)
                
                // Next Steps Section (customized for their BMI)
                VStack(alignment: .leading, spacing: 16) {
                    Text("Recommended Next Steps")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(textColor)
                    
                    Text(bmiRecommendation(for: bmiValue))
                        .font(.body)
                        .foregroundColor(textColor)
                        .lineSpacing(4)
                }
                .padding(16)
                .background(cardBackgroundColor)
                .cornerRadius(16)
            }
            .padding()
        }
        .background(colorScheme == .dark ? Color(UIColor.systemBackground) : Color(UIColor.systemGray6).opacity(0.3))
    }
    
    private func bmiCategoryRow(category: String, range: String, color: Color, description: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle()
                    .fill(color)
                    .frame(width: 12, height: 12)
                
                Text(category)
                    .font(.headline)
                    .foregroundColor(textColor)
                
                Spacer()
                
                Text(range)
                    .font(.subheadline)
                    .foregroundColor(secondaryTextColor)
            }
            
            Text(description)
                .font(.subheadline)
                .foregroundColor(secondaryTextColor)
                .padding(.leading, 24)
        }
        .padding(12)
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
    
    private func bmiCategory(for bmi: Double) -> String {
        switch bmi {
        case ..<18.5:
            return "Underweight"
        case 18.5..<25:
            return "Normal Weight"
        case 25..<30:
            return "Overweight"
        default:
            return "Obese"
        }
    }
    
    private func bmiCategoryColor(for bmi: Double) -> Color {
        switch bmi {
        case ..<18.5:
            return Color.blue
        case 18.5..<25:
            return Color.green
        case 25..<30:
            return Color.orange
        default:
            return Color.red
        }
    }
    
    private func bmiRecommendation(for bmi: Double) -> String {
        switch bmi {
        case ..<18.5:
            return "Consider consulting with a healthcare provider about healthy weight gain strategies. Focus on nutrient-dense foods and strength training to build muscle mass. Track your calorie intake to ensure you're consuming enough to support healthy weight gain."
        case 18.5..<25:
            return "Continue maintaining your healthy weight through balanced nutrition and regular physical activity. Focus on strength training to build muscle and cardio for heart health. Regular check-ups can help monitor your overall health status."
        case 25..<30:
            return "Consider moderate weight loss through a combination of dietary changes and increased physical activity. Aim for gradual weight loss of 1-2 pounds per week. Focus on portion control, reducing processed foods, and incorporating regular exercise into your routine."
        default:
            return "Consider consulting with healthcare professionals about weight management strategies. They may recommend a comprehensive approach including dietary changes, increased physical activity, and possibly behavioral therapy or medical interventions depending on your specific health situation."
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ProfileView()
                .environmentObject(AuthViewModel())
                .environmentObject(WorkoutViewModel())
                .environmentObject(HabitViewModel())
                .environmentObject(GoalViewModel())
                .environment(\.colorScheme, .dark) // Preview in dark mode
        }
        
        NavigationView {
            ProfileView()
                .environmentObject(AuthViewModel())
                .environmentObject(WorkoutViewModel())
                .environmentObject(HabitViewModel())
                .environmentObject(GoalViewModel())
                .environment(\.colorScheme, .light) // Preview in light mode
        }
    }
}
