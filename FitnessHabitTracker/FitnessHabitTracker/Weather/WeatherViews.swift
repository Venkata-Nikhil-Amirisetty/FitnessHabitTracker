//
//  WeatherViews.swift
//  FitnessHabitTracker
//
//  Created by Nikhil Av on 4/20/25.
//

import SwiftUI

struct WeatherDisplayView: View {
    @ObservedObject var weatherViewModel: WeatherViewModel
    
    var body: some View {
        Group {
            if weatherViewModel.isLoading {
                ProgressView()
                    .frame(height: 80)
            } else if let weather = weatherViewModel.currentWeather {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        if let iconURLString = weather.weather.first?.iconURL {
                            AsyncImage(url: iconURLString) { phase in
                                switch phase {
                                case .empty:
                                    ProgressView()
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                case .failure:
                                    Image(systemName: weather.weather.first?.systemIconName ?? "cloud")
                                        .foregroundColor(.blue)
                                @unknown default:
                                    EmptyView()
                                }
                            }
                            .frame(width: 50, height: 50)
                        } else {
                            Image(systemName: weather.weather.first?.systemIconName ?? "cloud")
                                .font(.title)
                                .foregroundColor(.blue)
                                .frame(width: 50, height: 50)
                        }
                        
                        VStack(alignment: .leading) {
                            // Use viewModel's locationName which defaults to Boston
                            Text(weatherViewModel.locationName)
                                .font(.headline)
                            
                            Text(weather.weather.first?.description.capitalized ?? "")
                                .font(.subheadline)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                            Text("\(Int(weather.main.temp))°C")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            if let lastUpdated = weatherViewModel.lastUpdated {
                                Text(formatLastUpdated(lastUpdated))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Button(action: {
                                weatherViewModel.refreshWeather()
                            }) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    
                    // Weather details
                    HStack(spacing: 20) {
                        WeatherDetailItem(
                            icon: "humidity",
                            value: "\(weather.main.humidity)%",
                            label: "Humidity"
                        )
                        
                        WeatherDetailItem(
                            icon: "wind",
                            value: "\(Int(weather.wind.speed * 3.6)) km/h",
                            label: "Wind"
                        )
                        
                        WeatherDetailItem(
                            icon: "thermometer",
                            value: "\(Int(weather.main.feelsLike))°C",
                            label: "Feels like"
                        )
                    }
                    
                    if !weatherViewModel.forecast.isEmpty {
                        Divider()
                            .padding(.vertical, 4)
                        
                        Text("Forecast")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(weatherViewModel.forecast) { item in
                                    ForecastItemView(forecastItem: item)
                                }
                            }
                        }
                    }
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(15)
                .padding(.horizontal)
            } else if let error = weatherViewModel.errorMessage {
                VStack(spacing: 10) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.orange)
                    
                    Text("Weather data unavailable")
                        .font(.headline)
                    
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button(action: {
                        weatherViewModel.refreshWeather()
                    }) {
                        Text("Retry")
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(Color.blue)
                            .cornerRadius(8)
                    }
                    .padding(.top, 8)
                }
                .padding()
            } else {
                VStack(spacing: 10) {
                    ProgressView()
                    Text("Loading weather data...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
            }
        }
    }
    
    private func formatLastUpdated(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return "Updated \(formatter.localizedString(for: date, relativeTo: Date()))"
    }
}



struct ForecastItemView: View {
    var forecastItem: ForecastItem
    
    var body: some View {
        VStack(spacing: 8) {
            Text(forecastItem.dayOfWeek)
                .font(.caption)
                .foregroundColor(.secondary)
            
            if let iconURL = forecastItem.weather.first?.iconURL {
                AsyncImage(url: iconURL) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(width: 40, height: 40)
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 40, height: 40)
                    case .failure:
                        Image(systemName: forecastItem.weather.first?.systemIconName ?? "cloud")
                            .frame(width: 40, height: 40)
                    @unknown default:
                        EmptyView()
                    }
                }
            } else {
                Image(systemName: forecastItem.weather.first?.systemIconName ?? "cloud")
                    .font(.title3)
                    .foregroundColor(.blue)
                    .frame(width: 40, height: 40)
            }
            
            Text("\(Int(forecastItem.main.temp))°")
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .frame(width: 60)
        .padding(8)
        .background(Color.blue.opacity(0.05))
        .cornerRadius(8)
    }
}

