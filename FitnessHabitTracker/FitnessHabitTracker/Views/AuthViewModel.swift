//
//  AuthViewModel.swift
//  FitnessHabitTracker
//
//  Updated with improved profile image handling and data persistence
//

import SwiftUI
import Combine
import SwiftData
import FirebaseAuth
import FirebaseFirestore

class AuthViewModel: ObservableObject {
    @Published var currentUser: User?
    @Published var firebaseUser: FirebaseAuth.User?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var showingError = false
    
    private var cancellables = Set<AnyCancellable>()
    private var modelContext: ModelContext?
    
    init() {
        print("Initializing AuthViewModel")
        
        // Check if user is already signed in
        if let firebaseUser = Auth.auth().currentUser {
            print("User already signed in: \(firebaseUser.uid)")
            self.firebaseUser = firebaseUser
            self.isAuthenticated = true
            fetchUserData(uid: firebaseUser.uid)
        } else {
            print("No user is signed in")
        }
        
        // Listen for auth state changes
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                if let user = user {
                    print("Auth state changed: User signed in - \(user.uid)")
                    self.firebaseUser = user
                    self.isAuthenticated = true
                    self.fetchUserData(uid: user.uid)
                    
                    // Notify other view models about user authentication
                    NotificationCenter.default.post(
                        name: NSNotification.Name("UserDidChangeNotification"),
                        object: nil,
                        userInfo: ["userId": user.uid]
                    )
                } else {
                    print("Auth state changed: User signed out")
                    self.firebaseUser = nil
                    self.currentUser = nil
                    self.isAuthenticated = false
                    
                    // Notify other view models about user logout
                    NotificationCenter.default.post(
                        name: NSNotification.Name("UserDidChangeNotification"),
                        object: nil,
                        userInfo: nil
                    )
                }
            }
        }
    }
    
    func setModelContext(_ context: ModelContext) {
        print("Setting ModelContext in AuthViewModel")
        self.modelContext = context
        
        // If user is already authenticated, check for local data
        if let firebaseUser = Auth.auth().currentUser {
            print("User already authenticated, checking local session: \(firebaseUser.uid)")
            checkUserSession(userId: firebaseUser.uid)
        }
    }
    
    private func checkUserSession(userId: String) {
        guard let modelContext = modelContext else {
            print("Error: ModelContext not set")
            return
        }
        
        do {
            print("Checking for local user data with ID: \(userId)")
            // Look for user with matching ID
            let descriptor = FetchDescriptor<User>()
            let savedUsers = try modelContext.fetch(descriptor)
            
            // Filter users manually
            let matchingUsers = savedUsers.filter { $0.id == userId }
            
            if let savedUser = matchingUsers.first {
                // User exists locally
                print("Found user locally: \(savedUser.name), profileImageURL: \(savedUser.profileImageURL ?? "nil")")
                self.currentUser = savedUser
                
                // Make sure the isCurrentUser flag is set
                if !savedUser.isCurrentUser {
                    savedUser.isCurrentUser = true
                    try modelContext.save()
                }
                
                // Pre-load profile image if available
                if let imageURL = savedUser.profileImageURL, !imageURL.isEmpty {
                    preloadProfileImage(from: imageURL)
                } else {
                    print("No profile image URL found for local user")
                }
            } else {
                print("User not found locally, fetching from Firestore")
                // User not found locally, fetch from Firestore
                fetchUserData(uid: userId)
            }
        } catch {
            print("Error fetching user data: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Authentication Methods
    
    func login(email: String, password: String) {
        isLoading = true
        
        // Simple validation
        if email.isEmpty || password.isEmpty {
            self.isLoading = false
            self.errorMessage = "Please enter both email and password"
            self.showingError = true
            return
        }
        
        print("Attempting to log in with email: \(email)")
        
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let error = error {
                    print("Login error: \(error.localizedDescription)")
                    self.errorMessage = error.localizedDescription
                    self.showingError = true
                    return
                }
                
                if let user = result?.user {
                    print("Login successful: \(user.uid)")
                }
                
                // Auth state listener will handle the rest
            }
        }
    }
    
    func signUp(name: String, email: String, password: String, completion: @escaping (Error?) -> Void = {_ in }) {
        isLoading = true
        
        // Simple validation
        if name.isEmpty || email.isEmpty || password.isEmpty {
            self.isLoading = false
            self.errorMessage = "Please fill in all fields"
            self.showingError = true
            completion(NSError(domain: "AuthError", code: 400, userInfo: [NSLocalizedDescriptionKey: "Please fill in all fields"]))
            return
        }
        
        print("Attempting to create user with email: \(email)")
        
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                if let error = error {
                    self.isLoading = false
                    self.errorMessage = error.localizedDescription
                    self.showingError = true
                    print("Firebase Auth Error: \(error.localizedDescription)")
                    completion(error)
                    return
                }
                
                if let firebaseUser = result?.user {
                    print("User created successfully with ID: \(firebaseUser.uid)")
                    
                    // Create user profile in Firestore
                    let newUser = User(
                        id: firebaseUser.uid,
                        name: name,
                        email: email,
                        passwordHash: "", // No need to store password hash with Firebase Auth
                        isCurrentUser: true
                    )
                    
                    self.saveUserToFirestore(newUser)
                    self.saveUserLocally(newUser)
                    
                    self.isLoading = false
                    completion(nil)
                } else {
                    self.isLoading = false
                    let error = NSError(domain: "AuthError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to create user. No user returned from Firebase."])
                    self.errorMessage = error.localizedDescription
                    self.showingError = true
                    print("No user returned from Firebase")
                    completion(error)
                }
            }
        }
    }
    
    // MARK: - User Data Methods
    
    private func fetchUserData(uid: String) {
        print("Fetching user data from Firestore for ID: \(uid)")
        let db = FirebaseManager.shared.firestore
        
        db.collection("users").document(uid).getDocument { [weak self] document, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Error fetching user data: \(error.localizedDescription)")
                return
            }
            
            if let document = document, document.exists {
                let data = document.data() ?? [:]
                print("User document found: \(data)")
                
                // Extract profileImageURL directly to verify it's present
                if let profileImageURL = data["profileImageURL"] as? String {
                    print("Profile image URL from document: \(profileImageURL)")
                } else {
                    print("No profile image URL found in document")
                }
                
                // Convert Firestore data to User object
                if let user = FirebaseManager.shared.userFromDictionary(data) {
                    print("User object created: \(user.name), profileImageURL: \(user.profileImageURL ?? "nil")")
                    
                    DispatchQueue.main.async {
                        self.currentUser = user
                        self.saveUserLocally(user)
                        
                        // Pre-load profile image if available
                        if let imageURL = user.profileImageURL, !imageURL.isEmpty {
                            self.preloadProfileImage(from: imageURL)
                        } else {
                            print("No profile image URL to preload")
                        }
                    }
                } else {
                    print("Failed to convert document data to User object")
                }
            } else {
                print("User document doesn't exist, creating new user profile")
                // Document doesn't exist, user might be new
                if let firebaseUser = Auth.auth().currentUser {
                    // Create a basic user profile
                    let newUser = User(
                        id: firebaseUser.uid,
                        name: firebaseUser.displayName ?? "User",
                        email: firebaseUser.email ?? "",
                        passwordHash: "",
                        isCurrentUser: true
                    )
                    
                    self.saveUserToFirestore(newUser)
                    
                    DispatchQueue.main.async {
                        self.currentUser = newUser
                        self.saveUserLocally(newUser)
                    }
                }
            }
        }
    }
    
    // Pre-load profile image for immediate display
    private func preloadProfileImage(from imageURL: String) {
        print("Preloading profile image from URL: \(imageURL)")
        
        // Verify if the image URL actually exists
        ProfileImageService.shared.verifyImageURL(imageURL) { exists in
            if exists {
                print("Image URL verified, loading image")
                
                // Load and cache the image
                ProfileImageService.shared.loadProfileImage(from: imageURL) { loadedImage in
                    if let loadedImage = loadedImage {
                        print("Successfully preloaded profile image")
                        
                        // Cache the image for immediate use
                        ProfileImageManager.shared.cacheImage(loadedImage, for: imageURL)
                        
                        // Notify any views that might be waiting for the image
                        ProfileImageManager.shared.notifyImageUpdated()
                    } else {
                        print("Failed to preload profile image")
                    }
                }
            } else {
                print("Warning: Image URL doesn't exist or is inaccessible")
            }
        }
    }
    
    func saveUserToFirestore(_ user: User) {
        print("Saving user to Firestore: \(user.id)")
        let db = FirebaseManager.shared.firestore
        
        // Convert User to Dictionary using helper method
        let userData = FirebaseManager.shared.dictionaryFromUser(user)
        
        // Save to Firestore
        db.collection("users").document(user.id).setData(userData) { error in
            if let error = error {
                print("Error saving user to Firestore: \(error.localizedDescription)")
            } else {
                print("User saved to Firestore successfully with data: \(userData)")
            }
        }
    }
    
    private func saveUserLocally(_ user: User) {
        guard let modelContext = modelContext else {
            print("Error: ModelContext not set")
            return
        }
        
        print("Saving user to local database: \(user.id)")
        
        // Reset isCurrentUser flag for all users
        do {
            let descriptor = FetchDescriptor<User>()
            let existingUsers = try modelContext.fetch(descriptor)
            
            for existingUser in existingUsers {
                existingUser.isCurrentUser = (existingUser.id == user.id)
            }
        } catch {
            print("Error updating user flags: \(error.localizedDescription)")
        }
        
        // Check if user already exists locally
        do {
            let descriptor = FetchDescriptor<User>()
            let existingUsers = try modelContext.fetch(descriptor)
            
            // Find users manually instead of using predicates
            let matchingUsers = existingUsers.filter { $0.id == user.id }
            
            if let existingUser = matchingUsers.first {
                // Update existing user
                print("Updating existing user: \(existingUser.id)")
                existingUser.name = user.name
                existingUser.email = user.email
                
                // Important: Update profile image URL
                print("Previous profileImageURL: \(existingUser.profileImageURL ?? "nil")")
                existingUser.profileImageURL = user.profileImageURL
                print("Updated profileImageURL: \(existingUser.profileImageURL ?? "nil")")
                
                existingUser.weight = user.weight
                existingUser.height = user.height
                existingUser.fitnessGoal = user.fitnessGoal
                existingUser.isCurrentUser = true
                
                self.currentUser = existingUser
            } else {
                // Insert new user
                print("Inserting new user: \(user.id)")
                modelContext.insert(user)
                self.currentUser = user
            }
            
            try modelContext.save()
            print("User saved to local database successfully")
            
            // Pre-load profile image if available
            if let imageURL = user.profileImageURL, !imageURL.isEmpty {
                preloadProfileImage(from: imageURL)
            }
        } catch {
            print("Error saving user locally: \(error.localizedDescription)")
        }
    }
    
    // Updated method to better handle profile image URL updates
    func updateUser(_ user: User) {
        print("Updating user with profileImageURL: \(user.profileImageURL ?? "nil")")
        
        let db = FirebaseManager.shared.firestore
        let userRef = db.collection("users").document(user.id)
        
        // Build the user data dictionary
        var userData: [String: Any] = [
            "id": user.id,
            "name": user.name,
            "email": user.email
        ]
        
        // Explicitly add profile image URL
        if let profileImageURL = user.profileImageURL {
            userData["profileImageURL"] = profileImageURL
            print("Including profile image URL in update: \(profileImageURL)")
        } else {
            // For Firebase, use a delete field operation to remove the field if it's nil
            userData["profileImageURL"] = NSNull()
            print("No profile image URL to include in update")
        }
        
        // Add other fields
        if let weight = user.weight {
            userData["weight"] = weight
        }
        
        if let height = user.height {
            userData["height"] = height
        }
        
        if let fitnessGoal = user.fitnessGoal {
            userData["fitnessGoal"] = fitnessGoal
        }
        
        // Update in Firestore
        userRef.setData(userData, merge: true) { [weak self] error in
            guard let self = self else { return }
            
            if let error = error {
                print("Error updating user in Firestore: \(error.localizedDescription)")
            } else {
                print("User successfully updated in Firestore")
                
                // Verify the data was saved correctly by reading it back
                userRef.getDocument { document, _ in
                    if let document = document, document.exists {
                        let savedData = document.data() ?? [:]
                        print("Verified saved data: \(savedData)")
                        
                        if let savedURL = savedData["profileImageURL"] as? String {
                            print("Verified profile image URL: \(savedURL)")
                        } else {
                            print("WARNING: Profile image URL not found in verified data!")
                        }
                    }
                }
                
                // Update SwiftData model if available
                if let modelContext = self.modelContext {
                    do {
                        print("Updating user in SwiftData...")
                        
                        // Find the user in SwiftData - using manual filter instead of predicate
                        let descriptor = FetchDescriptor<User>()
                        let existingUsers = try modelContext.fetch(descriptor)
                        let matchingUsers = existingUsers.filter { $0.id == user.id }
                        
                        if let existingUser = matchingUsers.first {
                            // Update existing user
                            existingUser.name = user.name
                            existingUser.email = user.email
                            
                            // Update profile image URL
                            print("SwiftData: Previous profileImageURL: \(existingUser.profileImageURL ?? "nil")")
                            existingUser.profileImageURL = user.profileImageURL
                            print("SwiftData: Updated profileImageURL: \(existingUser.profileImageURL ?? "nil")")
                            
                            existingUser.weight = user.weight
                            existingUser.height = user.height
                            existingUser.fitnessGoal = user.fitnessGoal
                            existingUser.isCurrentUser = true
                            
                            try modelContext.save()
                            print("User updated in SwiftData successfully")
                        } else {
                            // If user not found in SwiftData, insert it
                            print("User not found in SwiftData, inserting new record")
                            modelContext.insert(user)
                            try modelContext.save()
                            print("User inserted into SwiftData")
                        }
                    } catch {
                        print("Error updating user in SwiftData: \(error.localizedDescription)")
                    }
                }
                
                // Update the current user in memory to ensure UI updates
                DispatchQueue.main.async {
                    print("Updating current user in memory")
                    self.currentUser = user
                    
                    // Important: Force UI refresh
                    self.objectWillChange.send()
                    
                    // Notify image manager that profile image was updated
                    ProfileImageManager.shared.notifyImageUpdated()
                    
                    // If there's a profile image URL, preload it
                    if let imageURL = user.profileImageURL, !imageURL.isEmpty {
                        self.preloadProfileImage(from: imageURL)
                    }
                }
            }
        }
    }
    
    func logout() {
        print("Logging out...")
        do {
            // Reset local user state
            if let modelContext = modelContext, let currentUser = currentUser {
                print("Resetting current user flag")
                currentUser.isCurrentUser = false
                try modelContext.save()
            }
            
            // Clear image caches
            print("Clearing image caches")
            ProfileImageService.shared.clearCache()
            ProfileImageManager.shared.clearCache()
            
            // Sign out from Firebase
            try Auth.auth().signOut()
            print("Successfully signed out from Firebase")
            
            // Auth state listener will handle the rest
        } catch {
            print("Error signing out: \(error.localizedDescription)")
            self.errorMessage = "Failed to sign out"
            self.showingError = true
        }
    }
}
