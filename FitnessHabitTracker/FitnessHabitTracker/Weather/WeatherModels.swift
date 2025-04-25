//  WeatherModels.swift
//  FitnessHabitTracker
//
//  Created by Nikhil Av on 4/20/25.
//

import Foundation
import SwiftUI

// WeatherAPI.com response structure
struct WeatherData: Codable {
    let location: Location
    let current: Current
    
    // Helper computed property to match old model
    var weather: [Weather] {
        return [Weather(
            id: current.condition.code,
            main: current.condition.text,
            description: current.condition.text,
            icon: current.condition.icon
        )]
    }
    
    var main: Main {
        return Main(
            temp: current.tempC,
            feelsLike: current.feelslikeC,
            tempMin: current.tempC, // not provided in current data
            tempMax: current.tempC, // not provided in current data
            pressure: current.pressureMb.map { Int($0) } ?? 0,
            humidity: current.humidity
        )
    }
    
    var wind: Wind {
        return Wind(
            speed: current.windKph / 3.6, // convert to m/s
            deg: Int(current.windDegree)
        )
    }
    
    var name: String {
        return location.name
    }
    
    var dt: TimeInterval {
        return TimeInterval(location.localtimeEpoch)
    }
    
    var sys: Sys {
        // WeatherAPI doesn't provide these by default, use middleware values
        return Sys(
            country: location.country,
            sunrise: TimeInterval(0), // Not provided
            sunset: TimeInterval(0)  // Not provided
        )
    }
}

struct Location: Codable {
    let name: String
    let region: String
    let country: String
    let lat: Double
    let lon: Double
    let tzId: String
    let localtimeEpoch: Int
    let localtime: String
    
    enum CodingKeys: String, CodingKey {
        case name, region, country, lat, lon
        case tzId = "tz_id"
        case localtimeEpoch = "localtime_epoch"
        case localtime
    }
}

struct Current: Codable {
    let lastUpdatedEpoch: Int
    let lastUpdated: String
    let tempC: Double
    let tempF: Double
    let isDay: Int
    let condition: Condition
    let windMph: Double
    let windKph: Double
    let windDegree: Double
    let windDir: String
    let pressureMb: Double?
    let pressureIn: Double?
    let precipMm: Double
    let precipIn: Double
    let humidity: Int
    let cloud: Int
    let feelslikeC: Double
    let feelslikeF: Double
    let visKm: Double
    let visMiles: Double
    let uv: Double
    let gustMph: Double
    let gustKph: Double
    
    enum CodingKeys: String, CodingKey {
        case lastUpdatedEpoch = "last_updated_epoch"
        case lastUpdated = "last_updated"
        case tempC = "temp_c"
        case tempF = "temp_f"
        case isDay = "is_day"
        case condition
        case windMph = "wind_mph"
        case windKph = "wind_kph"
        case windDegree = "wind_degree"
        case windDir = "wind_dir"
        case pressureMb = "pressure_mb"
        case pressureIn = "pressure_in"
        case precipMm = "precip_mm"
        case precipIn = "precip_in"
        case humidity, cloud
        case feelslikeC = "feelslike_c"
        case feelslikeF = "feelslike_f"
        case visKm = "vis_km"
        case visMiles = "vis_miles"
        case uv
        case gustMph = "gust_mph"
        case gustKph = "gust_kph"
    }
}

struct Condition: Codable {
    let text: String
    let icon: String
    let code: Int
}

// Forecast models for WeatherAPI.com
struct Forecast: Codable {
    let location: Location
    let current: Current
    let forecast: ForecastDays
    
    // Helper computed property to match old model
    var list: [ForecastItem] {
        return forecast.forecastday.flatMap { day in
            // Create a forecast item for each day
            let forecastItem = ForecastItem(
                dt: TimeInterval(day.dateEpoch),
                main: Main(
                    temp: day.day.avgtempC,
                    feelsLike: day.day.avgtempC, // Not provided
                    tempMin: day.day.mintempC,
                    tempMax: day.day.maxtempC,
                    pressure: 0, // Not provided
                    humidity: 0 // Not provided
                ),
                weather: [
                    Weather(
                        id: day.day.condition.code,
                        main: day.day.condition.text,
                        description: day.day.condition.text,
                        icon: day.day.condition.icon
                    )
                ],
                dt_txt: day.date
            )
            return [forecastItem]
        }
    }
}

struct ForecastDays: Codable {
    let forecastday: [ForecastDay]
}

struct ForecastDay: Codable {
    let date: String
    let dateEpoch: Int
    let day: Day
    let astro: Astro
    let hour: [Hour]
    
    enum CodingKeys: String, CodingKey {
        case date
        case dateEpoch = "date_epoch"
        case day, astro, hour
    }
}

struct Day: Codable {
    let maxtempC: Double
    let maxtempF: Double
    let mintempC: Double
    let mintempF: Double
    let avgtempC: Double
    let avgtempF: Double
    let maxwindMph: Double
    let maxwindKph: Double
    let totalprecipMm: Double
    let totalprecipIn: Double
    let totalsnowCm: Double
    let avgvisKm: Double
    let avgvisMiles: Double
    let avghumidity: Double
    let dailyWillItRain: Int
    let dailyChanceOfRain: Int
    let dailyWillItSnow: Int
    let dailyChanceOfSnow: Int
    let condition: Condition
    let uv: Double
    
