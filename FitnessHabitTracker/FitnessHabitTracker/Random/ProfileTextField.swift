//
// ProfileTextField.swift
// FitnessHabitTracker
//
// Created by Nikhil Av on 4/19/25.
//

import SwiftUI

struct ProfileTextField: View {
    var title: String
    @Binding var text: String
    var placeholder: String = ""
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.gray)
            TextField(placeholder.isEmpty ? title : placeholder, text: $text)
                .keyboardType(keyboardType)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
        }
    }
}
