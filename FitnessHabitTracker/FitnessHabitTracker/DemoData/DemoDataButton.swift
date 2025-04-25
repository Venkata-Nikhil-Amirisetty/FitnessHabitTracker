//
//  DemoDataButton.swift
//  FitnessHabitTracker
//
//  Created by Nikhil Av on 4/20/25.
//


//
//  DemoDataButton.swift
//  FitnessHabitTracker
//
//  Created on 4/20/25.
//

import SwiftUI
import SwiftData
import FirebaseAuth

struct DemoDataButton: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var workoutViewModel: WorkoutViewModel
    @EnvironmentObject var habitViewModel: HabitViewModel
    
    @Environment(\.modelContext) private var modelContext
    
    @State private var isGenerating = false
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    
    var body: some View {
        Button(action: generateDemoData) {
            if isGenerating {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
            } else {
                Text("Load Demo Data")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
        }
        .disabled(isGenerating)
        .padding(.horizontal)
        .alert(isPresented: $showingAlert) {
            Alert(
                title: Text(alertTitle),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    private func generateDemoData() {
        guard let userId = Auth.auth().currentUser?.uid else {
            alertTitle = "Error"
            alertMessage = "You must be logged in to generate demo data"
            showingAlert = true
            return
        }
        
        isGenerating = true
        
        DemoDataGenerator.generateDemoData(for: userId, modelContext: modelContext) { success in
            isGenerating = false
            
            if success {
                alertTitle = "Success"
                alertMessage = "Demo data has been generated successfully!"
                
                // Reload data in view models
                workoutViewModel.loadWorkouts()
                habitViewModel.loadHabits()
            } else {
                alertTitle = "Error"
                alertMessage = "Failed to generate demo data. Please try again."
            }
            
            showingAlert = true
        }
    }
}

// MARK: - Preview
struct DemoDataButton_Previews: PreviewProvider {
    static var previews: some View {
        DemoDataButton()
            .environmentObject(AuthViewModel())
            .environmentObject(WorkoutViewModel())
            .environmentObject(HabitViewModel())
    }
}