//
//  NotificationsView.swift
//  FitnessHabitTracker
//
//  Created to separate functionality from ProfileView

import SwiftUI
import UserNotifications

// MARK: - Notification Model (moved from ProfileView)
struct ReminderNotification: Identifiable, Codable {
    var id = UUID().uuidString
    var title: String
    var message: String
    var time: Date
    var isActive: Bool = true
    var repeatPattern: RepeatPattern = .daily
    
    enum RepeatPattern: String, Codable, CaseIterable {
        case daily = "Daily"
        case weekdays = "Weekdays"
        case weekends = "Weekends"
        case weekly = "Weekly"
        case custom = "Custom"
    }
}

// MARK: - Notifications View (extracted from ProfileView)
struct NotificationsView: View {
    @Binding var notificationsEnabled: Bool
    @Binding var savedReminders: [ReminderNotification]
    @Binding var reminderTimeHour: Int
    @Binding var reminderTimeMinute: Int
    
    @State private var reminderDate = Date()
    @State private var showingAddReminder = false
    @State private var showingReminderDetails = false
    @State private var selectedReminder: ReminderNotification?
    @State private var isLoading = true
    
    // Add state for observer management
    @State private var notificationObserver: NSObjectProtocol? = nil
    
    var body: some View {
        ZStack {
            Form {
                Section {
                    Toggle("Enable Notifications", isOn: $notificationsEnabled)
                        .onChange(of: notificationsEnabled) { newValue in
                            if newValue {
                                // Request notification permissions
                                requestNotificationPermission()
                            } else {
                                // Cancel all notifications if turned off
                                NotificationManager.shared.cancelAllNotifications()
                            }
                        }
                    
                    if notificationsEnabled {
                        DatePicker("Default Reminder Time", selection: $reminderDate, displayedComponents: .hourAndMinute)
                            .onChange(of: reminderDate) { newValue in
                                let components = Calendar.current.dateComponents([.hour, .minute], from: newValue)
                                reminderTimeHour = components.hour ?? 20
                                reminderTimeMinute = components.minute ?? 0
                                
                                // Update default reminder if it exists
                                DispatchQueue.global(qos: .userInitiated).async {
                                    updateDefaultReminder()
                                }
                            }
                            .onAppear {
                                // Set the date picker to show the saved time
                                var components = DateComponents()
                                components.hour = reminderTimeHour
                                components.minute = reminderTimeMinute
                                if let date = Calendar.current.date(from: components) {
                                    reminderDate = date
                                }
                            }
                    }
                }
                
                Section(header: Text("Reminders")) {
                    if savedReminders.isEmpty && !isLoading {
                        Text("No reminders set")
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 8)
                    } else {
                        ForEach(savedReminders) { reminder in
                            NavigationLink(destination: ReminderDetailView(reminder: reminder, onUpdate: { updatedReminder in
                                updateReminder(updatedReminder)
                            })) {
                                ReminderRow(reminder: reminder)
                            }
                        }
                        .onDelete(perform: deleteReminders)
                    }
                    
                    Button(action: {
                        showingAddReminder = true
                    }) {
                        Label("Add New Reminder", systemImage: "plus.circle")
                            .foregroundColor(.blue)
                    }
                }
            }
            .opacity(isLoading ? 0.6 : 1.0)
            
            if isLoading {
                ProgressView()
                    .scaleEffect(1.5)
                    .progressViewStyle(CircularProgressViewStyle())
            }
        }
        .sheet(isPresented: $showingAddReminder) {
            NavigationView {
                ReminderFormView(isNew: true, reminder: ReminderNotification(
                    title: "",
                    message: "",
                    time: reminderDate
                )) { reminder in
                    addReminder(reminder: reminder)
                    showingAddReminder = false
                }
                .navigationTitle("Add Reminder")
            }
        }
        .onAppear {
            // Initialize reminderDate on appear
            setupReminderDate()
            
            // Add observer for opening reminder details from notifications
            notificationObserver = NotificationCenter.default.addObserver(
                forName: NSNotification.Name("OpenReminderDetail"),
                object: nil,
                queue: .main
            ) { notification in
                if let reminderId = notification.userInfo?["reminderId"] as? String,
                   let reminder = self.savedReminders.first(where: { $0.id == reminderId }) {
                    // Set selected reminder and show details
                    self.selectedReminder = reminder
                    self.showingReminderDetails = true
                }
            }
            
            // Move data loading to background thread
            DispatchQueue.global(qos: .userInitiated).async {
                // Artificial small delay to allow UI to appear first
                Thread.sleep(forTimeInterval: 0.05)
                
                // Schedule any active notifications after view has appeared
                DispatchQueue.main.async {
                    isLoading = false
                    
                    // Schedule notifications after a slight delay
                    if notificationsEnabled {
                        DispatchQueue.global(qos: .utility).async {
                            for reminder in savedReminders where reminder.isActive {
                                scheduleReminderNotification(reminder)
                            }
                        }
                    }
                }
            }
        }
        .onDisappear {
            // Cleanup when view disappears
            if let observer = notificationObserver {
                NotificationCenter.default.removeObserver(observer)
                notificationObserver = nil
            }
            
            // Cancel any background tasks to prevent hanging
            cancelAllBackgroundTasks()
        }
    }
    
    // Setup reminder date from saved hour/minute
    private func setupReminderDate() {
        var components = DateComponents()
        components.hour = reminderTimeHour
        components.minute = reminderTimeMinute
        if let date = Calendar.current.date(from: components) {
            reminderDate = date
        }
    }
    
    // Method to cancel any background tasks
    private func cancelAllBackgroundTasks() {
        // No specific implementation needed, but this is where you would cancel
        // any dispatch work items or other long-running tasks if necessary
    }
    
    private func requestNotificationPermission() {
        NotificationManager.shared.requestAuthorization { granted in
            // Handle result
            print("Notification permission granted: \(granted)")
            
            // If permission granted, schedule active reminders on background thread
            if granted {
                DispatchQueue.global(qos: .utility).async {
                    for reminder in savedReminders where reminder.isActive {
                        scheduleReminderNotification(reminder)
                    }
                }
            }
        }
    }
    
    private func updateDefaultReminder() {
        // Find the default reminder if it exists
        DispatchQueue.main.async {
            if let defaultIndex = savedReminders.firstIndex(where: { $0.title == "Fitness Reminder" && $0.message == "Time to check your fitness progress!" }) {
                
                var components = DateComponents()
                components.hour = reminderTimeHour
                components.minute = reminderTimeMinute
                
                if let reminderTime = Calendar.current.date(from: components) {
                    savedReminders[defaultIndex].time = reminderTime
                    
                    // Reschedule the notification if it's active
                    if savedReminders[defaultIndex].isActive && notificationsEnabled {
                        let reminderToSchedule = savedReminders[defaultIndex]
                        DispatchQueue.global(qos: .utility).async {
                            scheduleReminderNotification(reminderToSchedule)
                        }
                    }
                }
            }
        }
    }
    
    private func addReminder(reminder: ReminderNotification) {
        savedReminders.append(reminder)
        
        // Schedule the notification if enabled
        if notificationsEnabled && reminder.isActive {
            let reminderToSchedule = reminder // Create a local copy
            DispatchQueue.global(qos: .utility).async {
                scheduleReminderNotification(reminderToSchedule)
            }
        }
    }
    
    private func updateReminder(_ reminder: ReminderNotification) {
        if let index = savedReminders.firstIndex(where: { $0.id == reminder.id }) {
            // Cancel existing notification
            let reminderId = savedReminders[index].id
            let updatedReminder = reminder // Create a local copy
            
            DispatchQueue.global(qos: .utility).async {
                cancelReminderNotification(reminderId)
                
                DispatchQueue.main.async {
                    // Update the reminder on main thread
                    if let updateIndex = savedReminders.firstIndex(where: { $0.id == reminderId }) {
                        savedReminders[updateIndex] = updatedReminder
                    }
                    
                    // Schedule new notification if active
                    if notificationsEnabled && updatedReminder.isActive {
                        DispatchQueue.global(qos: .utility).async {
                            scheduleReminderNotification(updatedReminder)
                        }
                    }
                }
            }
        }
    }
    
    private func deleteReminders(at offsets: IndexSet) {
        // Get IDs of reminders to delete before removing them
        let reminderIdsToDelete = offsets.map { savedReminders[$0].id }
        
        // Remove reminders from array
        savedReminders.remove(atOffsets: offsets)
        
        // Cancel notifications on background thread
        DispatchQueue.global(qos: .utility).async {
            for reminderId in reminderIdsToDelete {
                cancelReminderNotification(reminderId)
            }
        }
    }
    
    private func cancelReminderNotification(_ reminderId: String) {
        NotificationManager.shared.cancelReminderNotifications(for: reminderId)
    }
    
    private func scheduleReminderNotification(_ reminder: ReminderNotification) {
        NotificationManager.shared.scheduleReminderNotification(reminder)
    }
}

