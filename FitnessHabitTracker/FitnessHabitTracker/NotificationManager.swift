//
//  NotificationManager.swift
//  FitnessHabitTracker
//
//  Created by Nikhil Av on 4/16/25.
//  Updated with improved reminder handling


import Foundation
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()
    
    private init() {
        // Request authorization as soon as the manager is created
        requestAuthorization { _ in }
    }
    
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Error requesting notification authorization: \(error.localizedDescription)")
                }
                completion(granted)
            }
        }
    }
    
    func checkNotificationStatus(completion: @escaping (UNAuthorizationStatus) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                completion(settings.authorizationStatus)
            }
        }
    }
    
    // MARK: - Habit Reminders
    
    func scheduleHabitReminder(for habit: Habit, completion: @escaping (Bool) -> Void) {
        guard let reminderTime = habit.reminderTime else {
            completion(false)
            return
        }
        
        // Cancel any existing notifications for this habit first
        cancelHabitReminder(habitId: habit.id)
        
        checkNotificationStatus { status in
            guard status == .authorized else {
                print("Notification authorization not granted. Current status: \(status)")
                completion(false)
                return
            }
            
            // Create notification content
            let content = UNMutableNotificationContent()
            content.title = "Habit Reminder"
            content.body = "Time to complete your habit: \(habit.name)"
            content.sound = .default
            
            // Add category name as contextual information
            content.userInfo = [
                "habitId": habit.id,
                "habitName": habit.name,
                "habitCategory": habit.categoryName
            ]
            
            // Extract hour and minute components from the reminder time
            let calendar = Calendar.current
            let hour = calendar.component(.hour, from: reminderTime)
            let minute = calendar.component(.minute, from: reminderTime)
            
            // Create date components for the trigger
            var dateComponents = DateComponents()
            dateComponents.hour = hour
            dateComponents.minute = minute
            
            // Create the trigger for daily repetition
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            
            // Create the request with a unique identifier
            let request = UNNotificationRequest(
                identifier: "habit-\(habit.id)",
                content: content,
                trigger: trigger
            )
            
            // Schedule the notification
            UNUserNotificationCenter.current().add(request) { error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("Error scheduling notification: \(error.localizedDescription)")
                        completion(false)
                    } else {
                        print("Successfully scheduled notification for habit: \(habit.name)")
                        completion(true)
                    }
                }
            }
        }
    }
    
    func cancelHabitReminder(habitId: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["habit-\(habitId)"])
    }
    
    // MARK: - General Reminders
    
    func scheduleWorkoutReminder(title: String, body: String, date: Date, completion: @escaping (Bool) -> Void) {
        checkNotificationStatus { status in
            guard status == .authorized else {
                completion(false)
                return
            }
            
            // Create notification content
            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body
            content.sound = .default
            
            // Create the trigger
            let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
            let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
            
            // Create a unique identifier
            let identifier = "workout-\(UUID().uuidString)"
            
            // Create the request
            let request = UNNotificationRequest(
                identifier: identifier,
                content: content,
                trigger: trigger
            )
            
            // Schedule the notification
            UNUserNotificationCenter.current().add(request) { error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("Error scheduling workout notification: \(error.localizedDescription)")
                        completion(false)
                    } else {
                        completion(true)
                    }
                }
            }
        }
    }
    
    // MARK: - Custom Reminder Notifications
    
    func scheduleReminderNotification(_ reminder: ReminderNotification) -> Bool {
        var scheduled = false
        let semaphore = DispatchSemaphore(value: 0)
        
        self.checkNotificationStatus { status in
            guard status == .authorized else {
                semaphore.signal()
                return
            }
            
            // Extract hour and minute components
            let calendar = Calendar.current
            let hour = calendar.component(.hour, from: reminder.time)
            let minute = calendar.component(.minute, from: reminder.time)
            
            // Create date components
            var dateComponents = DateComponents()
            dateComponents.hour = hour
            dateComponents.minute = minute
            
            // Handle different repeat patterns
            switch reminder.repeatPattern {
            case .daily:
                self.scheduleDailyReminder(reminder, dateComponents)
                scheduled = true
                semaphore.signal()
                
            case .weekdays:
                for weekday in 2...6 { // Monday to Friday
                    var components = dateComponents
                    components.weekday = weekday
                    self.scheduleReminder(reminder, with: components, weekdayIdentifier: weekday)
                }
                scheduled = true
                semaphore.signal()
                
            case .weekends:
                for weekday in [1, 7] { // Sunday and Saturday
                    var components = dateComponents
                    components.weekday = weekday
                    self.scheduleReminder(reminder, with: components, weekdayIdentifier: weekday)
                }
                scheduled = true
                semaphore.signal()
                
            case .weekly:
                // Schedule on current day of week
                let currentWeekday = calendar.component(.weekday, from: Date())
                var components = dateComponents
                components.weekday = currentWeekday
                self.scheduleReminder(reminder, with: components, weekdayIdentifier: currentWeekday)
                scheduled = true
                semaphore.signal()
                
            case .custom:
                // Default to daily for now
                self.scheduleDailyReminder(reminder, dateComponents)
                scheduled = true
                semaphore.signal()
            }
        }
        
        // Wait for completion
        _ = semaphore.wait(timeout: .now() + 5.0)
        return scheduled
    }
    
    private func scheduleDailyReminder(_ reminder: ReminderNotification, _ dateComponents: DateComponents) {
        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = reminder.title
        content.body = reminder.message
        content.sound = .default
        
        // Add reminder ID as context
        content.userInfo = [
            "reminderId": reminder.id,
            "reminderType": "daily"
        ]
        
        // Create trigger
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        // Create request
        let request = UNNotificationRequest(
            identifier: "reminder-\(reminder.id)-daily",
            content: content,
            trigger: trigger
        )
        
        // Schedule notification
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling daily notification: \(error.localizedDescription)")
            }
        }
    }
    
    private func scheduleReminder(_ reminder: ReminderNotification, with dateComponents: DateComponents, weekdayIdentifier: Int) {
        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = reminder.title
        content.body = reminder.message
        content.sound = .default
        
        // Add reminder ID as context
        content.userInfo = [
            "reminderId": reminder.id,
            "reminderType": weekdayIdentifier == 1 || weekdayIdentifier == 7 ? "weekend" : "weekday",
            "weekday": weekdayIdentifier
        ]
        
        // Create trigger
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        // Create request with unique identifier including the weekday
        let request = UNNotificationRequest(
            identifier: "reminder-\(reminder.id)-\(weekdayIdentifier)",
            content: content,
            trigger: trigger
        )
        
        // Schedule notification
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling weekday notification: \(error.localizedDescription)")
            }
        }
    }
    
    func cancelReminderNotifications(for reminderId: String) {
        var identifiers: [String] = []
        
        // Add daily identifier
        identifiers.append("reminder-\(reminderId)-daily")
        
        // Add weekday identifiers (1-7)
        for weekday in 1...7 {
            identifiers.append("reminder-\(reminderId)-\(weekday)")
        }
        
        // Remove all notification requests with these identifiers
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
    }
    
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    // MARK: - Notification Handling
    
    func handleNotificationTap(with identifier: String) -> ReminderNotification? {
        // Parse the reminder ID from the notification identifier
        let components = identifier.components(separatedBy: "-")
        guard components.count >= 2 else { return nil }
        
        let reminderId = components[1]
        
        // Load saved reminders from UserDefaults
        if let savedRemindersData = UserDefaults.standard.data(forKey: "savedReminders") {
            do {
                let decodedReminders = try JSONDecoder().decode([ReminderNotification].self, from: savedRemindersData)
                
                // Find the matching reminder
                return decodedReminders.first { $0.id == reminderId }
            } catch {
                print("Error loading reminder for notification: \(error.localizedDescription)")
            }
        }
        
        return nil
    }
    
    func printAllPendingNotifications() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            print("Pending notifications (\(requests.count)):")
            for request in requests {
                print("ID: \(request.identifier), Title: \(request.content.title)")
            }
        }
    }
}