struct WeatherHabitRow: View {
    var habit: Habit
    @ObservedObject var weatherViewModel: WeatherViewModel
    
    var body: some View {
        HStack {
            Image(systemName: habit.category.icon)
                .foregroundColor(.white)
                .padding(8)
                .background(getRowColor())
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(habit.name)
                    .font(.headline)
                
                if habit.isWeatherSensitive {
                    if let weather = weatherViewModel.currentWeather {
                        if habit.isWeatherSuitable(weatherData: weather) {
                            Text("Weather is good for this habit")
                                .font(.caption)
                                .foregroundColor(.green)
                        } else {
                            if let alternative = habit.indoorAlternative, !alternative.isEmpty {
                                Text("Try instead: \(alternative)")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            } else {
                                Text("Weather may affect this habit")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                        }
                    } else {
                        Text("Weather-sensitive habit")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            if habit.isWeatherSensitive {
                Image(systemName: "cloud.sun")
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
    
    private func getRowColor() -> Color {
        guard habit.isWeatherSensitive, let weather = weatherViewModel.currentWeather else {
            return Color(habit.category.rawValue)
        }
        
        return habit.isWeatherSuitable(weatherData: weather) ? .green : .orange
    }
}

struct WeatherRecommendationView: View {
    var habit: Habit
    @ObservedObject var weatherViewModel: WeatherViewModel
    
    var body: some View {
        if habit.isWeatherSensitive, let weather = weatherViewModel.currentWeather {
            VStack(alignment: .leading, spacing: 8) {
                Text("Weather Impact")
                    .font(.headline)
                
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: getWeatherIcon())
                        .font(.title2)
                        .foregroundColor(getWeatherColor())
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(getWeatherRecommendation())
                            .font(.subheadline)
                        
                        if !habit.isWeatherSuitable(weatherData: weatherViewModel.currentWeather) && habit.indoorAlternative != nil {
                            Text("Alternative: \(habit.indoorAlternative!)")
                                .font(.callout)
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                // Optimal time recommendation
                Text("Best time: \(weatherViewModel.getRecommendedTime())")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
        }
    }
    
    private func getWeatherIcon() -> String {
        return weatherViewModel.getCurrentWeatherIcon()
    }
    
    private func getWeatherColor() -> Color {
        return weatherViewModel.getCurrentWeatherColor()
    }
    
    private func getWeatherRecommendation() -> String {
        if !habit.isWeatherSuitable(weatherData: weatherViewModel.currentWeather) {
            return "Current weather conditions aren't ideal for this habit."
        } else {
            return "Weather conditions are good for this habit!"
        }
    }
}

struct WeatherDetailView: View {
    @ObservedObject var weatherViewModel: WeatherViewModel
    @EnvironmentObject var habitViewModel: HabitViewModel
    @Environment(\.presentationMode) var presentationMode
    
    // Add this state variable for the sheet
    @State private var showingAddHabit = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Full Weather Display - Uses the updated WeatherDisplayView
                // that now properly shows weatherViewModel.locationName
                WeatherDisplayView(weatherViewModel: weatherViewModel)
                    .padding(.top)
                
                // Divider with title
                HStack {
                    VStack {
                        Divider()
                    }
                    
                    Text("Weather-Impacted Habits")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    VStack {
                        Divider()
                    }
                }
                .padding(.horizontal)
                
                // Weather-impacted habits section
                VStack(spacing: 16) {
                    if habitViewModel.weatherSensitiveHabits.isEmpty {
                        Text("You don't have any weather-sensitive habits yet.")
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding()
                        
                        // Update this button to show the habit form
                        Button(action: {
                            showingAddHabit = true
                        }) {
                            Text("Add a Weather-Sensitive Habit")
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(10)
                        }
                        .padding(.horizontal)
                    } else {
                        ForEach(habitViewModel.weatherSensitiveHabits) { habit in
                            NavigationLink(destination: HabitDetailView(habit: habit)) {
                                WeatherHabitRow(habit: habit, weatherViewModel: weatherViewModel)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .padding(.horizontal)
                        }
                    }
                }
                
                // Weather recommendations
                VStack(alignment: .leading, spacing: 12) {
                    Text("Weather Tips")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    if habitViewModel.getWeatherRecommendations().isEmpty {
                        Text("No specific weather recommendations today.")
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    } else {
                        ForEach(habitViewModel.getWeatherRecommendations(), id: \.self) { recommendation in
                            HStack {
                                Image(systemName: "cloud.sun")
                                    .foregroundColor(.blue)
                                
                                Text(recommendation)
                                    .font(.subheadline)
                            }
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(10)
                            .padding(.horizontal)
                        }
                    }
                }
                
                // Forecast section
                if !weatherViewModel.forecast.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("5-Day Forecast")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(weatherViewModel.forecast) { item in
                                    VStack(spacing: 8) {
                                        Text(item.dayOfWeek)
                                            .font(.callout)
                                            .fontWeight(.medium)
                                        
                                        if let iconURL = item.weather.first?.iconURL {
                                            AsyncImage(url: iconURL) { phase in
                                                switch phase {
                                                case .empty:
                                                    ProgressView()
                                                case .success(let image):
                                                    image
                                                        .resizable()
                                                        .aspectRatio(contentMode: .fit)
                                                        .frame(width: 50, height: 50)
                                                case .failure:
                                                    Image(systemName: item.weather.first?.systemIconName ?? "cloud")
                                                        .font(.title)
                                                        .foregroundColor(.blue)
                                                @unknown default:
                                                    EmptyView()
                                                }
                                            }
                                            .frame(width: 50, height: 50)
                                        }
                                        
                                        Text("\(Int(item.main.temp))°C")
                                            .font(.title3)
                                            .fontWeight(.bold)
                                        
                                        Text(item.weather.first?.description.capitalized ?? "")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .multilineTextAlignment(.center)
                                            .lineLimit(2)
                                            .frame(width: 80)
                                    }
                                    .padding()
                                    .background(Color.blue.opacity(0.05))
                                    .cornerRadius(10)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                }
            }
        }
        .navigationTitle("Weather & Habits")
        .navigationBarItems(trailing: Button(action: {
            weatherViewModel.refreshWeather()
        }) {
            Image(systemName: "arrow.clockwise")
        })
        .onAppear {
            // Request location when view appears
            LocationManager.shared.requestLocation()
        }
        // Add this sheet modifier to show the habit form
        .sheet(isPresented: $showingAddHabit) {
            NavigationView {
                HabitFormView(isPresented: $showingAddHabit, isWeatherSensitive: true)
                    .environmentObject(habitViewModel)
            }
        }
    }
}

struct WeatherPreferencesView: View {
    var habit: Habit
    @Binding var isPresented: Bool
    @EnvironmentObject var habitViewModel: HabitViewModel
    
    @State private var isWeatherSensitive: Bool
    @State private var selectedWeatherConditions: Set<WeatherCondition> = []
    @State private var indoorAlternative: String
    
    // Initialize state from habit
    init(habit: Habit, isPresented: Binding<Bool>) {
        self.habit = habit
        self._isPresented = isPresented
        
        // Load from habit
        self._isWeatherSensitive = State(initialValue: habit.isWeatherSensitive)
        self._indoorAlternative = State(initialValue: habit.indoorAlternative ?? "")
        
        // Convert string array to WeatherCondition set
        var conditionSet: Set<WeatherCondition> = []
        for conditionString in habit.preferredWeatherConditions {
            if let condition = WeatherCondition.allCases.first(where: { $0.rawValue == conditionString }) {
                conditionSet.insert(condition)
            }
        }
        self._selectedWeatherConditions = State(initialValue: conditionSet)
    }
    
    var body: some View {
        Form {
            Section {
                Toggle("Weather Sensitive Habit", isOn: $isWeatherSensitive.animation())
                
                if isWeatherSensitive {
                    // Current weather preview
                    if let weather = habitViewModel.weatherViewModel.currentWeather {
                        WeatherPreviewView(
                            weather: weather,
                            selectedConditions: selectedWeatherConditions
                        )
                    }
                }
            }
            
            if isWeatherSensitive {
                Section(header: Text("Preferred Weather Conditions")) {
                    ForEach(WeatherCondition.allCases) { condition in
                        Button(action: {
                            if selectedWeatherConditions.contains(condition) {
                                selectedWeatherConditions.remove(condition)
                            } else {
                                selectedWeatherConditions.insert(condition)
                            }
                        }) {
                            HStack {
                                Image(systemName: condition.systemIconName)
                                    .foregroundColor(condition.color)
                                
                                Text(condition.rawValue)
                                
                                Spacer()
                                
                                if selectedWeatherConditions.contains(condition) {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        .foregroundColor(.primary)
                    }
                }
                
                Section(header: Text("Indoor Alternative")) {
                    Text("What to do when weather isn't suitable")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    TextEditor(text: $indoorAlternative)
                        .frame(minHeight: 100)
                }
                
                Section(footer: Text("The app will notify you when weather conditions aren't suitable for this habit.")) {
                    Text("Your preferences will be saved automatically when you tap Save.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Section {
                Button(action: saveWeatherPreferences) {
                    Text("Save Preferences")
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .foregroundColor(.blue)
                }
            }
        }
    }
    
    private func saveWeatherPreferences() {
        // Save the weather preferences to the habit
        habit.isWeatherSensitive = isWeatherSensitive
        habit.preferredWeatherConditions = selectedWeatherConditions.map { $0.rawValue }
        habit.indoorAlternative = indoorAlternative.isEmpty ? nil : indoorAlternative
        
        // Update habit via view model
        habitViewModel.updateHabitWithWeatherPreferences(
            habit: habit,
            isWeatherSensitive: isWeatherSensitive,
            preferredWeatherConditions: selectedWeatherConditions.map { $0.rawValue },
            indoorAlternative: indoorAlternative.isEmpty ? nil : indoorAlternative
        )
        
        // Dismiss the sheet
        isPresented = false
    }
}

struct WeatherPreviewView: View {
    var weather: WeatherData
    var selectedConditions: Set<WeatherCondition>
    
    var isWeatherSuitable: Bool {
        let currentConditions = WeatherCondition.allCases.filter { condition in
            switch condition {
            case .sunny, .clear:
                return weather.weather.first?.isClear ?? false
            case .cloudy:
                return weather.weather.first?.isCloudy ?? false
            case .partlyCloudy:
                return (weather.weather.first?.isCloudy ?? false) && weather.weather.first?.id != 804
            case .rainy:
                return weather.weather.first?.isRainy ?? false
            case .snowy:
                return weather.weather.first?.isSnowy ?? false
            case .windy:
                return weather.wind.isWindy
            case .fog:
                return (weather.weather.first?.id ?? 0) >= 700 && (weather.weather.first?.id ?? 0) < 800
            case .hot:
                return weather.main.isHot
            case .cold:
                return weather.main.isCold
            case .any:
                return true
            }
        }
        
        if selectedConditions.isEmpty {
            return true
        }
        
        // Check for "Any" condition
        if selectedConditions.contains(.any) {
            return true
        }
        
        // Check if any of the selected conditions match current conditions
        return !selectedConditions.isDisjoint(with: Set(currentConditions))
    }
    
    var body: some View {
        HStack {
            if isWeatherSuitable {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.title3)
                
                VStack(alignment: .leading) {
                    Text("Current weather is suitable!")
                        .font(.subheadline)
                        .foregroundColor(.green)
                    
                    Text("\(Int(weather.main.temp))°C, \(weather.weather.first?.description.capitalized ?? "")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                    .font(.title3)
                
                VStack(alignment: .leading) {
                    Text("Current weather isn't ideal")
                        .font(.subheadline)
                        .foregroundColor(.orange)
                    
                    Text("\(Int(weather.main.temp))°C, \(weather.weather.first?.description.capitalized ?? "")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}
