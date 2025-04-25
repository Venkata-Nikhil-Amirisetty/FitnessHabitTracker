//
//  SettingsView.swift
//  FitnessHabitTracker
//
//  Updated with FAQs View and notification functionality moved to ProfileView
//  Fixed to apply dark mode changes immediately

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

// MARK: - File Picker Delegate
class FilePickerDelegate: NSObject, UIDocumentPickerDelegate {
    static let shared = FilePickerDelegate()
    
    var onPick: (([URL]) -> Void)?
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        onPick?(urls)
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        // Handle cancellation
    }
}

// MARK: - SettingsView
struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) var colorScheme // For dark mode detection
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var workoutViewModel: WorkoutViewModel
    @EnvironmentObject var habitViewModel: HabitViewModel
    
    // MARK: App settings
    @AppStorage("darkModeEnabled") private var darkModeEnabled = false
    @AppStorage("appTheme") private var selectedThemeIndex = 0
    
    // MARK: Export/Import state
    @State private var showingExportOptions = false
    @State private var showingFileImporter = false
    @State private var isExporting = false
    @State private var isImporting = false
    @State private var importFileFormat: ExportFormat = .json
    @State private var exportErrorMessage = ""
    @State private var showingExportError = false
    @State private var importErrorMessage = ""
    @State private var showingImportError = false
    @State private var importSuccessMessage = ""
    @State private var showingImportSuccess = false
    
    // Force view updates
    @State private var viewUpdateCounter = 0
    
    var themeOptions = ["System Default", "Light", "Dark"]
    
    var body: some View {
        ZStack {
            // This empty Text with an ID forces the view to update when viewUpdateCounter changes
            Text("").id(viewUpdateCounter)
            
            Form {
                Section(header: Text("APPEARANCE")) {
                    Picker("App Theme", selection: $selectedThemeIndex) {
                        ForEach(0..<themeOptions.count, id: \.self) { index in
                            Text(themeOptions[index])
                        }
                    }
                    .onChange(of: selectedThemeIndex) { newValue in
                        // Update dark mode based on theme selection
                        if newValue == 2 { // Dark theme
                            darkModeEnabled = true
                            // Force immediate refresh
                            viewUpdateCounter += 1
                        } else if newValue == 1 { // Light theme
                            darkModeEnabled = false
                            // Force immediate refresh
                            viewUpdateCounter += 1
                        } else {
                            // System default - could be implemented to check system setting
                            // For now, we'll just leave the current dark mode setting
                        }
                    }
                    
                    Toggle("Dark Mode", isOn: $darkModeEnabled)
                        .onChange(of: darkModeEnabled) { newValue in
                            // Update theme selection when dark mode changes
                            if newValue && selectedThemeIndex != 2 {
                                selectedThemeIndex = 2 // Dark
                            } else if !newValue && selectedThemeIndex == 2 {
                                selectedThemeIndex = 1 // Light
                            }
                            
                            // Force immediate refresh
                            viewUpdateCounter += 1
                        }
                }
                
                // In the SettingsView body, add a new section for Resources:
                Section(header: Text("RESOURCES")) {
                    Link(destination: URL(string: "https://www.weatherapi.com/my/")!) {
                        HStack {
                            Image(systemName: "cloud.sun")
                                .foregroundColor(.blue)
                            Text("WeatherAPI Dashboard")
                                .foregroundColor(colorScheme == .dark ? .white : .primary)
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                    
                    Link(destination: URL(string: "https://firebase.google.com/")!) {
                        HStack {
                            Image(systemName: "flame")
                                .foregroundColor(.orange)
                            Text("Firebase Console")
                                .foregroundColor(colorScheme == .dark ? .white : .primary)
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                }
                
//#if DEBUG
//                // Demo data section in debug mode
//                Section(header: Text("DEVELOPMENT")) {
//                    // Use the environment color scheme for proper appearance
//                    DemoDataButton()
//                        .padding(.vertical, 10)
//                }
//#endif
                
                Section(header: Text("DATA MANAGEMENT")) {
                    Button(action: {
                        showingExportOptions = true
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(.blue)
                            Text("Export Your Data")
                                .foregroundColor(colorScheme == .dark ? .white : .primary)
                        }
                    }
                    .disabled(isExporting || isImporting)
                    
                    Button(action: {
                        showImportOptions()
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.down")
                                .foregroundColor(.blue)
                            Text("Import Data")
                                .foregroundColor(colorScheme == .dark ? .white : .primary)
                        }
                    }
                    .disabled(isExporting || isImporting)
                }
            }
            .navigationTitle("Settings")
            .navigationBarItems(leading: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
            .actionSheet(isPresented: $showingExportOptions) {
                ActionSheet(
                    title: Text("Export Your Data"),
                    message: Text("Choose a format to export your fitness data"),
                    buttons: [
                        .default(Text("CSV Format")) {
                            exportData(format: .csv)
                        },
                        .default(Text("JSON Format")) {
                            exportData(format: .json)
                        },
                        .cancel()
                    ]
                )
            }
            .alert(isPresented: $showingExportError) {
                Alert(
                    title: Text("Export Error"),
                    message: Text(exportErrorMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            .alert(isPresented: $showingImportError) {
                Alert(
                    title: Text("Import Error"),
                    message: Text(importErrorMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            .alert(isPresented: $showingImportSuccess) {
                Alert(
                    title: Text("Success"),
                    message: Text(importSuccessMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            .sheet(isPresented: $showingFileImporter) {
                FileImporterView(format: importFileFormat, onImport: { url in
                    importData(from: url, format: importFileFormat)
                })
            }
            
            // Loading overlay
            if isExporting || isImporting {
                Color.black.opacity(0.4)
                    .edgesIgnoringSafeArea(.all)
                    .overlay(
                        VStack {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.5)
                                .padding()
                            
                            Text(getLoadingText())
                                .foregroundColor(.white)
                                .font(.headline)
                        }
                    )
            }
        }
        // This modifier allows the view to adapt to dark mode changes in real time
        .preferredColorScheme(darkModeEnabled ? .dark : .light)
    }
    
    private func getLoadingText() -> String {
        if isExporting {
            return "Exporting..."
        } else if isImporting {
            return "Importing..."
        }
        return ""
    }
    
    // MARK: - Export/Import Functions
    
    private func exportData(format: ExportFormat) {
        guard let user = authViewModel.currentUser else {
            exportErrorMessage = "No user data available to export"
            showingExportError = true
            return
        }
        
        // Show loading indicator
        withAnimation {
            isExporting = true
        }
        
        // Use background thread for file operations
        DispatchQueue.global(qos: .userInitiated).async {
            // Pass the workouts and habits to the export function
            if let fileURL = FileService.shared.exportUserData(
                user,
                workouts: workoutViewModel.workouts,
                habits: habitViewModel.habits,
                format: format
            ) {
                // Return to main thread to share file
                DispatchQueue.main.async {
                    // Hide loading indicator
                    withAnimation {
                        isExporting = false
                    }
                    
                    // Share the file
                    FileService.shared.shareFile(at: fileURL)
                }
            } else {
                // Return to main thread for error handling
                DispatchQueue.main.async {
                    // Hide loading indicator
                    withAnimation {
                        isExporting = false
                    }
                    
                    exportErrorMessage = "Failed to export data. Please try again."
                    showingExportError = true
                }
            }
        }
    }
    
    // MARK: - Import Functions
    
    private func showImportOptions() {
        let alert = UIAlertController(title: "Import Data", message: "Choose the format of the file you want to import", preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "CSV", style: .default) { _ in
            importFileFormat = .csv
            showingFileImporter = true
        })
        
        alert.addAction(UIAlertAction(title: "JSON", style: .default) { _ in
            importFileFormat = .json
            showingFileImporter = true
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        // Find top view controller to present the alert
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            var currentVC = rootVC
            while let presented = currentVC.presentedViewController {
                currentVC = presented
            }
            currentVC.present(alert, animated: true)
        }
    }
    
    private func importData(from url: URL, format: ExportFormat) {
        guard let currentUser = authViewModel.currentUser else {
            importErrorMessage = "No user account found"
            showingImportError = true
            return
        }
        
        // Show loading indicator
        withAnimation {
            isImporting = true
        }
        
        // Add debug log to console
        print("Starting import process from: \(url.absoluteString)")
        print("File format: \(format == .csv ? "CSV" : "JSON")")
        
        // Perform import in background
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                // Read file content for debugging
                let fileContent = try String(contentsOf: url, encoding: .utf8)
                print("File content preview (first 200 chars): \(String(fileContent.prefix(200)))")
                
                // Proceed with import
                let success = FileService.shared.importUserData(from: url, format: format, currentUser: currentUser)
                
                // Return to main thread
                DispatchQueue.main.async {
                    // Hide loading indicator
                    withAnimation {
                        isImporting = false
                        showingFileImporter = false
                    }
                    
                    if success {
                        // Save changes via the view model
                        authViewModel.updateUser(currentUser)
                        importSuccessMessage = "Data imported successfully!"
                        showingImportSuccess = true
                        
                        // Force UI refresh for workouts and habits
                        workoutViewModel.loadWorkouts()
                        habitViewModel.loadHabits()
                        
                        print("Import completed successfully - UI refresh triggered")
                    } else {
                        importErrorMessage = "Failed to import data. The file format may be incorrect."
                        showingImportError = true
                        print("Import failed - file format issue suspected")
                    }
                }
            } catch {
                // Handle file read errors
                print("Error reading file: \(error.localizedDescription)")
                
                DispatchQueue.main.async {
                    withAnimation {
                        isImporting = false
                        showingFileImporter = false
                    }
                    importErrorMessage = "Failed to read import file: \(error.localizedDescription)"
                    showingImportError = true
                }
            }
        }
    }
}

// MARK: - FAQ View
struct FAQView: View {
    // State for tracking which FAQs are expanded
    @State private var expandedFAQs: Set<Int> = []
    @Environment(\.colorScheme) var colorScheme
    
    // List of FAQs
    private let faqs: [(question: String, answer: String)] = [
        (
            "How do I add a new workout?",
            "To add a new workout, go to the Workouts tab and tap the '+' button in the top right corner. Fill in the workout details like name, type, duration, and calories burned, then tap 'Save Workout'."
        ),
        (
            "How do I track my habit streaks?",
            "Habit streaks are automatically tracked when you mark a habit as completed. You can view your current streak on the habit detail page. The streak counter increases each day you complete the habit and resets if you miss a day."
        ),
        (
            "Can I export my data?",
            "Yes! Go to Settings > Data Management > Export Your Data. You can choose to export in CSV or JSON format. This is useful for keeping a backup of your fitness data or analyzing it in other applications."
        ),
        (
            "How do weather conditions affect my habits?",
            "For weather-sensitive habits, the app checks current weather conditions and suggests whether it's suitable for the activity. You can set preferred weather conditions for each habit in the habit settings."
        ),
        (
            "How do I set up notifications?",
            "Notifications can be configured for each habit individually. When creating or editing a habit, toggle 'Enable Reminder' and set the time you want to be reminded. You can also manage all your notifications from the Profile screen."
        ),
        (
            "How is my data stored?",
            "Your data is stored securely both on your device and in the cloud (if you're signed in). This allows you to access your fitness information across multiple devices and ensures your data isn't lost if you change or lose your device."
        ),
        (
            "How can I log out of my account?",
            "To log out of your account, navigate to the Profile tab, then tap the 'Log Out' button at the bottom of the screen. This will sign you out of the app and return you to the login screen. Your data will remain synchronized with your account for when you log back in."
        ),
        (
            "Can I connect to Apple Health or other fitness apps?",
            "Yes, the app can sync with Apple Health to import workout data and health metrics. This integration helps provide a more complete picture of your fitness activities."
        ),
        // Add this to the FAQs array:
        (
            "What third-party services does the app use?",
            "The app uses Firebase for user authentication, data synchronization, and analytics. It also uses WeatherAPI to provide weather information for weather-sensitive habits. Both services help provide a seamless and feature-rich experience while keeping your data secure."
        )
    ]
    
    var body: some View {
        List {
            ForEach(0..<faqs.count, id: \.self) { index in
                FAQItem(
                    question: faqs[index].question,
                    answer: faqs[index].answer,
                    isExpanded: expandedFAQs.contains(index),
                    onToggle: {
                        toggleFAQ(index)
                    }
                )
            }
            
        }
        .navigationTitle("FAQs")
        .listStyle(InsetGroupedListStyle())
    }
    
    private func toggleFAQ(_ index: Int) {
        if expandedFAQs.contains(index) {
            expandedFAQs.remove(index)
        } else {
            expandedFAQs.insert(index)
        }
    }
}

// MARK: - FAQ Item View
struct FAQItem: View {
    var question: String
    var answer: String
    var isExpanded: Bool
    var onToggle: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button(action: onToggle) {
                HStack {
                    Text(question)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.blue)
                }
            }
            
            if isExpanded {
                Text(answer)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .padding(.top, 5)
                    .padding(.bottom, 8)
                    .animation(.easeInOut, value: isExpanded)
                    .transition(.opacity)
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - File Importer View
struct FileImporterView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    @State private var selectedURL: URL?
    @State private var showingPasteOption = false
    @State private var pastedText = ""
    
    var format: ExportFormat
    var onImport: (URL) -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Select a \(format == .csv ? "CSV" : "JSON") File")
                .font(.headline)
                .foregroundColor(colorScheme == .dark ? .white : .primary)
                .padding(.top, 30)
            
            Image(systemName: format == .csv ? "tablecells" : "curlybraces")
                .font(.system(size: 60))
                .foregroundColor(.blue)
                .padding()
            
            Text("Choose a file to import your fitness data")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            Button(action: {
                // Show document picker for file selection
                if #available(iOS 14, *) {
                    // Handle with new iOS 14+ api if available
                    showFilePickerIOS14()
                } else {
                    // Use UIDocumentPickerViewController for earlier iOS versions
                    showDocumentPicker()
                }
            }) {
                Text("Select File")
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
                    .padding(.horizontal)
            }
            .padding(.vertical)
            
            // FOR TESTING: Add paste option
            Divider()
                .padding(.horizontal)
            
            Button(action: {
                self.showingPasteOption = true
            }) {
                Text("Paste JSON Content (For Testing)")
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(10)
                    .padding(.horizontal)
            }
            
            Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            }
            .foregroundColor(.red)
            .padding(.bottom)
            
            Spacer()
        }
        .padding()
        .background(colorScheme == .dark ? Color(UIColor.systemBackground) : Color(UIColor.systemBackground))
        .sheet(isPresented: $showingPasteOption) {
            PasteContentView(format: format, onImport: onImport)
        }
    }
    
    private func showFilePickerIOS14() {
        if #available(iOS 14.0, *) {
            let supportedTypes: [UTType] = [
                format == .csv ? UTType.commaSeparatedText : UTType.json
            ]
            
            let picker = UIDocumentPickerViewController(forOpeningContentTypes: supportedTypes)
            picker.allowsMultipleSelection = false
            picker.delegate = FilePickerDelegate.shared
            
            FilePickerDelegate.shared.onPick = { urls in
                if let url = urls.first {
                    self.selectedURL = url
                    self.onImport(url)
                }
            }
            
            // Present the file picker
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let rootVC = window.rootViewController {
                var currentVC = rootVC
                while let presented = currentVC.presentedViewController {
                    currentVC = presented
                }
                currentVC.present(picker, animated: true)
            }
        }
    }
    
    private func showDocumentPicker() {
        let documentTypes = [format == .csv ? "public.comma-separated-values-text" : "public.json"]
        let picker = UIDocumentPickerViewController(documentTypes: documentTypes, in: .import)
        picker.allowsMultipleSelection = false
        picker.delegate = FilePickerDelegate.shared
        
        FilePickerDelegate.shared.onPick = { urls in
            if let url = urls.first {
                self.selectedURL = url
                self.onImport(url)
            }
        }
        
        // Present the file picker
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            var currentVC = rootVC
            while let presented = currentVC.presentedViewController {
                currentVC = presented
            }
            currentVC.present(picker, animated: true)
        }
    }
}

// MARK: - Paste Content View for Testing
struct PasteContentView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var pastedContent = ""
    var format: ExportFormat
    var onImport: (URL) -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Paste your \(format == .csv ? "CSV" : "JSON") content here:")
                    .font(.headline)
                    .padding(.top)
                
                TextEditor(text: $pastedContent)
                    .frame(maxHeight: .infinity)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                    .padding(.horizontal)
                
                Button(action: {
                    // Save pasted content to a temporary file and import
                    if let url = savePastedContent() {
                        onImport(url)
                        presentationMode.wrappedValue.dismiss()
                    }
                }) {
                    Text("Import Pasted Content")
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                        .padding(.horizontal)
                }
                .disabled(pastedContent.isEmpty)
            }
            .padding()
            .navigationTitle("Paste Content")
            .navigationBarItems(trailing: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
    
    private func savePastedContent() -> URL? {
        // Create a temporary file with the pasted content
        do {
            let tempDir = FileManager.default.temporaryDirectory
            let fileName = "pasted_content.\(format == .csv ? "csv" : "json")"
            let fileURL = tempDir.appendingPathComponent(fileName)
            
            try pastedContent.write(to: fileURL, atomically: true, encoding: .utf8)
            print("Saved pasted content to temporary file: \(fileURL.path)")
            return fileURL
        } catch {
            print("Error saving pasted content: \(error.localizedDescription)")
            return nil
        }
    }
}

// MARK: - UTType Extension for iOS 14+
@available(iOS 14.0, *)
extension UTType {
    static var commaSeparatedText: UTType {
        UTType(importedAs: "public.comma-separated-values-text")
    }
}

// Modified preview to show both light and dark mode
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            NavigationView {
                SettingsView()
                    .environmentObject(AuthViewModel())
                    .environment(\.colorScheme, .light)
                    .previewDisplayName("Light Mode")
            }
            
            NavigationView {
                SettingsView()
                    .environmentObject(AuthViewModel())
                    .environment(\.colorScheme, .dark)
                    .previewDisplayName("Dark Mode")
            }
            
            NavigationView {
                FAQView()
                    .environment(\.colorScheme, .light)
                    .previewDisplayName("FAQs - Light Mode")
            }
            
            NavigationView {
                FAQView()
                    .environment(\.colorScheme, .dark)
                    .previewDisplayName("FAQs - Dark Mode")
            }
        }
    }
}
