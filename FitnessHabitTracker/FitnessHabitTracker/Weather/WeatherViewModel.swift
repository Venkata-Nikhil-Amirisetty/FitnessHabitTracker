//
//  WeatherViewModel.swift
//  FitnessHabitTracker
//
//  Created by Nikhil Av on 4/20/25.
//

import SwiftUI
import Combine
import CoreLocation

class WeatherViewModel: ObservableObject {
    @Published var currentWeather: WeatherData?
    @Published var forecast: [ForecastItem] = []
    @Published var isLoading = true  // Start with loading state
    @Published var errorMessage: String?
    @Published var currentConditions: [WeatherCondition] = []
    @Published var locationName: String = "Loading location..."
    @Published var lastUpdated: Date?
    
    private var cancellables = Set<AnyCancellable>()
    private var refreshTimer: Timer?
    private var locationReceived = false
    private var refreshTask: DispatchWorkItem?
    
    init() {
        // Observe location changes with better handling
        LocationManager.shared.$location
            .sink { [weak self] location in
                guard let self = self else { return }
                if let location = location {
                    self.locationReceived = true
                    self.fetchWeather(for: location)
                    self.fetchForecast(for: location)
                }
            }
            .store(in: &cancellables)
        
        // Add observer for lastKnownLocation as a fallback
        LocationManager.shared.$lastKnownLocation
            .sink { [weak self] location in
                guard let self = self, self.currentWeather == nil, let location = location else { return }
                if !self.locationReceived {
                    self.fetchWeather(for: location)
                    self.fetchForecast(for: location)
                }
            }
            .store(in: &cancellables)
        
        // Add a timeout for first load
        scheduleRefreshTimeout()
        
        // Observe location name changes
        Publishers.CombineLatest(
            LocationManager.shared.$city,
            LocationManager.shared.$country
        )
        .sink { [weak self] city, country in
            if !city.isEmpty {
                self?.locationName = city
                if !country.isEmpty {
                    self?.locationName += ", \(country)"
                }
            }
        }
        .store(in: &cancellables)
        
        // Setup timer for regular weather updates
        setupRefreshTimer()
        
        // Request location when view model initializes
        DispatchQueue.main.async {
            LocationManager.shared.requestLocation()
        }
    }
    
    deinit {
        cancellables.removeAll()
        refreshTimer?.invalidate()
        refreshTask?.cancel()
    }
    
