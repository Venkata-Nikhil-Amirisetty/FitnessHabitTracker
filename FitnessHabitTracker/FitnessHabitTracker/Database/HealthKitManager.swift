//
//  HealthKitManager.swift
//  FitnessHabitTracker
//
//  Created by Nikhil Av on 4/16/25.
//


import Foundation
import HealthKit

class HealthKitManager {
    static let shared = HealthKitManager()
    
    private let healthStore = HKHealthStore()
    private let readTypes: Set<HKObjectType> = [
        HKObjectType.quantityType(forIdentifier: .stepCount)!,
        HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
        HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
        HKObjectType.quantityType(forIdentifier: .heartRate)!,
        HKObjectType.workoutType()
    ]
    
    private let writeTypes: Set<HKSampleType> = [
        HKObjectType.quantityType(forIdentifier: .stepCount)!,
        HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
        HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
        HKObjectType.workoutType()
    ]
    
    private init() {}
    
    func requestAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        // Check if HealthKit is available on this device
        guard HKHealthStore.isHealthDataAvailable() else {
            completion(false, nil)
            return
        }
        
        healthStore.requestAuthorization(toShare: writeTypes, read: readTypes) { success, error in
            completion(success, error)
        }
    }
    
    func fetchStepCount(for date: Date, completion: @escaping (Double, Error?) -> Void) {
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        
        let predicate = createDayPredicate(for: date)
        
        let query = HKStatisticsQuery(
            quantityType: stepType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum
        ) { _, result, error in
            guard let result = result, let sum = result.sumQuantity() else {
                completion(0.0, error)
                return
            }
            
            let steps = sum.doubleValue(for: HKUnit.count())
            completion(steps, nil)
        }
        
        healthStore.execute(query)
    }
    
    func fetchActiveCalories(for date: Date, completion: @escaping (Double, Error?) -> Void) {
        let caloriesType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
        
        let predicate = createDayPredicate(for: date)
        
        let query = HKStatisticsQuery(
            quantityType: caloriesType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum
        ) { _, result, error in
            guard let result = result, let sum = result.sumQuantity() else {
                completion(0.0, error)
                return
            }
            
            let calories = sum.doubleValue(for: HKUnit.kilocalorie())
            completion(calories, nil)
        }
        
        healthStore.execute(query)
    }
    
    func fetchDistance(for date: Date, completion: @escaping (Double, Error?) -> Void) {
        let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!
        
        let predicate = createDayPredicate(for: date)
        
        let query = HKStatisticsQuery(
            quantityType: distanceType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum
        ) { _, result, error in
            guard let result = result, let sum = result.sumQuantity() else {
                completion(0.0, error)
                return
            }
            
            let distance = sum.doubleValue(for: HKUnit.meter())
            completion(distance, nil)
        }
        
        healthStore.execute(query)
    }
    
    func saveWorkout(type: HKWorkoutActivityType, startDate: Date, endDate: Date, calories: Double, distance: Double, completion: @escaping (Bool, Error?) -> Void) {
        // Create workout configuration
        let workoutConfiguration = HKWorkoutConfiguration()
        workoutConfiguration.activityType = type
        
        // Create energy and distance quantities
        let energyBurned = calories > 0 ? HKQuantity(unit: HKUnit.kilocalorie(), doubleValue: calories) : nil
        let distanceTraveled = distance > 0 ? HKQuantity(unit: HKUnit.meter(), doubleValue: distance) : nil
        
        do {
            // Initialize the workout builder
            let builder = try HKWorkoutBuilder(healthStore: healthStore, configuration: workoutConfiguration, device: nil)
            
            // Begin collection
            builder.beginCollection(withStart: startDate) { success, error in
                guard success else {
                    completion(false, error)
                    return
                }
                
                // Add samples if needed
                var samples: [HKSample] = []
                
                // Create active energy burned sample if calories provided
                if let energyBurned = energyBurned {
                    let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
                    let energySample = HKQuantitySample(
                        type: energyType,
                        quantity: energyBurned,
                        start: startDate,
                        end: endDate
                    )
                    samples.append(energySample)
                }
                
                // Create distance sample if distance provided
                if let distanceTraveled = distanceTraveled {
                    let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!
                    let distanceSample = HKQuantitySample(
                        type: distanceType,
                        quantity: distanceTraveled,
                        start: startDate,
                        end: endDate
                    )
                    samples.append(distanceSample)
                }
                
                // Add samples if we have any
                if !samples.isEmpty {
                    builder.add(samples) { success, error in
                        if !success {
                            print("Error adding samples: \(error?.localizedDescription ?? "Unknown error")")
                        }
                    }
                }
                
                // End collection
                builder.endCollection(withEnd: endDate) { success, error in
                    guard success else {
                        completion(false, error)
                        return
                    }
                    
                    // Finalize the workout
                    builder.finishWorkout { workout, error in
                        if let workout = workout, error == nil {
                            completion(true, nil)
                        } else {
                            completion(false, error)
                        }
                    }
                }
            }
        } catch {
            completion(false, error)
        }
    }
    
    private func createDayPredicate(for date: Date) -> NSPredicate {
        let calendar = Calendar.current
        let startDate = calendar.startOfDay(for: date)
        let endDate = calendar.date(byAdding: .day, value: 1, to: startDate)!
        
        return HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
    }
}
