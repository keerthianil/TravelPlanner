//
//  TravelPlannerViewModel.swift
//  TravelPlanner
//
//  Created by Keerthi Reddy on 4/3/25.
//

import Foundation
import SwiftUI
import Combine

class TravelPlannerViewModel: ObservableObject {
    // Published properties that will notify SwiftUI views when they change
    @Published var destinations: [Destination] = []
    @Published var trips: [Trip] = []
    @Published var activities: [Activity] = []
    @Published var expenses: [Expense] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    private var dataManager = DataManager.shared
    
    init() {
        loadAllData()
        
        // If network is available, refresh data from API
        if NetworkReachability.isConnectedToNetwork() {
            refreshDataFromAPI()
        }
    }
    
    func loadAllData() {
        destinations = dataManager.getAllDestinations()
        trips = dataManager.getAllTrips()
        activities = dataManager.getAllActivities()
        expenses = dataManager.getAllExpenses()
    }
    
    func refreshDataFromAPI() {
        isLoading = true
        errorMessage = nil
        
        TravelAPIService.shared.fetchDestinations { [weak self] fetchedDestinations, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = "Failed to fetch destinations: \(error.localizedDescription)"
                    self?.isLoading = false
                    return
                }
                
                // Now fetch trips
                TravelAPIService.shared.fetchTrips { fetchedTrips, error in
                    DispatchQueue.main.async {
                        if let error = error {
                            self?.errorMessage = "Failed to fetch trips: \(error.localizedDescription)"
                        }
                        
                        // Reload data from database regardless of API success
                        self?.loadAllData()
                        self?.isLoading = false
                    }
                }
            }
        }
    }
    
    // MARK: - Destination Functions
    
    func addDestination(city: String, country: String, description: String?, imageData: Data?) {
        let newDestination = Destination(id: 0, city: city, country: country, imageData: imageData, description: description)
        dataManager.addDestination(destination: newDestination)
        loadAllData() // Reload data to reflect changes
    }
    
    func updateDestination(id: Int, city: String, description: String?) {
        if let index = destinations.firstIndex(where: { $0.id == id }) {
            // Update local object
            destinations[index].city = city
            destinations[index].description = description
            
            // Update database
            dataManager.updateDestination(id: id, city: city, description: description)
            
            // Force UI update by reassigning the published property
            let updatedDestinations = destinations
            self.destinations = updatedDestinations
        }
        loadAllData()
    }
    
    func deleteDestination(id: Int) -> Bool {
        let result = dataManager.deleteDestination(id: id)
        if result {
            loadAllData()
        }
        return result
    }
    
    func searchDestinationsByCity(term: String) -> [Destination] {
        if term.isEmpty {
            return destinations
        }
        return destinations.filter { $0.city.lowercased().contains(term.lowercased()) }
    }
    
    // MARK: - Trip Functions
    
    func addTrip(destinationId: Int, title: String, startDate: String, endDate: String) {
        dataManager.addTrip(destinationId: destinationId, title: title, startDate: startDate, endDate: endDate)
        loadAllData()
    }
    
    func updateTrip(id: Int, title: String, endDate: String) {
        if let index = trips.firstIndex(where: { $0.id == id }) {
            // Update local object
            trips[index].title = title
            trips[index].endDate = endDate
            
            // Update database
            dataManager.updateTrip(id: id, title: title, endDate: endDate)
            
            // Force UI update by reassigning the published property
            let updatedTrips = trips
            self.trips = updatedTrips
        }
        loadAllData()
    }
    
    func deleteTrip(id: Int) -> Bool {
        let result = dataManager.deleteTrip(id: id)
        if result {
            loadAllData()
        }
        return result
    }
    
    func searchTripsByTitle(term: String) -> [Trip] {
        if term.isEmpty {
            return trips
        }
        return trips.filter { $0.title.lowercased().contains(term.lowercased()) }
    }
    
    func getTripDuration(trip: Trip) -> Int {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        guard let startDate = dateFormatter.date(from: trip.startDate),
              let endDate = dateFormatter.date(from: trip.endDate) else {
            return 0
        }
        
        let components = Calendar.current.dateComponents([.day], from: startDate, to: endDate)
        return components.day ?? 0
    }
    
    func getTripDurationIcon(trip: Trip) -> String {
        let duration = getTripDuration(trip: trip)
        
        if duration <= 3 {
            return "calendar"
        } else if duration <= 7 {
            return "calendar.badge.clock"
        } else {
            return "calendar.badge.exclamationmark"
        }
    }
    
    // MARK: - Activity & Expense Functions
    
    func addActivity(tripId: Int, name: String, date: String, time: String, location: String) {
        dataManager.addActivity(tripId: tripId, name: name, date: date, time: time, location: location)
        loadAllData()
    }
    
    func getActivitiesForTrip(tripId: Int) -> [Activity] {
        return activities.filter { $0.tripId == tripId }
    }
    
    func addExpense(tripId: Int, title: String, amount: Double, date: String) {
        dataManager.addExpense(tripId: tripId, title: title, amount: amount, date: date)
        loadAllData()
    }
    
    func getExpensesForTrip(tripId: Int) -> [Expense] {
        return expenses.filter { $0.tripId == tripId }
    }
    
    func getDestinationCity(id: Int) -> String {
        if let destination = destinations.first(where: { $0.id == id }) {
            return destination.city
        }
        return "Unknown"
    }
    
    func getDestination(id: Int) -> Destination? {
        return destinations.first(where: { $0.id == id })
    }
    
    // MARK: - Activity Functions (additional)
    func updateActivity(id: Int, name: String, date: String, time: String, location: String) {
        if let index = activities.firstIndex(where: { $0.id == id }) {
            // Update local object
            activities[index].name = name
            activities[index].date = date
            activities[index].time = time
            activities[index].location = location
            
            // Update database
            dataManager.updateActivity(id: id, name: name, date: date, time: time, location: location)
            
            // Force UI update by reassigning the published property
            let updatedActivities = activities
            self.activities = updatedActivities
        }
        loadAllData()
    }

    func deleteActivity(id: Int) -> Bool {
        let result = dataManager.deleteActivity(id: id)
        if result {
            loadAllData()
        }
        return result
    }

    // MARK: - Expense Functions (additional)
    func updateExpense(id: Int, title: String, amount: Double, date: String) {
        if let index = expenses.firstIndex(where: { $0.id == id }) {
            // Update local object
            expenses[index].title = title
            expenses[index].amount = amount
            expenses[index].date = date
            
            // Update database
            dataManager.updateExpense(id: id, title: title, amount: amount, date: date)
            
            // Force UI update by reassigning the published property
            let updatedExpenses = expenses
            self.expenses = updatedExpenses
        }
        loadAllData()
    }

    func deleteExpense(id: Int) -> Bool {
        let result = dataManager.deleteExpense(id: id)
        if result {
            loadAllData()
        }
        return result
    }
   

    func hasLinkedTrips(destinationId: Int) -> Bool {
        return trips.contains { $0.destinationId == destinationId }
    }

    func canDeleteTrip(trip: Trip) -> Bool {
        return !hasLinkedActivities(tripId: trip.id) && !hasLinkedExpenses(tripId: trip.id)
    }

    func hasLinkedActivities(tripId: Int) -> Bool {
        return activities.contains { $0.tripId == tripId }
    }

    func hasLinkedExpenses(tripId: Int) -> Bool {
        return expenses.contains { $0.tripId == tripId }
    }

    func isActivityInPast(activity: Activity) -> Bool {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        if let activityDate = dateFormatter.date(from: activity.date),
           activityDate < Date() {
            return true
        }
        return false
    }

    func isExpenseTooOld(expense: Expense) -> Bool {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        if let expenseDate = dateFormatter.date(from: expense.date),
           let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()),
           expenseDate < thirtyDaysAgo {
            return true
        }
        return false
    }
}
