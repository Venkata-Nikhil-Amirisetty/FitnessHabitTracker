//  WeatherService.swift
//  FitnessHabitTracker
//
//  Created by Nikhil Av on 4/20/25.
//

import Foundation

class WeatherService {
    static let shared = WeatherService()
    private let apiKey = "92bd5c88d9fe4ac28cd192222252004"
    private let baseURL = "https://api.weatherapi.com/v1"
    
    private init() {}
    
    func getWeatherData(latitude: Double, longitude: Double, retryCount: Int = 0, completion: @escaping (Result<WeatherData, Error>) -> Void) {
        // WeatherAPI.com uses a different endpoint structure
        let urlString = "\(baseURL)/current.json?key=\(apiKey)&q=\(latitude),\(longitude)"
        
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "WeatherError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                if retryCount < 2 {
                    // Retry after a short delay
                    DispatchQueue.global().asyncAfter(deadline: .now() + 2) {
                        self.getWeatherData(latitude: latitude, longitude: longitude, retryCount: retryCount + 1, completion: completion)
                    }
                    return
                }
                completion(.failure(error))
                return
            }
            
            // Check for HTTP errors
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                let error = NSError(domain: "WeatherError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Server returned status code \(httpResponse.statusCode)"])
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "WeatherError", code: 1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            do {
                let weatherData = try JSONDecoder().decode(WeatherData.self, from: data)
                completion(.success(weatherData))
            } catch {
                print("JSON Decoding Error: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }.resume()
    }
    
    func getForecastData(latitude: Double, longitude: Double, retryCount: Int = 0, completion: @escaping (Result<Forecast, Error>) -> Void) {
        // WeatherAPI.com forecast endpoint
        let urlString = "\(baseURL)/forecast.json?key=\(apiKey)&q=\(latitude),\(longitude)&days=5"
        
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "WeatherError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                if retryCount < 2 {
                    // Retry after a short delay
                    DispatchQueue.global().asyncAfter(deadline: .now() + 2) {
                        self.getForecastData(latitude: latitude, longitude: longitude, retryCount: retryCount + 1, completion: completion)
                    }
                    return
                }
                completion(.failure(error))
                return
            }
            
            // Check for HTTP errors
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                let error = NSError(domain: "WeatherError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Server returned status code \(httpResponse.statusCode)"])
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "WeatherError", code: 1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            do {
                let forecast = try JSONDecoder().decode(Forecast.self, from: data)
                completion(.success(forecast))
            } catch {
                print("JSON Decoding Error: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }.resume()
    }
}
