
//
//  DistanceUnit.swift
//  FitnessHabitTracker
//
//  Created by Nikhil Av on 4/16/25.
//

import Foundation
import SwiftUI

enum DistanceUnit: String, Codable, CaseIterable {
    case km = "km"
    case mi = "mi"
    
    func convert(_ value: Double, to unit: DistanceUnit) -> Double {
        switch (self, unit) {
        case (.km, .mi):
            return value / 1.60934
        case (.mi, .km):
            return value * 1.60934
        default:
            return value
        }
    }
}
