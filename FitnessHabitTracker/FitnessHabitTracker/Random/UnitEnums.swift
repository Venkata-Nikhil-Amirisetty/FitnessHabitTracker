//
//  enum.swift
//  FitnessHabitTracker
//
//  Created by Nikhil Av on 4/19/25.
//


import Foundation
import SwiftUI

// Weight unit enum
enum WeightUnit: String, CaseIterable {
    case kg = "kg"
    case lb = "lb"
    
    // Convert between units
    func convert(_ value: Double, to unit: WeightUnit) -> Double {
        switch (self, unit) {
        case (.kg, .lb):
            return value * 2.20462
        case (.lb, .kg):
            return value * 0.453592
        default:
            return value
        }
    }
}

// Height unit enum
enum HeightUnit: String, CaseIterable {
    case cm = "cm"
    case `in` = "in"
    
    // Convert between units
    func convert(_ value: Double, to unit: HeightUnit) -> Double {
        switch (self, unit) {
        case (.cm, .in):
            return value * 0.393701
        case (.in, .cm):
            return value * 2.54
        default:
            return value
        }
    }
}