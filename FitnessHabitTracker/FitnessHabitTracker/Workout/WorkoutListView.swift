//
//  WorkoutListView.swift
//  FitnessHabitTracker
//
//  Created by Nikhil Av on 4/16/25.
//  Enhanced with SwiftData features and CoreML integration

import SwiftUI
import SwiftData

struct WorkoutListView: View {
    @EnvironmentObject var workoutViewModel: WorkoutViewModel
    @State private var showingAddWorkout = false
    @State private var selectedFilter: WorkoutType? = nil
    @State private var searchText = ""
    @State private var sortOption: WorkoutSortOption = .dateDescending
    @State private var showingSortOptions = false
    @State private var isSearching = false
    
    var filteredWorkouts: [Workout] {
        var result = workoutViewModel.workouts
        
        // Apply type filter
        if let filter = selectedFilter {
            result = result.filter { $0.type == filter }
        }
        
        // Apply search if not empty
        if !searchText.isEmpty {
            result = result.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                ($0.notes?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        
        // Apply sorting
        switch sortOption {
        case .dateDescending:
            result.sort { $0.date > $1.date }
        case .dateAscending:
            result.sort { $0.date < $1.date }
        case .durationDescending:
            result.sort { $0.duration > $1.duration }
        case .durationAscending:
            result.sort { $0.duration < $1.duration }
        case .caloriesDescending:
            result.sort { $0.caloriesBurned > $1.caloriesBurned }
        case .caloriesAscending:
            result.sort { $0.caloriesBurned < $1.caloriesBurned }
        case .name:
            result.sort { $0.name < $1.name }
        }
        
        return result
    }
    
    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground)
                .ignoresSafeArea()
                
            VStack(spacing: 0) {
                // Search and Sort Bar
                HStack {
                    if isSearching {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.gray)
                            
                            TextField("Search workouts", text: $searchText)
                                .disableAutocorrection(true)
                            
                            Button(action: {
                                withAnimation(.spring()) {
                                    searchText = ""
                                    isSearching = false
                                }
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                            .opacity(searchText.isEmpty ? 0 : 1)
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(UIColor.systemBackground))
                                .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
                        )
                        
                        Spacer()
                        
                        Button(action: {
                            showingSortOptions = true
                        }) {
                            HStack {
                                Text("Sort")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Image(systemName: "arrow.up.arrow.down")
                            }
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(UIColor.systemBackground))
                                    .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
                            )
                        }
                    } else {
                        Button(action: {
                            withAnimation(.spring()) {
                                isSearching = true
                            }
                        }) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.blue)
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(UIColor.systemBackground))
                                        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
                                )
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            showingSortOptions = true
                        }) {
                            HStack {
                                Text("Sort: \(sortOption.description)")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Image(systemName: "arrow.up.arrow.down")
                            }
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(UIColor.systemBackground))
                                    .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
                            )
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 16)
                .padding(.bottom, 12)
                
                // Filter options
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        FilterButton(title: "All", isSelected: selectedFilter == nil) {
                            withAnimation {
                                selectedFilter = nil
                            }
                        }
                        
                        ForEach(WorkoutType.allCases, id: \.self) { type in
                            FilterButton(
                                title: type.rawValue.capitalized,
                                icon: type.icon,
                                isSelected: selectedFilter == type
                            ) {
                                withAnimation {
                                    selectedFilter = type
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                
                // Workout list
                if filteredWorkouts.isEmpty {
                    VStack(spacing: 24) {
                        Spacer()
                        
                        Image(systemName: "figure.walk")
                            .font(.system(size: 70))
                            .foregroundColor(.blue.opacity(0.7))
                            .padding()
                            .background(
                                Circle()
                                    .fill(Color.blue.opacity(0.1))
                                    .frame(width: 150, height: 150)
                            )
                        
                        if !searchText.isEmpty {
                            Text("No workouts match your search")
                                .font(.title3)
                                .fontWeight(.medium)
                        } else if selectedFilter != nil {
                            Text("No \(selectedFilter!.rawValue) workouts found")
                                .font(.title3)
                                .fontWeight(.medium)
                        } else {
                            Text("No workouts yet")
                                .font(.title3)
                                .fontWeight(.medium)
                        }
                        
                        Button(action: {
                            showingAddWorkout = true
                        }) {
                            HStack {
                                Image(systemName: "plus")
                                    .font(.headline)
                                Text("Add Workout")
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .padding(.vertical, 14)
                            .padding(.horizontal, 30)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color.blue)
                                    .shadow(color: Color.blue.opacity(0.3), radius: 5, x: 0, y: 3)
                            )
                        }
                        .padding(.top, 8)
                        
                        Spacer()
                    }
                    .padding()
                    .frame(maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(filteredWorkouts, id: \.id) { workout in
                                NavigationLink(destination: WorkoutDetailView(workout: workout)) {
                                    WorkoutRow(workout: workout)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            .onDelete(perform: deleteWorkout)
                        }
                        .padding(.vertical, 8)
                    }
                    .refreshable {
                        workoutViewModel.loadWorkouts()
                    }
                    
                    // Summary Footer
                    VStack(spacing: 16) {
                        Text("\(filteredWorkouts.count) workouts")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                        
                        HStack(spacing: 16) {
                            StatisticView(
                                label: "Total Duration",
                                value: formatTotalDuration(),
                                icon: "clock"
                            )
                            
                            StatisticView(
                                label: "Total Calories",
                                value: formatTotalCalories(),
                                icon: "flame"
                            )
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 16)
                    }
                    .background(
                        Rectangle()
                            .fill(Color(UIColor.systemBackground))
                            .shadow(color: Color.black.opacity(0.05), radius: 5, y: -3)
                    )
                }
            }
        }
        .navigationTitle("Workouts")
        .navigationBarItems(
            trailing: HStack(spacing: 20) {
                NavigationLink(destination: WorkoutMLAnalyticsView()) {
                    Image(systemName: "brain")
                        .font(.system(size: 20))
                        .foregroundColor(workoutViewModel.mlModelsAvailable ? .purple : .gray)
                }
                
                Button(action: {
                    showingAddWorkout = true
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.blue)
                }
            }
        )
        .sheet(isPresented: $showingAddWorkout) {
            NavigationView {
                WorkoutFormView(isPresented: $showingAddWorkout)
                    .environmentObject(workoutViewModel)
            }
        }
        .actionSheet(isPresented: $showingSortOptions) {
            ActionSheet(
                title: Text("Sort Workouts"),
                buttons: [
                    .default(Text(WorkoutSortOption.dateDescending.description)) {
                        sortOption = .dateDescending
                    },
                    .default(Text(WorkoutSortOption.dateAscending.description)) {
                        sortOption = .dateAscending
                    },
                    .default(Text(WorkoutSortOption.durationDescending.description)) {
                        sortOption = .durationDescending
                    },
                    .default(Text(WorkoutSortOption.durationAscending.description)) {
                        sortOption = .durationAscending
                    },
                    .default(Text(WorkoutSortOption.caloriesDescending.description)) {
                        sortOption = .caloriesDescending
                    },
                    .default(Text(WorkoutSortOption.caloriesAscending.description)) {
                        sortOption = .caloriesAscending
                    },
                    .default(Text(WorkoutSortOption.name.description)) {
                        sortOption = .name
                    },
                    .cancel()
                ]
            )
        }
        .alert(isPresented: $workoutViewModel.showingError) {
            Alert(
                title: Text("Error"),
                message: Text(workoutViewModel.errorMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    private func deleteWorkout(at offsets: IndexSet) {
        for index in offsets {
            let workoutToDelete = filteredWorkouts[index]
            workoutViewModel.deleteWorkout(workoutToDelete)
        }
    }
    
    private func formatTotalDuration() -> String {
        let totalMinutes = Int(filteredWorkouts.reduce(0) { $0 + $1.duration } / 60)
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    private func formatTotalCalories() -> String {
        let totalCalories = Int(filteredWorkouts.reduce(0) { $0 + $1.caloriesBurned })
        return "\(totalCalories) kcal"
    }
}

struct FilterButton: View {
    var title: String
    var icon: String? = nil
    var isSelected: Bool
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.subheadline)
                }
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 14)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? Color.blue : Color(UIColor.systemGray6))
                    .shadow(color: isSelected ? Color.blue.opacity(0.3) : Color.clear, radius: 4, x: 0, y: 2)
            )
            .foregroundColor(isSelected ? .white : .primary)
            .animation(.spring(response: 0.3), value: isSelected)
        }
    }
}