    enum CodingKeys: String, CodingKey {
        case maxtempC = "maxtemp_c"
        case maxtempF = "maxtemp_f"
        case mintempC = "mintemp_c"
        case mintempF = "mintemp_f"
        case avgtempC = "avgtemp_c"
        case avgtempF = "avgtemp_f"
        case maxwindMph = "maxwind_mph"
        case maxwindKph = "maxwind_kph"
        case totalprecipMm = "totalprecip_mm"
        case totalprecipIn = "totalprecip_in"
        case totalsnowCm = "totalsnow_cm"
        case avgvisKm = "avgvis_km"
        case avgvisMiles = "avgvis_miles"
        case avghumidity
        case dailyWillItRain = "daily_will_it_rain"
        case dailyChanceOfRain = "daily_chance_of_rain"
        case dailyWillItSnow = "daily_will_it_snow"
        case dailyChanceOfSnow = "daily_chance_of_snow"
        case condition, uv
    }
}

struct Astro: Codable {
    let sunrise: String
    let sunset: String
    let moonrise: String
    let moonset: String
    let moonPhase: String
    let moonIllumination: String
    let isMoonUp: Int
    let isSunUp: Int
    
    enum CodingKeys: String, CodingKey {
        case sunrise, sunset, moonrise, moonset
        case moonPhase = "moon_phase"
        case moonIllumination = "moon_illumination"
        case isMoonUp = "is_moon_up"
        case isSunUp = "is_sun_up"
    }
}

struct Hour: Codable {
    let timeEpoch: Int
    let time: String
    let tempC: Double
    let tempF: Double
    let isDay: Int
    let condition: Condition
    let windMph: Double
    let windKph: Double
    let windDegree: Int
    let windDir: String
    let pressureMb: Double
    let pressureIn: Double
    let precipMm: Double
    let precipIn: Double
    let humidity: Int
    let cloud: Int
    let feelslikeC: Double
    let feelslikeF: Double
    let windchillC: Double
    let windchillF: Double
    let heatindexC: Double
    let heatindexF: Double
    let dewpointC: Double
    let dewpointF: Double
    let willItRain: Int
    let chanceOfRain: Int
    let willItSnow: Int
    let chanceOfSnow: Int
    let visKm: Double
    let visMiles: Double
    let gustMph: Double
    let gustKph: Double
    let uv: Double
    
    enum CodingKeys: String, CodingKey {
        case timeEpoch = "time_epoch"
        case time
        case tempC = "temp_c"
        case tempF = "temp_f"
        case isDay = "is_day"
        case condition
        case windMph = "wind_mph"
        case windKph = "wind_kph"
        case windDegree = "wind_degree"
        case windDir = "wind_dir"
        case pressureMb = "pressure_mb"
        case pressureIn = "pressure_in"
        case precipMm = "precip_mm"
        case precipIn = "precip_in"
        case humidity, cloud
        case feelslikeC = "feelslike_c"
        case feelslikeF = "feelslike_f"
        case windchillC = "windchill_c"
        case windchillF = "windchill_f"
        case heatindexC = "heatindex_c"
        case heatindexF = "heatindex_f"
        case dewpointC = "dewpoint_c"
        case dewpointF = "dewpoint_f"
        case willItRain = "will_it_rain"
        case chanceOfRain = "chance_of_rain"
        case willItSnow = "will_it_snow"
        case chanceOfSnow = "chance_of_snow"
        case visKm = "vis_km"
        case visMiles = "vis_miles"
        case gustMph = "gust_mph"
        case gustKph = "gust_kph"
        case uv
    }
}

// Compatibility models to keep existing code working
struct Weather: Codable {
    let id: Int
    let main: String
    let description: String
    let icon: String
    
    var iconURL: URL? {
        return URL(string: "https:\(icon)")
    }
    
    var isRainy: Bool {
        return main.lowercased().contains("rain") ||
               description.lowercased().contains("rain") ||
               [1063, 1180, 1183, 1186, 1189, 1192, 1195, 1240, 1243, 1246].contains(id)
    }
    
    var isSnowy: Bool {
        return main.lowercased().contains("snow") ||
               description.lowercased().contains("snow") ||
               [1066, 1114, 1117, 1210, 1213, 1216, 1219, 1222, 1225, 1255, 1258].contains(id)
    }
    
    var isClear: Bool {
        return main.lowercased().contains("clear") || main.lowercased().contains("sunny") ||
               [1000].contains(id)
    }
    
    var isCloudy: Bool {
        return main.lowercased().contains("cloud") ||
               description.lowercased().contains("cloud") ||
               [1003, 1006, 1009].contains(id)
    }
    
    var systemIconName: String {
        if isRainy {
            return "cloud.rain"
        } else if isSnowy {
            return "cloud.snow"
        } else if isClear {
            return "sun.max"
        } else if isCloudy {
            return "cloud"
        } else {
            return "cloud.sun"
        }
    }
}

struct Main: Codable {
    let temp: Double
    let feelsLike: Double
    let tempMin: Double
    let tempMax: Double
    let pressure: Int
    let humidity: Int
    
    var isHot: Bool {
        return temp > 28
    }
    
    var isCold: Bool {
        return temp < 10
    }
}

struct Wind: Codable {
    let speed: Double
    let deg: Int?
    
    var isWindy: Bool {
        return speed > 5.5  // m/s
    }
}

struct Sys: Codable {
    let country: String
    let sunrise: TimeInterval
    let sunset: TimeInterval
}

// Adapter model for forecast items
struct ForecastItem: Codable, Identifiable {
    let dt: TimeInterval
    let main: Main
    let weather: [Weather]
    let dt_txt: String
    
    var id: String {
        return dt_txt
    }
    
    var date: Date {
        return Date(timeIntervalSince1970: dt)
    }
    
    var dayOfWeek: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
}
