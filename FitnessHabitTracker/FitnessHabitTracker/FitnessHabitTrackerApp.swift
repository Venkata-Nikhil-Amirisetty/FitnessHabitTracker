//
//  FitnessHabitTrackerApp.swift
//  FitnessHabitTracker
//
//  Updated with profile image preloading
//

import SwiftUI
import SwiftData
import FirebaseCore
import FirebaseAuth

@main
struct FitnessHabitTrackerApp: App {
    // Register app delegate for Firebase setup and notifications
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var habitViewModel = HabitViewModel()
    @StateObject private var workoutViewModel = WorkoutViewModel()
    @StateObject private var goalViewModel = GoalViewModel() // Added GoalViewModel
    @AppStorage("darkModeEnabled") private var darkModeEnabled = false
    
    // Add state to track initialization
    @State private var hasCompletedInitialSetup = false
    
    init() {
        print("FitnessHabitTrackerApp initializing")
    }
    
    var body: some Scene {
        WindowGroup {
            if authViewModel.isAuthenticated {
                DashboardView()
                    .environmentObject(authViewModel)
                    .environmentObject(habitViewModel)
                    .environmentObject(workoutViewModel)
                    .environmentObject(goalViewModel)
                    .preferredColorScheme(darkModeEnabled ? .dark : .light)
                    .onAppear {
                        if !hasCompletedInitialSetup {
                            // Call the startup image preload and cache functions
                            preloadCurrentUserImage()
                            hasCompletedInitialSetup = true
                        }
                    }
                    .onOpenURL { url in
                        // Handle URL schemes for deep linking
                        print("App opened with URL: \(url)")
                    }
            } else {
                LoginView()
                    .environmentObject(authViewModel)
                    .preferredColorScheme(darkModeEnabled ? .dark : .light)
            }
        }
        .modelContainer(for: [Workout.self, Habit.self, User.self, Goal.self]) { result in // Added Goal.self
            switch result {
            case .success(let container):
                print("SwiftData model container configured successfully")
                
                // Pass the ModelContext to our ViewModels
                workoutViewModel.setModelContext(container.mainContext)
                habitViewModel.setModelContext(container.mainContext)
                authViewModel.setModelContext(container.mainContext)
                goalViewModel.setModelContext(container.mainContext) // Added context for GoalViewModel
                
                // Setup ViewModel relationships for proper goal tracking
                workoutViewModel.setGoalViewModel(goalViewModel)
                habitViewModel.setGoalViewModel(goalViewModel)
                
            case .failure(let error):
                // Handle any error
                print("Failed to configure SwiftData model container: \(error.localizedDescription)")
            }
        }
    }
    
    // Function to preload current user's profile image
    private func preloadCurrentUserImage() {
        print("Checking for profile image to preload...")
        
        if let user = authViewModel.currentUser, let imageURL = user.profileImageURL, !imageURL.isEmpty {
            print("Found profile image URL to preload: \(imageURL)")
            
            // Verify URL is valid
            ProfileImageService.shared.verifyImageURL(imageURL) { exists in
                if exists {
                    print("Image URL is valid, preloading image")
                    
                    // Load and cache the image
                    ProfileImageService.shared.loadProfileImage(from: imageURL) { loadedImage in
                        if let loadedImage = loadedImage {
                            print("Successfully preloaded profile image at app startup")
                            
                            // Save to both memory and disk cache
                            ProfileImageManager.shared.cacheImage(loadedImage, for: imageURL)
                            
                            // Notify views to refresh
                            DispatchQueue.main.async {
                                ProfileImageManager.shared.notifyImageUpdated()
                            }
                        } else {
                            print("Failed to preload profile image at app startup")
                        }
                    }
                } else {
                    print("Warning: Image URL doesn't exist or is inaccessible, might need to update user profile")
                }
            }
        } else {
            print("No profile image URL found for current user")
        }
    }
}