struct WorkoutRow: View {
    var workout: Workout
    @State private var appear = false
    
    var body: some View {
        VStack {
            HStack(spacing: 15) {
                Image(systemName: workout.type.icon)
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 45, height: 45)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(workout.intensity?.color ?? Color.blue)
                            .shadow(color: (workout.intensity?.color ?? Color.blue).opacity(0.3), radius: 4, x: 0, y: 2)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(workout.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    HStack {
                        Text(formatDate(workout.date))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        if let distance = workout.distance, distance > 0 {
                            Text("•")
                                .foregroundColor(.secondary)
                            Text(String(format: "%.1f km", distance))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 6) {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(Int(workout.duration / 60)) min")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                        Text("\(Int(workout.caloriesBurned)) cal")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .opacity(appear ? 1 : 0)
        .offset(y: appear ? 0 : 20)
        .onAppear {
            withAnimation(.easeOut(duration: 0.3).delay(0.1)) {
                appear = true
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

struct StatisticView: View {
    var label: String
    var value: String
    var icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(icon == "flame" ? .orange : .blue)
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(icon == "flame" ? Color.orange.opacity(0.1) : Color.blue.opacity(0.1))
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(value)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(UIColor.systemGray6))
            )
        }
    }
}

// Add missing WorkoutSortOption enum if not already defined elsewhere
enum WorkoutSortOption {
    case dateDescending
    case dateAscending
    case durationDescending
    case durationAscending
    case caloriesDescending
    case caloriesAscending
    case name
    
    var description: String {
        switch self {
        case .dateDescending:
            return "Newest First"
        case .dateAscending:
            return "Oldest First"
        case .durationDescending:
            return "Longest First"
        case .durationAscending:
            return "Shortest First"
        case .caloriesDescending:
            return "Most Calories"
        case .caloriesAscending:
            return "Least Calories"
        case .name:
            return "Name A-Z"
        }
    }
}

struct WorkoutListView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            WorkoutListView()
                .environmentObject(WorkoutViewModel())
        }
        .modelContainerPreview {
            Text("Preview with SwiftData")
        }
    }
}
