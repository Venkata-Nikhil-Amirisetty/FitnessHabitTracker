//
//  EditProfileView.swift
//  FitnessHabitTracker
//
//  Updated with improved UI while maintaining all functionality
//

import SwiftUI
import SwiftData
import PhotosUI

struct EditProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    
    var user: User
    @State private var profileImage: UIImage?
    @State private var isImagePickerPresented = false
    @State private var isLoading = false
    @State private var uploadedImageURL: String? = nil
    
    // Form state variables
    @State private var name: String
    @State private var email: String
    @State private var weight: String
    @State private var height: String
    @State private var fitnessGoal: String
    
    // Unit selection states
    @State private var selectedWeightUnit: WeightUnit = .kg
    @State private var selectedHeightUnit: HeightUnit = .cm
    
    // For validation
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    // Track if user has interacted with fields
    @State private var hasInteractedWithWeight = false
    @State private var hasInteractedWithHeight = false
    
    // Image manager reference
    @ObservedObject private var imageManager = ProfileImageManager.shared
    
    // Colors for better UI
    private var primaryColor: Color { Color.blue }
    private var cardBackground: Color { colorScheme == .dark ? Color(UIColor.systemGray6) : Color.white }
    private var inputBackground: Color { colorScheme == .dark ? Color(UIColor.systemGray5) : Color.gray.opacity(0.1) }
    private var textColor: Color { colorScheme == .dark ? .white : .primary }
    private var captionColor: Color { colorScheme == .dark ? Color.gray.opacity(0.8) : Color.gray }
    
    init(user: User) {
        self.user = user
        
        // Initialize state properties with user data
        _name = State(initialValue: user.name)
        _email = State(initialValue: user.email)
        _weight = State(initialValue: user.weight != nil ? String(format: "%.1f", user.weight!) : "")
        _height = State(initialValue: user.height != nil ? String(format: "%.1f", user.height!) : "")
        _fitnessGoal = State(initialValue: user.fitnessGoal ?? "")
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Profile Image Section
                profileImageSection
                    .padding(.top, 8)
                
                // Form Cards
                VStack(spacing: 20) {
                    // Personal Info Card
                    formCard(title: "Personal Information", systemImage: "person.fill") {
                        VStack(spacing: 18) {
                            // Name field
                            formField(
                                title: "Name",
                                systemImage: "person.text.rectangle",
                                placeholder: "Enter your name",
                                text: $name,
                                keyboardType: .default,
                                required: true
                            )
                            
                            // Email field (non-editable)
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "envelope")
                                        .font(.system(size: 15))
                                        .foregroundColor(primaryColor)
                                    
                                    Text("Email")
                                        .font(.headline)
                                        .foregroundColor(textColor)
                                }
                                
                                // Display email as text instead of TextField
                                Text(email)
                                    .padding(12)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(inputBackground.opacity(0.5))
                                    .cornerRadius(10)
                                    .foregroundColor(textColor.opacity(0.8))
                            }
                        }
                    }
                    
                    // Body Metrics Card
                    formCard(title: "Body Metrics", systemImage: "figure.stand") {
                        VStack(spacing: 18) {
                            // Weight field with unit selection
                            weightFieldWithUnit
                            
                            // Height field with unit selection
                            heightFieldWithUnit
                        }
                    }
                    
                    // Fitness Goal Card
                    formCard(title: "Fitness Goal", systemImage: "target") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("What are you aiming to achieve?")
                                .font(.subheadline)
                                .foregroundColor(captionColor)
                            
                            TextEditor(text: $fitnessGoal)
                                .frame(minHeight: 120)
                                .padding(8)
                                .background(inputBackground)
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                )
                                .font(.body)
                        }
                    }
                }
                .padding(.horizontal)
                
                // Save Button
                saveButton
                    .padding(.horizontal)
                    .padding(.top, 10)
                    .padding(.bottom, 40)
            }
        }
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(leading: Button("Cancel") {
            presentationMode.wrappedValue.dismiss()
        })
        .alert(isPresented: $showingAlert) {
            Alert(
                title: Text("Error"),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
        .sheet(isPresented: $isImagePickerPresented) {
            ImagePicker(selectedImage: $profileImage)
        }
        .onTapGesture {
            hideKeyboard()
        }
        .background(colorScheme == .dark ? Color(UIColor.systemBackground) : Color(UIColor.systemGray6).opacity(0.3))
        .edgesIgnoringSafeArea(.bottom)
    }
    
    // MARK: - UI Components
    
    private var profileImageSection: some View {
        VStack(spacing: 14) {
            ZStack(alignment: .bottomTrailing) {
                // Profile image
                Group {
                    if let profileImage = profileImage {
                        Image(uiImage: profileImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(primaryColor.opacity(0.3), lineWidth: 2))
                            .shadow(color: Color.black.opacity(0.1), radius: 6, x: 0, y: 3)
                    } else if let profileImageURL = user.profileImageURL, !profileImageURL.isEmpty {
                        ProfileImageView(imageURL: profileImageURL)
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(primaryColor.opacity(0.3), lineWidth: 2))
                            .shadow(color: Color.black.opacity(0.1), radius: 6, x: 0, y: 3)
                    } else {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .foregroundColor(.gray)
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(primaryColor.opacity(0.3), lineWidth: 2))
                            .shadow(color: Color.black.opacity(0.1), radius: 6, x: 0, y: 3)
                    }
                }
                
                // Camera button overlay
                Button(action: {
                    isImagePickerPresented = true
                }) {
                    ZStack {
                        Circle()
                            .fill(primaryColor)
                            .frame(width: 34, height: 34)
                            .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 1)
                        
                        Image(systemName: "camera.fill")
                            .font(.system(size: 15))
                            .foregroundColor(.white)
                    }
                }
                .offset(x: 8, y: 5)
            }
            
            Text("Tap to change profile photo")
                .font(.caption)
                .foregroundColor(primaryColor)
        }
        .padding(.bottom, 10)
    }
    
    private var weightFieldWithUnit: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "scalemass.fill")
                    .foregroundColor(primaryColor)
                    .font(.system(size: 15))
                
                Text("Weight")
                    .font(.headline)
                    .foregroundColor(textColor)
                
                if !weightIsValid && hasInteractedWithWeight {
                    Spacer()
                    Text("Invalid")
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            
            HStack(spacing: 10) {
                TextField("Weight", text: $weight, onEditingChanged: { editing in
                    if editing {
                        hasInteractedWithWeight = true
                    }
                })
                .keyboardType(.decimalPad)
                .padding(12)
                .background(inputBackground)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(weightIsValid || !hasInteractedWithWeight ? Color.clear : Color.red, lineWidth: 1)
                )
                
                // Unit picker with improved style
                Picker("", selection: $selectedWeightUnit) {
                    ForEach(WeightUnit.allCases, id: \.self) { unit in
                        Text(unit.rawValue).tag(unit)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 100)
            }
        }
    }
    
    private var heightFieldWithUnit: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "ruler.fill")
                    .foregroundColor(primaryColor)
                    .font(.system(size: 15))
                
                Text("Height")
                    .font(.headline)
                    .foregroundColor(textColor)
                
                if !heightIsValid && hasInteractedWithHeight {
                    Spacer()
                    Text("Invalid")
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            
            HStack(spacing: 10) {
                TextField("Height", text: $height, onEditingChanged: { editing in
                    if editing {
                        hasInteractedWithHeight = true
                    }
                })
                .keyboardType(.decimalPad)
                .padding(12)
                .background(inputBackground)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(heightIsValid || !hasInteractedWithHeight ? Color.clear : Color.red, lineWidth: 1)
                )
                
                // Unit picker
                Picker("", selection: $selectedHeightUnit) {
                    ForEach(HeightUnit.allCases, id: \.self) { unit in
                        Text(unit.rawValue).tag(unit)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 100)
            }
        }
    }
    
    private var saveButton: some View {
        Button(action: saveProfile) {
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .frame(maxWidth: .infinity)
                    .frame(height: 55)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue.opacity(0.7), Color.blue]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                    .shadow(color: Color.blue.opacity(0.3), radius: 5, x: 0, y: 3)
            } else {
                Text("Save Changes")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 55)
                    .background(
                        formIsValid ?
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue.opacity(0.7), Color.blue]),
                            startPoint: .leading,
                            endPoint: .trailing
                        ) :
                        LinearGradient(
                            gradient: Gradient(colors: [Color.gray.opacity(0.7), Color.gray]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                    .shadow(color: formIsValid ? Color.blue.opacity(0.3) : Color.clear, radius: 5, x: 0, y: 3)
            }
        }
        .disabled(!formIsValid || isLoading)
    }
    
    // MARK: - Helper Views
    
    private func formCard<Content: View>(title: String, systemImage: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 15) {
            // Card title with icon
            HStack {
                Image(systemName: systemImage)
                    .font(.system(size: 18))
                    .foregroundColor(primaryColor)
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(textColor)
            }
            
            content()
        }
        .padding(16)
        .background(cardBackground)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
    
    private func formField(title: String, systemImage: String, placeholder: String, text: Binding<String>, keyboardType: UIKeyboardType, required: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Label
            HStack {
                Image(systemName: systemImage)
                    .font(.system(size: 15))
                    .foregroundColor(primaryColor)
                
                Text(title)
                    .font(.headline)
                    .foregroundColor(textColor)
                
                if required && text.wrappedValue.isEmpty {
                    Text("*")
                        .foregroundColor(.red)
                        .fontWeight(.bold)
                }
            }
            
            // Text field
            TextField(placeholder, text: text)
                .padding(12)
                .background(inputBackground)
                .cornerRadius(10)
                .keyboardType(keyboardType)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(text.wrappedValue.isEmpty && required ? Color.red.opacity(0.3) : Color.clear, lineWidth: 1)
                )
        }
    }
    
    // MARK: - Form validation
    
    var weightIsValid: Bool {
        guard !weight.isEmpty else { return true }
        guard let weightValue = Double(weight) else { return false }
        return weightValue > 0 && weightValue < (selectedWeightUnit == .kg ? 300 : 660)
    }
    
    var heightIsValid: Bool {
        guard !height.isEmpty else { return true }
        guard let heightValue = Double(height) else { return false }
        return heightValue > 0 && heightValue < (selectedHeightUnit == .cm ? 300 : 96)
    }
    
    var formIsValid: Bool {
        !name.isEmpty && weightIsValid && heightIsValid // removed email validation since it's non-editable
    }
    
    // MARK: - Logic Functions
    
    private func saveProfile() {
        isLoading = true
        
        // Validate fields
        if name.isEmpty {
            alertMessage = "Please enter your name"
            showingAlert = true
            isLoading = false
            return
        }
        
        // Parse and convert numeric values
        var weightInKg: Double? = nil
        var heightInCm: Double? = nil
        
        if let weightValue = Double(weight), weightValue > 0 {
            // Convert to kg if necessary
            weightInKg = selectedWeightUnit == .kg ? weightValue : weightValue * 0.453592
        }
        
        if let heightValue = Double(height), heightValue > 0 {
            // Convert to cm if necessary
            heightInCm = selectedHeightUnit == .cm ? heightValue : heightValue * 2.54
        }
        
        // Update current user object directly
        user.name = name
        // email is not updated since it's non-editable
        user.weight = weightInKg
        user.height = heightInCm
        user.fitnessGoal = fitnessGoal.isEmpty ? nil : fitnessGoal
        
        // If a new image is selected, upload it
        if let profileImage = profileImage {
            print("Starting profile image upload for user: \(user.id)")
            
            ProfileImageService.shared.uploadProfileImage(profileImage, userId: user.id) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let url):
                        print("Successfully uploaded image with URL: \(url)")
                        self.user.profileImageURL = url
                        self.uploadedImageURL = url
                        self.finishSaving()
                    case .failure(let error):
                        print("Error uploading profile image: \(error.localizedDescription)")
                        self.alertMessage = "Profile updated but image upload failed: \(error.localizedDescription)"
                        self.showingAlert = true
                        self.finishSaving()
                    }
                }
            }
        } else {
            print("No new profile image selected, saving other changes")
            finishSaving()
        }
    }
    
    private func finishSaving() {
        // Update user in ViewModel
        authViewModel.updateUser(user)
        
        // Always notify image manager about update to ensure UI refreshes
        ProfileImageManager.shared.notifyImageUpdated()
        
        // If we uploaded a new image, clear all caches to ensure fresh loading
        if profileImage != nil || uploadedImageURL != nil {
            // Clear all image caches
            ProfileImageService.shared.clearCache()
            
            // Store the image in the manager cache for immediate use
            if let profileImage = profileImage, let url = user.profileImageURL {
                ProfileImageManager.shared.cacheImage(profileImage, for: url)
            }
        }
        
        // Set loading to false
        isLoading = false
        
        // Dismiss the view
        presentationMode.wrappedValue.dismiss()
    }
    
    // Helper function to hide keyboard
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// Keep original ImagePicker implementation
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.presentationMode) private var presentationMode
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .photoLibrary
        imagePicker.delegate = context.coordinator
        return imagePicker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
        // Nothing to update
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}
