//
//  ColorExtension.swift
//  FitnessHabitTracker
//
//  Created by Nikhil Av on 4/16/25.
//

import Foundation
import SwiftUI

extension Color {
    static let background = Color("Background")
    static let cardBackground = Color("CardBackground")
    static let textPrimary = Color("TextPrimary")
    static let textSecondary = Color("TextSecondary")
    static let accent = Color.blue
    static let accentBackground = Color.blue.opacity(0.1)
    
    // Helper method to create dynamic colors
    static func dynamicColor(light: Color, dark: Color) -> Color {
        return Color(UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .light, .unspecified:
                return UIColor(light)
            case .dark:
                return UIColor(dark)
            @unknown default:
                return UIColor(light)
            }
        })
    }
}
