//
//  FileService.swift
//  FitnessHabitTracker
//
//  Created on 4/17/25.
//

import Foundation
import SwiftUI
import SwiftData

enum ExportFormat {
    case csv
    case json
    
    var fileExtension: String {
        switch self {
        case .csv:
            return "csv"
        case .json:
            return "json"
        }
    }
    
    var mimeType: String {
        switch self {
        case .csv:
            return "text/csv"
        case .json:
            return "application/json"
        }
    }
}

class FileService {
    static let shared = FileService()
    
    private init() {}
    
    // MARK: - Export
    
    func exportUserData(_ user: User, workouts: [Workout] = [], habits: [Habit] = [], format: ExportFormat) -> URL? {
        do {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyyMMdd_HHmmss"
            let dateString = formatter.string(from: Date())
            
            let fileName = "FitnessTrackerData_\(dateString).\(format.fileExtension)"
            let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
            
            if format == .csv {
                try exportAsCSV(user: user, workouts: workouts, habits: habits, to: fileURL)
            } else {
                try exportAsJSON(user: user, workouts: workouts, habits: habits, to: fileURL)
            }
            
            return fileURL
        } catch {
            print("Error exporting data: \(error.localizedDescription)")
            return nil
        }
    }
    
    private func exportAsCSV(user: User, workouts: [Workout], habits: [Habit], to fileURL: URL) throws {
        // User data header and row
        var csvString = "id,name,email,weight,height,fitnessGoal,profileImageURL,joinDate\n"
        
        // Format join date
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let joinDateStr = dateFormatter.string(from: user.joinDate)
        
        // Add user data
        csvString += "\"\(user.id)\",\"\(user.name)\",\"\(user.email)\","
        csvString += "\(user.weight != nil ? String(format: "%.1f", user.weight!) : ""),"
        csvString += "\(user.height != nil ? String(format: "%.1f", user.height!) : ""),"
        csvString += "\"\(user.fitnessGoal ?? "")\","
        csvString += "\"\(user.profileImageURL ?? "")\","
        csvString += "\"\(joinDateStr)\"\n"
        
        // NOTE: Password hash is intentionally NOT exported for security reasons
        
        // Add workouts if provided
        if !workouts.isEmpty {
            csvString += "\nworkouts\n"
            csvString += "id,name,type,duration,date,calories,notes,distance,intensity,avgHeartRate,maxHeartRate\n"
            
            for workout in workouts {
                let workoutDateStr = dateFormatter.string(from: workout.date)
                
                csvString += "\"\(workout.id)\",\"\(workout.name)\",\"\(workout.typeName)\","
                csvString += "\(workout.duration),"
                csvString += "\"\(workoutDateStr)\","
                csvString += "\(workout.caloriesBurned),"
                csvString += "\"\(workout.notes ?? "")\","
                csvString += "\(workout.distance != nil ? String(format: "%.2f", workout.distance!) : ""),"
                csvString += "\"\(workout.intensityName ?? "")\","
                csvString += "\(workout.averageHeartRate != nil ? String(format: "%.0f", workout.averageHeartRate!) : ""),"
                csvString += "\(workout.maxHeartRate != nil ? String(format: "%.0f", workout.maxHeartRate!) : "")\n"
            }
        }
        
        // Add habits if provided
        if !habits.isEmpty {
            csvString += "\nhabits\n"
            csvString += "id,name,category,frequency,targetDaysPerWeek,startDate,description,isArchived,isWeatherSensitive\n"
            
            for habit in habits {
                let startDateStr = dateFormatter.string(from: habit.startDate)
                
                csvString += "\"\(habit.id)\",\"\(habit.name)\",\"\(habit.categoryName)\","
                csvString += "\"\(habit.frequencyName)\","
                csvString += "\(habit.targetDaysPerWeek),"
                csvString += "\"\(startDateStr)\","
                csvString += "\"\(habit.descriptionText ?? "")\","
                csvString += "\(habit.isArchived),"
                csvString += "\(habit.isWeatherSensitive)\n"
            }
        }
        
        try csvString.write(to: fileURL, atomically: true, encoding: .utf8)
    }
    