    private func setupRefreshTimer() {
        // Refresh weather every 15 minutes
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 900, repeats: true) { [weak self] _ in
            self?.refreshWeather()
        }
    }
    
    private func scheduleRefreshTimeout() {
        // If no weather data after 5 seconds, try with last known location
        let task = DispatchWorkItem { [weak self] in
            guard let self = self, self.currentWeather == nil else { return }
            
            if let lastLocation = LocationManager.shared.lastKnownLocation {
                self.fetchWeather(for: lastLocation)
                self.fetchForecast(for: lastLocation)
            } else {
                // Force a new location request if no data available
                DispatchQueue.main.async {
                    LocationManager.shared.startUpdatingLocation()
                }
                
                // Set an error message after 5 seconds if still nothing
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
                    if self?.currentWeather == nil {
                        self?.isLoading = false
                        self?.errorMessage = "Unable to get location. Please check your location settings."
                    }
                }
            }
        }
        
        refreshTask = task
        DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: task)
    }
    
    func refreshWeather() {
        // Set loading state and clear previous error
        isLoading = true
        errorMessage = nil
        
        // Cancel any pending timeout
        refreshTask?.cancel()
        
        // Try with current location first
        if let location = LocationManager.shared.location {
            fetchWeather(for: location)
            fetchForecast(for: location)
        } else if let lastLocation = LocationManager.shared.lastKnownLocation {
            // Use last known location as a fallback
            fetchWeather(for: lastLocation)
            fetchForecast(for: lastLocation)
        } else {
            // If no location available, request it again
            DispatchQueue.main.async {
                LocationManager.shared.requestLocation()
            }
            
            // Schedule a new timeout
            scheduleRefreshTimeout()
        }
    }
    
    func fetchWeather(for location: CLLocation) {
        WeatherService.shared.getWeatherData(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude
        ) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isLoading = false
                
                switch result {
                case .success(let weatherData):
                    self.currentWeather = weatherData
                    self.getCurrentWeatherConditions(from: weatherData)
                    self.lastUpdated = Date()
                    self.errorMessage = nil  // Clear any previous errors
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                    print("Weather fetch error: \(error.localizedDescription)")
                    
                    // If this is the first attempt and we have a last known location, try it
                    if self.currentWeather == nil,
                       let lastLocation = LocationManager.shared.lastKnownLocation,
                       lastLocation.coordinate.latitude != location.coordinate.latitude ||
                       lastLocation.coordinate.longitude != location.coordinate.longitude {
                        self.fetchWeather(for: lastLocation)
                    }
                }
            }
        }
    }
    
    func fetchForecast(for location: CLLocation) {
        WeatherService.shared.getForecastData(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude
        ) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let forecastData):
                    // Filter forecast to show one entry per day
                    let filteredForecast = self?.filterDailyForecast(from: forecastData.list) ?? []
                    self?.forecast = filteredForecast
                case .failure(let error):
                    print("Forecast fetch error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func filterDailyForecast(from forecastItems: [ForecastItem]) -> [ForecastItem] {
        let calendar = Calendar.current
        var uniqueDays: [Date: ForecastItem] = [:]
        
        // Group forecasts by day, taking the noon forecast for each day
        for item in forecastItems {
            let dateComponents = calendar.dateComponents([.year, .month, .day], from: item.date)
            guard let date = calendar.date(from: dateComponents) else { continue }
            
            if uniqueDays[date] == nil {
                uniqueDays[date] = item
            } else {
                // Try to get the forecast closest to noon
                let hour = calendar.component(.hour, from: item.date)
                let currentHour = calendar.component(.hour, from: uniqueDays[date]!.date)
                
                if abs(hour - 12) < abs(currentHour - 12) {
                    uniqueDays[date] = item
                }
            }
        }
        
        // Sort the forecasts by date
        return uniqueDays.values.sorted { $0.date < $1.date }
    }
    
    private func getCurrentWeatherConditions(from weatherData: WeatherData) {
        var conditions: [WeatherCondition] = []
        
        // Extract weather conditions from weather data
        if let mainCondition = weatherData.weather.first?.main.lowercased() {
            if mainCondition.contains("clear") {
                conditions.append(.clear)
                conditions.append(.sunny)
            } else if mainCondition.contains("cloud") {
                if mainCondition.contains("scattered") || mainCondition.contains("few") {
                    conditions.append(.partlyCloudy)
                } else {
                    conditions.append(.cloudy)
                }
            } else if mainCondition.contains("rain") || mainCondition.contains("drizzle") {
                conditions.append(.rainy)
            } else if mainCondition.contains("snow") {
                conditions.append(.snowy)
            } else if mainCondition.contains("fog") || mainCondition.contains("mist") {
                conditions.append(.fog)
            }
        }
        
        // Add temperature conditions
        if weatherData.main.isHot {
            conditions.append(.hot)
        } else if weatherData.main.isCold {
            conditions.append(.cold)
        }
        
        // Add wind condition
        if weatherData.wind.isWindy {
            conditions.append(.windy)
        }
        
        self.currentConditions = conditions
    }
    
    // MARK: - Helper Methods for Habit Recommendations
    
    func shouldMoveWorkoutIndoors() -> Bool {
        guard let weather = currentWeather?.weather.first else { return false }
        return weather.isRainy || weather.isSnowy || currentWeather?.main.isHot == true
    }
    
    func getRecommendedTime() -> String {
        guard let weather = currentWeather else { return "" }
        
        let temp = weather.main.temp
        
        if temp > 28 {
            // For hot weather, recommend early morning or evening
            let isEvening = Calendar.current.component(.hour, from: Date()) >= 17
            return isEvening ? "early morning" : "evening"
        } else if weather.weather.first?.isRainy == true {
            // For rainy weather, check the forecast for a dry period
            if let dryPeriod = findDryPeriod() {
                let formatter = DateFormatter()
                formatter.dateFormat = "h a"
                return "around \(formatter.string(from: dryPeriod))"
            } else {
                return "indoors today"
            }
        }
        
        return "anytime today"
    }
    
    private func findDryPeriod() -> Date? {
        let now = Date()
        
        for item in forecast {
            if item.date > now && !(item.weather.first?.isRainy ?? false) {
                return item.date
            }
        }
        
        return nil
    }
    
    // Get weather icon based on current conditions
    func getCurrentWeatherIcon() -> String {
        if currentConditions.contains(.rainy) {
            return "cloud.rain"
        } else if currentConditions.contains(.snowy) {
            return "cloud.snow"
        } else if currentConditions.contains(.sunny) || currentConditions.contains(.clear) {
            return "sun.max"
        } else if currentConditions.contains(.cloudy) {
            return "cloud"
        } else if currentConditions.contains(.partlyCloudy) {
            return "cloud.sun"
        } else if currentConditions.contains(.fog) {
            return "cloud.fog"
        } else if currentConditions.contains(.windy) {
            return "wind"
        } else {
            return "thermometer.medium"
        }
    }
    
    // Get color based on current conditions
    func getCurrentWeatherColor() -> Color {
        if currentConditions.contains(.rainy) {
            return .blue
        } else if currentConditions.contains(.snowy) {
            return .cyan
        } else if currentConditions.contains(.hot) {
            return .orange
        } else if currentConditions.contains(.cold) {
            return .indigo
        } else if currentConditions.contains(.sunny) || currentConditions.contains(.clear) {
            return .yellow
        } else if currentConditions.contains(.cloudy) || currentConditions.contains(.partlyCloudy) {
            return .gray
        } else {
            return .purple
        }
    }
}