// MARK: - Reminder Row
struct ReminderRow: View {
    var reminder: ReminderNotification
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(reminder.title)
                    .font(.headline)
                
                Text(reminder.message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                HStack {
                    Text(formatTime(from: reminder.time))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(reminder.repeatPattern.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if reminder.isActive {
                Image(systemName: "bell.fill")
                    .foregroundColor(.blue)
            } else {
                Image(systemName: "bell.slash")
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatTime(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Reminder Detail View
struct ReminderDetailView: View {
    var reminder: ReminderNotification
    var onUpdate: (ReminderNotification) -> Void
    @Environment(\.presentationMode) var presentationMode
    
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    @State private var isProcessing = false
    @State private var isPreparingEditView = false
    
    var body: some View {
        ZStack {
            List {
                Section(header: Text("Reminder Details")) {
                    HStack {
                        Text("Title")
                        Spacer()
                        Text(reminder.title)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Message")
                        Spacer()
                        Text(reminder.message)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Time")
                        Spacer()
                        Text(formatTime(reminder.time))
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Repeat")
                        Spacer()
                        Text(reminder.repeatPattern.rawValue)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Status")
                        Spacer()
                        Text(reminder.isActive ? "Active" : "Inactive")
                            .foregroundColor(reminder.isActive ? .green : .red)
                    }
                }
                
                Section {
                    Button(action: {
                        // Show loading indicator briefly before showing edit sheet
                        isPreparingEditView = true
                        
                        // Small delay to allow UI to update
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                            isPreparingEditView = false
                            showingEditSheet = true
                        }
                    }) {
                        HStack {
                            Image(systemName: "pencil")
                            Text("Edit Reminder")
                        }
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .disabled(isProcessing || isPreparingEditView)
                    
                    Button(action: {
                        // Test the reminder to fire in 5 seconds
                        testReminder()
                    }) {
                        HStack {
                            Image(systemName: "play.fill")
                            Text("Test Reminder")
                        }
                        .foregroundColor(.orange)
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .disabled(isProcessing)
                    
                    Button(action: {
                        showingDeleteAlert = true
                    }) {
                        HStack {
                            Image(systemName: "trash.fill")
                            Text("Delete Reminder")
                        }
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .disabled(isProcessing)
                }
            }
            .opacity((isProcessing || isPreparingEditView) ? 0.6 : 1.0)
            
            if isProcessing || isPreparingEditView {
                ProgressView()
                    .scaleEffect(1.5)
                    .progressViewStyle(CircularProgressViewStyle())
            }
        }
        .navigationTitle(reminder.title)
        .sheet(isPresented: $showingEditSheet) {
            NavigationView {
                ReminderFormView(isNew: false, reminder: reminder) { updatedReminder in
                    isProcessing = true
                    
                    // Process update on background thread then return to main thread
                    DispatchQueue.global(qos: .userInitiated).async {
                        // Add small delay to show loading indicator
                        Thread.sleep(forTimeInterval: 0.05)
                        
                        DispatchQueue.main.async {
                            onUpdate(updatedReminder)
                            isProcessing = false
                            showingEditSheet = false
                        }
                    }
                }
                .navigationTitle("Edit Reminder")
            }
        }
        .alert(isPresented: $showingDeleteAlert) {
            Alert(
                title: Text("Delete Reminder"),
                message: Text("Are you sure you want to delete this reminder?"),
                primaryButton: .destructive(Text("Delete")) {
                    // Handle deletion - pass back to parent via onUpdate
                    isProcessing = true
                    
                    // Process deletion on background thread then return to main thread
                    DispatchQueue.global(qos: .userInitiated).async {
                        // Add small delay to show loading indicator
                        Thread.sleep(forTimeInterval: 0.05)
                        
                        var deletedReminder = reminder
                        deletedReminder.isActive = false
                        
                        DispatchQueue.main.async {
                            onUpdate(deletedReminder)
                            isProcessing = false
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                },
                secondaryButton: .cancel()
            )
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func testReminder() {
        isProcessing = true
        
        // Create test notification content
        let content = UNMutableNotificationContent()
        content.title = "TEST: \(reminder.title)"
        content.body = reminder.message
        content.sound = .default
        
        // Add reminder ID as context
        content.userInfo = [
            "reminderId": reminder.id
        ]
        
        // Fire test notification in 5 seconds
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        
        // Create the request
        let request = UNNotificationRequest(
            identifier: "test-reminder-\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        
        // Schedule the notification
        UNUserNotificationCenter.current().add(request) { error in
            DispatchQueue.main.async {
                self.isProcessing = false
                
                if let error = error {
                    print("Error scheduling test notification: \(error.localizedDescription)")
                } else {
                    print("Test notification scheduled successfully")
                }
            }
        }
    }
}

// MARK: - Reminder Form View
struct ReminderFormView: View {
    var isNew: Bool
    var initialReminder: ReminderNotification  // Use as read-only reference
    var onSave: (ReminderNotification) -> Void
    
    // State for form fields - initialized later for better performance
    @State private var title: String = ""
    @State private var message: String = ""
    @State private var time: Date = Date()
    @State private var isActive: Bool = true
    @State private var repeatPattern: ReminderNotification.RepeatPattern = .daily
    
    @Environment(\.presentationMode) var presentationMode
    
    @State private var showingValidationAlert = false
    @State private var validationMessage = ""
    @State private var isProcessing = false
    @State private var isInitializing = true
    
    // Lighter weight initializer that doesn't do as much work
    init(isNew: Bool, reminder: ReminderNotification, onSave: @escaping (ReminderNotification) -> Void) {
        self.isNew = isNew
        self.initialReminder = reminder
        self.onSave = onSave
        
        // Do NOT initialize state variables here - do it in onAppear
        // This makes the view creation faster
    }
    
    var body: some View {
        ZStack {
            Form {
                if isInitializing {
                    // Show placeholder content while initializing
                    Section {
                        Text("Loading reminder details...")
                            .foregroundColor(.secondary)
                    }
                } else {
                    // Real content once initialized
                    Section(header: Text("REMINDER DETAILS")) {
                        TextField("Title", text: $title)
                        TextField("Message", text: $message)
                        
                        DatePicker("Time", selection: $time, displayedComponents: .hourAndMinute)
                        
                        Picker("Repeat", selection: $repeatPattern) {
                            ForEach(ReminderNotification.RepeatPattern.allCases, id: \.self) { pattern in
                                Text(pattern.rawValue).tag(pattern)
                            }
                        }
                        
                        Toggle("Active", isOn: $isActive)
                    }
                    
                    Section {
                        Button(action: saveReminder) {
                            Text("Save Reminder")
                                .frame(maxWidth: .infinity, alignment: .center)
                                .foregroundColor(.blue)
                                .font(.headline)
                        }
                        .disabled(isProcessing)
                    }
                    
                    if !isNew {
                        Section {
                            Button(action: testReminder) {
                                Text("Test Reminder")
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .foregroundColor(.orange)
                            }
                            .disabled(isProcessing)
                        }
                    }
                }
            }
            .opacity((isProcessing || isInitializing) ? 0.6 : 1.0)
            
            if isProcessing || isInitializing {
                ProgressView()
                    .scaleEffect(1.5)
                    .progressViewStyle(CircularProgressViewStyle())
            }
        }
        .navigationTitle(isNew ? "New Reminder" : "Edit Reminder")
        .navigationBarItems(leading: Button("Cancel") {
            presentationMode.wrappedValue.dismiss()
        }
        .disabled(isProcessing))
        .alert(isPresented: $showingValidationAlert) {
            Alert(
                title: Text("Validation Error"),
                message: Text(validationMessage),
                dismissButton: .default(Text("OK"))
            )
        }
        .onAppear {
            // Initialize the state AFTER the view appears
            // This allows the view to render quickly
            initializeFormFields()
        }
    }
    
    private func initializeFormFields() {
        // Use a very short delay to allow the view to render first
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            // Then load the data from the initial reminder
            self.title = self.initialReminder.title
            self.message = self.initialReminder.message
            self.time = self.initialReminder.time
            self.isActive = self.initialReminder.isActive
            self.repeatPattern = self.initialReminder.repeatPattern
            
            // Mark initialization as complete
            self.isInitializing = false
        }
    }
    
    private func saveReminder() {
        // Validate input
        guard !title.isEmpty else {
            validationMessage = "Please enter a reminder title"
            showingValidationAlert = true
            return
        }
        
        isProcessing = true
        
        // Process saving on background thread
        DispatchQueue.global(qos: .userInitiated).async {
            // Create updated reminder
            var updatedReminder = self.initialReminder
            updatedReminder.title = self.title
            updatedReminder.message = self.message
            updatedReminder.time = self.time
            updatedReminder.isActive = self.isActive
            updatedReminder.repeatPattern = self.repeatPattern
            
            DispatchQueue.main.async {
                // Call onSave closure on main thread
                self.onSave(updatedReminder)
                
                self.isProcessing = false
                
                // Dismiss form
                self.presentationMode.wrappedValue.dismiss()
            }
        }
    }
    
    private func testReminder() {
        isProcessing = true
        
        // Create test notification content
        let content = UNMutableNotificationContent()
        content.title = "TEST: \(title)"
        content.body = message
        content.sound = .default
        
        // Add reminder ID for handling tap action
        content.userInfo = ["reminderId": initialReminder.id]
        
        // Fire test notification in 5 seconds
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        
        // Create the request
        let request = UNNotificationRequest(
            identifier: "test-reminder-\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        
        // Schedule the notification on background thread
        DispatchQueue.global(qos: .utility).async {
            // Schedule the notification
            UNUserNotificationCenter.current().add(request) { error in
                DispatchQueue.main.async {
                    self.isProcessing = false
                    
                    if let error = error {
                        print("Error scheduling test notification: \(error.localizedDescription)")
                    } else {
                        print("Test notification scheduled successfully")
                    }
                }
            }
        }
    }
}