    private func exportAsJSON(user: User, workouts: [Workout], habits: [Habit], to fileURL: URL) throws {
        // Format date for JSON
        let dateFormatter = ISO8601DateFormatter()
        
        // Build user data dictionary without sensitive information
        var userData: [String: Any] = [
            "id": user.id,
            "name": user.name,
            "email": user.email,
            "joinDate": dateFormatter.string(from: user.joinDate)
        ]
        
        if let weight = user.weight {
            userData["weight"] = weight
        }
        
        if let height = user.height {
            userData["height"] = height
        }
        
        if let fitnessGoal = user.fitnessGoal {
            userData["fitnessGoal"] = fitnessGoal
        }
        
        if let profileImageURL = user.profileImageURL {
            userData["profileImageURL"] = profileImageURL
        }
        
        // NOTE: Password hash is intentionally NOT exported for security reasons
        
        // Convert workouts to dictionaries with date conversion
        var workoutsData: [[String: Any]] = []
        if !workouts.isEmpty {
            workoutsData = workouts.map { workout in
                var workoutDict = FirebaseManager.shared.dictionaryFromWorkout(workout)
                
                // Convert date to string to avoid Firebase Timestamp issues
                workoutDict["date"] = dateFormatter.string(from: workout.date)
                
                return workoutDict
            }
        }
        
        // Convert habits to dictionaries with date conversion
        var habitsData: [[String: Any]] = []
        if !habits.isEmpty {
            habitsData = habits.map { habit in
                var habitDict = FirebaseManager.shared.dictionaryFromHabit(habit)
                
                // Convert start date to string
                habitDict["startDate"] = dateFormatter.string(from: habit.startDate)
                
                // Convert completed dates array to strings
                habitDict["completedDates"] = habit.completedDates.map { dateFormatter.string(from: $0) }
                
                // Handle reminder time if it exists
                if let reminderTime = habit.reminderTime {
                    habitDict["reminderTime"] = dateFormatter.string(from: reminderTime)
                }
                
                return habitDict
            }
        }
        
        // Create a dictionary with all data
        let exportData: [String: Any] = [
            "userData": userData,
            "exportDate": dateFormatter.string(from: Date()),
            "appVersion": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0",
            "workouts": workoutsData,
            "habits": habitsData
        ]
        
        // Use JSONSerialization with clean data (no Firebase timestamps)
        let jsonData = try JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted)
        try jsonData.write(to: fileURL)
    }
    
    // MARK: - Import
    
    func importUserData(from url: URL, format: ExportFormat, currentUser: User) -> Bool {
        do {
            print("Starting import from \(url.absoluteString)")
            if format == .csv {
                return try importFromCSV(url: url, currentUser: currentUser)
            } else {
                return try importFromJSON(url: url, currentUser: currentUser)
            }
        } catch {
            print("Error importing data: \(error.localizedDescription)")
            return false
        }
    }
    
    private func importFromCSV(url: URL, currentUser: User) throws -> Bool {
        print("Importing from CSV file")
        let csvString = try String(contentsOf: url, encoding: .utf8)
        let lines = csvString.components(separatedBy: .newlines)
        
        guard lines.count >= 2 else {
            print("CSV file has insufficient lines")
            return false
        }
        
        // Skip header line (index 0) and use data line (index 1)
        let values = lines[1].components(separatedBy: ",")
        guard values.count >= 7 else {
            print("CSV user data row has insufficient columns")
            return false
        }
        
        // Parse CSV values
        let name = values[1].replacingOccurrences(of: "\"", with: "")
        // We intentionally skip email value (index 2) to prevent changing it
        let weight = Double(values[3])
        let height = Double(values[4])
        let fitnessGoal = values[5].replacingOccurrences(of: "\"", with: "")
        let profileImageURL = values[6].replacingOccurrences(of: "\"", with: "")
        
        // Update the current user with imported data, but NOT email
        currentUser.name = name
        // SECURITY: Email not updated from import data to prevent account takeover
        currentUser.weight = weight
        currentUser.height = height
        currentUser.fitnessGoal = fitnessGoal.isEmpty ? nil : fitnessGoal
        currentUser.profileImageURL = profileImageURL.isEmpty ? nil : profileImageURL
        
        print("Updated user data from CSV (email preserved)")
        
        // Process workouts section if present
        var lineIndex = 3  // Start searching after user data
        while lineIndex < lines.count {
            if lineIndex < lines.count && lines[lineIndex].lowercased().contains("workouts") {
                print("Found workouts section in CSV")
                // Process workouts - post notification with the workouts section data
                let workoutsData = processCSVSection(lines: lines, startIndex: lineIndex)
                if !workoutsData.isEmpty {
                    NotificationCenter.default.post(
                        name: NSNotification.Name("ImportWorkoutsFromCSVNotification"),
                        object: nil,
                        userInfo: ["csvData": workoutsData]
                    )
                }
            }
            
            if lineIndex < lines.count && lines[lineIndex].lowercased().contains("habits") {
                print("Found habits section in CSV")
                // Process habits - post notification with the habits section data
                let habitsData = processCSVSection(lines: lines, startIndex: lineIndex)
                if !habitsData.isEmpty {
                    NotificationCenter.default.post(
                        name: NSNotification.Name("ImportHabitsFromCSVNotification"),
                        object: nil,
                        userInfo: ["csvData": habitsData]
                    )
                }
            }
            
            lineIndex += 1
        }
        
        return true
    }
    
    private func processCSVSection(lines: [String], startIndex: Int) -> [String] {
        var sectionLines: [String] = []
        var currentIndex = startIndex
        
        // Skip the section header line
        currentIndex += 1
        
        // Add all lines until a blank line or the end of the file
        while currentIndex < lines.count {
            let line = lines[currentIndex].trimmingCharacters(in: .whitespacesAndNewlines)
            if line.isEmpty || line.starts(with: "\n") {
                break
            }
            sectionLines.append(line)
            currentIndex += 1
        }
        
        return sectionLines
    }
    
    private func importFromJSON(url: URL, currentUser: User) throws -> Bool {
        print("Importing from JSON file")
        let jsonData = try Data(contentsOf: url)
        
        guard let jsonDict = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            print("Failed to parse JSON into dictionary")
            return false
        }
        
        print("Successfully parsed JSON: \(jsonDict.keys)")
        
        // Update user data if present, but NOT email
        if let userData = jsonDict["userData"] as? [String: Any] {
            print("Found user data, updating profile (preserving email)...")
            
            if let name = userData["name"] as? String {
                print("Updating name to: \(name)")
                currentUser.name = name
            }
            
            // SECURITY: Email not updated from import data to prevent account takeover
            // if let email = userData["email"] as? String {
            //    currentUser.email = email
            // }
            
            if let weight = userData["weight"] as? Double {
                print("Updating weight to: \(weight)")
                currentUser.weight = weight
            }
            
            if let height = userData["height"] as? Double {
                print("Updating height to: \(height)")
                currentUser.height = height
            }
            
            if let fitnessGoal = userData["fitnessGoal"] as? String {
                print("Updating fitness goal")
                currentUser.fitnessGoal = fitnessGoal
            }
            
            if let profileImageURL = userData["profileImageURL"] as? String {
                print("Updating profile image URL")
                currentUser.profileImageURL = profileImageURL
            }
        }
        
        // Notify WorkoutViewModel to import workouts if present
        if let workoutsData = jsonDict["workouts"] as? [[String: Any]], !workoutsData.isEmpty {
            print("Found \(workoutsData.count) workouts, notifying for import...")
            
            NotificationCenter.default.post(
                name: NSNotification.Name("ImportWorkoutsNotification"),
                object: nil,
                userInfo: ["workouts": workoutsData]
            )
        }
        
        // Notify HabitViewModel to import habits if present
        if let habitsData = jsonDict["habits"] as? [[String: Any]], !habitsData.isEmpty {
            print("Found \(habitsData.count) habits, notifying for import...")
            
            NotificationCenter.default.post(
                name: NSNotification.Name("ImportHabitsNotification"),
                object: nil,
                userInfo: ["habits": habitsData]
            )
        }
        
        return true
    }
    
    // MARK: - Share File
    
    func shareFile(at url: URL, from viewController: UIViewController? = nil) {
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        
        if let viewController = viewController {
            activityVC.popoverPresentationController?.sourceView = viewController.view
            viewController.present(activityVC, animated: true)
        } else {
            // Find the top view controller if none provided
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let rootViewController = window.rootViewController {
                
                var currentVC = rootViewController
                while let presented = currentVC.presentedViewController {
                    currentVC = presented
                }
                
                activityVC.popoverPresentationController?.sourceView = currentVC.view
                currentVC.present(activityVC, animated: true)
            }
        }
    }
}
