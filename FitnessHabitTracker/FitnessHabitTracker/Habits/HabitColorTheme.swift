//
//  HabitColorTheme.swift
//  FitnessHabitTracker
//
//  Created by Nikhil Av on 4/17/25.
//


//
//  HabitColorModel.swift
//  FitnessHabitTracker
//
//  Created by Nikhil Av on 4/17/25.
//

import SwiftUI
import SwiftData

// MARK: - Color Theme
enum HabitColorTheme: String, CaseIterable, Codable {
    case blue = "blue"
    case green = "green"
    case red = "red"
    case purple = "purple"
    case orange = "orange"
    case teal = "teal"
    case pink = "pink"
    case indigo = "indigo"
    case yellow = "yellow"
    case mint = "mint"
    
    var color: Color {
        switch self {
        case .blue: return .blue
        case .green: return .green
        case .red: return .red
        case .purple: return .purple
        case .orange: return .orange
        case .teal: return .teal
        case .pink: return .pink
        case .indigo: return Color.indigo
        case .yellow: return .yellow
        case .mint: return Color.mint
        }
    }
    
    var name: String {
        return self.rawValue.capitalized
    }
    
    // Generate a light version for backgrounds
    var lightColor: Color {
        return color.opacity(0.2)
    }
    
    // Generate a medium version for buttons/accents
    var mediumColor: Color {
        return color.opacity(0.5)
    }
}

// MARK: - Tag Model
@Model
final class HabitTag {
    @Attribute(.unique) var id: String
    var name: String
    var colorThemeName: String
    var habitIDs: [String]
    
    var colorTheme: HabitColorTheme {
        get {
            return HabitColorTheme(rawValue: colorThemeName) ?? .blue
        }
        set {
            colorThemeName = newValue.rawValue
        }
    }
    
    init(id: String = UUID().uuidString, name: String, colorTheme: HabitColorTheme = .blue) {
        self.id = id
        self.name = name
        self.colorThemeName = colorTheme.rawValue
        self.habitIDs = []
    }
}

// MARK: - Habit Model Extension
extension Habit {
    // Add tags to a habit
    func addTag(_ tag: HabitTag) {
        if !tag.habitIDs.contains(self.id) {
            tag.habitIDs.append(self.id)
        }
    }
    
    // Remove a tag from a habit
    func removeTag(_ tag: HabitTag) {
        if let index = tag.habitIDs.firstIndex(of: self.id) {
            tag.habitIDs.remove(at: index)
        }
    }
    
    // Check if habit has a specific tag
    func hasTag(_ tag: HabitTag) -> Bool {
        return tag.habitIDs.contains(self.id)
    }
}