//
//  SignUpView.swift
//  FitnessHabitTracker
//
//  Created by Nikhil Av on 4/16/25.
//  Updated for SwiftData implementation with improved error handling


import SwiftUI
import FirebaseAuth

struct SignUpView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.presentationMode) var presentationMode
    
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isFormValid = false
    
    // Validation states
    @State private var emailIsValid = false
    @State private var passwordIsValid = false
    @State private var passwordsMatch = false
    
    // Track if fields have been touched - better UX to only show validation after user interaction
    @State private var emailTouched = false
    @State private var passwordTouched = false
    @State private var confirmPasswordTouched = false
    
    // Error handling
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Create Account")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.top, 30)
                    
                    VStack(spacing: 15) {
                        TextField("Full Name", text: $name)
                            .padding()
                            .background(Color.white.opacity(0.9))
                            .cornerRadius(10)
                            .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 1)
                            .cornerRadius(10)
                            .onChange(of: name) { _ in
                                validateForm()
                            }
                        
                        VStack(alignment: .leading, spacing: 5) {
                            TextField("Email", text: $email)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .autocorrectionDisabled(true)
                                .padding()
                                .background(Color.white.opacity(0.9))
                                .cornerRadius(10)
                                .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 1)
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(emailTouched && !emailIsValid ? Color.red : Color.clear, lineWidth: 1)
                                )
                                .onChange(of: email) { _ in
                                    emailTouched = true
                                    validateEmail()
                                    validateForm()
                                }
                            
                            if emailTouched && !emailIsValid {
                                Text("Please enter a valid email address")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 5) {
                            SecureField("Password", text: $password)
                                .padding()
                                .background(Color.white.opacity(0.9))
                                .cornerRadius(10)
                                .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 1)
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(passwordTouched && !passwordIsValid ? Color.red : Color.clear, lineWidth: 1)
                                )
                                .onChange(of: password) { _ in
                                    passwordTouched = true
                                    validatePassword()
                                    if confirmPasswordTouched {
                                        validatePasswordsMatch()
                                    }
                                    validateForm()
                                }
                            
                            if passwordTouched && !passwordIsValid {
                                Text("Password must be at least 6 characters")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 5) {
                            SecureField("Confirm Password", text: $confirmPassword)
                                .padding()
                                .background(Color.white.opacity(0.9))
                                .cornerRadius(10)
                                .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 1)
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(confirmPasswordTouched && !passwordsMatch ? Color.red : Color.clear, lineWidth: 1)
                                )
                                .onChange(of: confirmPassword) { _ in
                                    confirmPasswordTouched = true
                                    validatePasswordsMatch()
                                    validateForm()
                                }
                            
                            if confirmPasswordTouched && !passwordsMatch {
                                Text("Passwords do not match")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                        
                        // Password strength indicator
                        if passwordTouched && !password.isEmpty {
                            PasswordStrengthView(password: password)
                                .padding(.vertical, 5)
                        }
                        
                        Button(action: {
                            signUp()
                        }) {
                            if authViewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                                    .tint(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                            } else {
                                Text("Sign Up")
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                            }
                        }
                        .background(
                            Group {
                                if isFormValid {
                                    LinearGradient(colors: [.teal, .blue], startPoint: .leading, endPoint: .trailing)
                                } else {
                                    Color.gray
                                }
                            }
                        )
                        .cornerRadius(14)
                        .shadow(color: .black.opacity(isFormValid ? 0.2 : 0), radius: 4, x: 0, y: 2)
                        .padding(.horizontal)
                        .disabled(!isFormValid || authViewModel.isLoading)
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationBarItems(leading: Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Image(systemName: "xmark")
                    .foregroundColor(.gray)
            })
            .alert(isPresented: $showingErrorAlert) {
                Alert(
                    title: Text("Error"),
                    message: Text(errorMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            .onTapGesture {
                // Dismiss keyboard when tapping outside text fields
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
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
    
    // MARK: - Validation Methods
    
    private func validateEmail() {
        let emailRegex = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        emailIsValid = !email.isEmpty && emailPredicate.evaluate(with: email)
    }
    
    private func validatePassword() {
        // Password must be at least 6 characters
        passwordIsValid = !password.isEmpty && password.count >= 6
    }
    
    private func validatePasswordsMatch() {
        passwordsMatch = !confirmPassword.isEmpty && password == confirmPassword
    }
    
    private func validateForm() {
        isFormValid = !name.isEmpty &&
                     emailIsValid &&
                     passwordIsValid &&
                     passwordsMatch
    }
    
    private func signUp() {
        // Final validation check
        if !isFormValid {
            return
        }
        
        // Set loading state
        // authViewModel.isLoading is already used
        
        // Call AuthViewModel to sign up
        authViewModel.signUp(name: name, email: email, password: password) { error in
            if let error = error {
                // Log the detailed error for debugging
                print("Sign-up error details: \(error.localizedDescription)")
                
                // Show the actual error to the user
                self.errorMessage = error.localizedDescription
                self.showingErrorAlert = true
            }
            // Success case is handled by the AuthViewModel
        }
    }
}

// MARK: - Password Strength View
struct PasswordStrengthView: View {
    var password: String
    
    private var strengthLevel: PasswordStrength {
        return getPasswordStrength(password)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("Password Strength: \(strengthLevel.description)")
                .font(.caption)
                .foregroundColor(strengthLevel.color)
            
            // Progress bar for password strength
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .frame(width: geometry.size.width, height: 4)
                        .opacity(0.2)
                        .foregroundColor(Color.gray)
                    
                    Rectangle()
                        .frame(width: geometry.size.width * CGFloat(strengthLevel.percentage), height: 4)
                        .foregroundColor(strengthLevel.color)
                }
            }
            .frame(height: 4)
        }
    }
    
    private func getPasswordStrength(_ password: String) -> PasswordStrength {
        // Basic password strength calculation logic
        if password.count < 6 {
            return .weak
        }
        
        var score = 0
        
        // Length check
        if password.count >= 8 {
            score += 1
        }
        if password.count >= 12 {
            score += 1
        }
        
        // Complexity checks
        if password.contains(where: { $0.isNumber }) {
            score += 1
        }
        if password.contains(where: { $0.isLowercase }) && password.contains(where: { $0.isUppercase }) {
            score += 1
        }
        if password.contains(where: { !$0.isLetter && !$0.isNumber }) {
            score += 1
        }
        
        switch score {
        case 0...2:
            return .weak
        case 3:
            return .moderate
        case 4:
            return .strong
        default:
            return .veryStrong
        }
    }
}

// MARK: - Password Strength Enum
enum PasswordStrength {
    case weak, moderate, strong, veryStrong
    
    var description: String {
        switch self {
        case .weak: return "Weak"
        case .moderate: return "Moderate"
        case .strong: return "Strong"
        case .veryStrong: return "Very Strong"
        }
    }
    
    var color: Color {
        switch self {
        case .weak: return .red
        case .moderate: return .orange
        case .strong: return .blue
        case .veryStrong: return .green
        }
    }
    
    var percentage: Double {
        switch self {
        case .weak: return 0.25
        case .moderate: return 0.5
        case .strong: return 0.75
        case .veryStrong: return 1.0
        }
    }
}

struct SignUpView_Previews: PreviewProvider {
    static var previews: some View {
        SignUpView()
            .environmentObject(AuthViewModel())
    }
}

