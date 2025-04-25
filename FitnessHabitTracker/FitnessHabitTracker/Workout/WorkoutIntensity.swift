//
//  WorkoutIntensity.swift
//  FitnessHabitTracker
//
//  Created by Nikhil Av on 4/16/25.
//


//
//  WorkoutIntensity.swift
//  FitnessHabitTracker
//
//  Created by Nikhil Av on 4/16/25.
//

import Foundation
import SwiftUI

enum WorkoutIntensity: String, Codable, CaseIterable {
    case light = "light"
    case moderate = "moderate"
    case intense = "intense"
    case maximum = "maximum"
    
    var color: Color {
        switch self {
        case .light: return .green
        case .moderate: return .blue
        case .intense: return .orange
        case .maximum: return .red
        }
    }
}