// MARK: - Modified LoginView with Firebase Auth
struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var showingSignUp = false
    @State private var showingResetPassword = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 60)

            // Logo + App Name
            VStack(spacing: 8) {
                Image(systemName: "figure.run")
                    .resizable()
                    .frame(width: 60, height: 60)
                    .foregroundColor(.black)
                    .shadow(radius: 6)

                Text("FitHabit Tracker")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(radius: 2)
            }
            .padding(.bottom, 30)

            // Custom Blur Form
            ZStack {
                RoundedRectangle(cornerRadius: 25)
                    .fill(Color.white.opacity(0.15)) // less intense than .ultraThinMaterial
                    .background(.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 25)
                            .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
                    )
                    .shadow(radius: 8)

                VStack(spacing: 16) {
                    RoundedTextField(placeholder: "Email", text: $email, isSecure: false)
                    RoundedTextField(placeholder: "Password", text: $password, isSecure: true)

                    HStack {
                        Spacer()
                        Button("Forgot Password?") {
                            showingResetPassword = true
                        }
                        .font(.footnote)
                        .foregroundColor(.white)
                    }

                    Button(action: {
                        authViewModel.login(email: email, password: password)
                    }) {
                        HStack {
                            if authViewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Sign In")
                                    .fontWeight(.bold)
                            }
                            Spacer().frame(width: 8)
                            Image(systemName: "arrow.right")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(colors: [.teal, .blue], startPoint: .leading, endPoint: .trailing)
                        )
                        .foregroundColor(.white)
                        .cornerRadius(14)
                        .shadow(radius: 5)
                    }
                    .disabled(authViewModel.isLoading)
                }
                .padding()
            }
            .padding(.horizontal)
            .padding(.bottom, 20)

            Spacer()

            // Sign Up Section
            HStack(spacing: 4) {
                Text("Don't have an account?")
                    .foregroundColor(.black)
                Button(action: {
                    showingSignUp = true
                }) {
                    Text("Sign Up")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
            }
            .padding(.bottom, 30)
        }
        .padding()
        .sheet(isPresented: $showingSignUp) {
            SignUpView()
                .environmentObject(authViewModel)
        }
        .sheet(isPresented: $showingResetPassword) {
            PasswordResetView()
        }
        .alert(isPresented: $authViewModel.showingError) {
            Alert(
                title: Text("Error"),
                message: Text(authViewModel.errorMessage),
                dismissButton: .default(Text("OK"))
            )
        }
        .background(
            ZStack {
                Image("fitnessbg")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()

                Color.black.opacity(0.25)
                    .ignoresSafeArea()
            }
        )
    }
}



// MARK: - Reusable Styled Text Field
struct RoundedTextField: View {
    var placeholder: String
    @Binding var text: String
    var isSecure: Bool

    var body: some View {
        Group {
            if isSecure {
                SecureField(placeholder, text: $text)
            } else {
                TextField(placeholder, text: $text)
                    .keyboardType(placeholder.lowercased() == "email" ? .emailAddress : .default)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}


// MARK: - Password Reset View
struct PasswordResetView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var email = ""
    @State private var message = ""
    @State private var showingAlert = false
    @State private var isSuccess = false
    @State private var isLoading = false

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Reset Password")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .shadow(radius: 2)

                Text("Enter your email address and we'll send you a link to reset your password.")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .autocorrectionDisabled(true)
                    .padding()
                    .background(Color.white.opacity(0.9))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
                    )

                // Send Reset Link Button
                Button(action: resetPassword) {
                    if isLoading {
                        ProgressView()
                    } else {
                        Text("Send Reset Link")
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(colors: [.teal, .blue], startPoint: .leading, endPoint: .trailing)
                            )
                            .foregroundColor(.white)
                            .cornerRadius(14)
                            .shadow(radius: 5)
                    }
                }
                .disabled(email.isEmpty || isLoading)
                .padding(.horizontal)

                // Cancel Button (Styled)
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Cancel")
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(colors: [.gray.opacity(0.4), .gray.opacity(0.6)], startPoint: .leading, endPoint: .trailing)
                        )
                        .foregroundColor(.white)
                        .cornerRadius(14)
                        .shadow(radius: 2)
                }
                .padding(.horizontal)

                Spacer()
            }
            .padding(.top, 40)
            .alert(isPresented: $showingAlert) {
                Alert(
                    title: Text(isSuccess ? "Success" : "Error"),
                    message: Text(message),
                    dismissButton: .default(Text("OK")) {
                        if isSuccess {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                )
            }
            .background(
                ZStack {
                    Image("fitnessbg")
                        .resizable()
                        .scaledToFill()
                        .ignoresSafeArea()

                    Color.black.opacity(0.25)
                        .ignoresSafeArea()
                }
            )
        }
    }


    
    private func resetPassword() {
        guard !email.isEmpty else { return }
        
        isLoading = true
        
        Auth.auth().sendPasswordReset(withEmail: email) { error in
            isLoading = false
            
            if let error = error {
                message = error.localizedDescription
                isSuccess = false
            } else {
                message = "Password reset link sent to \(email). Please check your inbox."
                isSuccess = true
            }
            
            showingAlert = true
        }
    }
}
