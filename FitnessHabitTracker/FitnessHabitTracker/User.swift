//
//  User.swift
//  FitnessHabitTracker
//
//  Created by Nikhil Av on 4/16/25.
//  Updated for SwiftData


import Foundation
import SwiftData

@Model
final class User {
    var id: String
    var name: String
    var email: String
    var passwordHash: String // Store password hash instead of plain text
    var profileImageURL: String?
    var weight: Double?
    var height: Double?
    var fitnessGoal: String?
    var joinDate: Date
    var isCurrentUser: Bool // Flag to identify the current user
    
    init(id: String = UUID().uuidString,
         name: String,
         email: String,
         passwordHash: String,
         profileImageURL: String? = nil,
         weight: Double? = nil,
         height: Double? = nil,
         fitnessGoal: String? = nil,
         joinDate: Date = Date(),
         isCurrentUser: Bool = false) {
        self.id = id
        self.name = name
        self.email = email
        self.passwordHash = passwordHash
        self.profileImageURL = profileImageURL
        self.weight = weight
        self.height = height
        self.fitnessGoal = fitnessGoal
        self.joinDate = joinDate
        self.isCurrentUser = isCurrentUser
    }
    
    // Simple password hashing function (for demo only - use a more secure method in production)
    static func hashPassword(_ password: String) -> String {
        // In a real app, use a secure hashing algorithm like PBKDF2, bcrypt, or Argon2
        // This is a simple hash for demonstration purposes only
        let data = Data(password.utf8)
        let hash = data.base64EncodedString()
        return hash
    }
}
