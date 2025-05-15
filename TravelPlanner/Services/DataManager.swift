//
//  DataManager.swift
//  TravelPlanner
//
//  Created by Keerthi Reddy on 3/4/25.
//

import Foundation

class DataManager {
    static let shared = DataManager() // Singleton pattern
    
    private var destinations: [Destination] = []
    private var trips: [Trip] = []
    private var activities: [Activity] = []
    private var expenses: [Expense] = []
    
    private init() {
        // Load data from database
        loadDataFromDatabase()
        
        // Insert sample data if needed (first run)
        DatabaseHelper.shared.insertSampleData()
        
        // Setup notification observers
        NotificationCenter.default.addObserver(self,
                                              selector: #selector(handleDestinationsUpdated),
                                              name: NSNotification.Name("DestinationsUpdated"),
                                              object: nil)
        
        NotificationCenter.default.addObserver(self,
                                              selector: #selector(handleTripsUpdated),
                                              name: NSNotification.Name("TripsUpdated"),
                                              object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func handleDestinationsUpdated() {
        loadDestinationsFromDatabase()
    }
    
    @objc private func handleTripsUpdated() {
        loadTripsFromDatabase()
    }
    
    // MARK: - Data Loading
    
    private func loadDataFromDatabase() {
        loadDestinationsFromDatabase()
        loadTripsFromDatabase()
        loadActivitiesFromDatabase()
        loadExpensesFromDatabase()
    }
    
    private func loadDestinationsFromDatabase() {
        destinations = DatabaseHelper.shared.getAllDestinations()
    }
    
    private func loadTripsFromDatabase() {
        trips = DatabaseHelper.shared.getAllTrips()
    }
    
    private func loadActivitiesFromDatabase() {
        activities = DatabaseHelper.shared.getAllActivities()
    }
    
    private func loadExpensesFromDatabase() {
        expenses = DatabaseHelper.shared.getAllExpenses()
    }
    
    // MARK: - Sync with API
    
    func syncWithAPI(completion: @escaping (Bool) -> Void) {
        let group = DispatchGroup()
        var success = true
        
        // Fetch destinations from API
        group.enter()
        TravelAPIService.shared.fetchDestinations { _, error in
            if error != nil {
                success = false
            }
            group.leave()
        }
        
        // Fetch trips from API
        group.enter()
        TravelAPIService.shared.fetchTrips { _, error in
            if error != nil {
                success = false
            }
            group.leave()
        }
        
        group.notify(queue: .main) {
            completion(success)
        }
    }
    
    // MARK: - Destination Methods
    
    func addDestination(destination: Destination) {
        // Save to local database first
        let id = DatabaseHelper.shared.saveDestination(destination: destination)
        destination.id = id
        destinations.append(destination)
        
        // If network is available, also save to API
        if NetworkReachability.isConnectedToNetwork() {
            TravelAPIService.shared.addDestinationToAPI(destination: destination) { success, error in
                if !success {
                    print("Failed to sync destination to API: \(error?.localizedDescription ?? "Unknown error")")
                }
            }
        }
        
        // Notify UI to refresh
        NotificationCenter.default.post(name: NSNotification.Name("DestinationsUpdated"), object: nil)
    }

    func updateDestination(id: Int, city: String, description: String?) {
        if let index = destinations.firstIndex(where: { $0.id == id }) {
            destinations[index].city = city
            destinations[index].description = description
            
            DatabaseHelper.shared.saveDestination(destination: destinations[index])
            
            // Notify UI to refresh
            NotificationCenter.default.post(name: NSNotification.Name("DestinationsUpdated"), object: nil)
        }
    }
    
   
    
    func deleteDestination(id: Int) -> Bool {
        if DatabaseHelper.shared.deleteDestination(id: id) {
            destinations.removeAll { $0.id == id }
            return true
        }
        return false
    }
    
    func getAllDestinations() -> [Destination] {
        return destinations
    }
    
    func getDestination(id: Int) -> Destination? {
        return destinations.first { $0.id == id }
    }
    
    func destinationExists(id: Int) -> Bool {
        return destinations.contains { $0.id == id }
    }
    
    // MARK: - Trip Methods
    
    func addTrip(destinationId: Int, title: String, startDate: String, endDate: String) {
        let trip = Trip(id: 0, destinationId: destinationId, title: title, startDate: startDate, endDate: endDate)
        let id = DatabaseHelper.shared.saveTrip(trip: trip)
        trip.id = id
        trips.append(trip)
    }
    
    func updateTrip(id: Int, title: String, endDate: String) {
        if let index = trips.firstIndex(where: { $0.id == id }) {
            trips[index].title = title
            trips[index].endDate = endDate
            DatabaseHelper.shared.saveTrip(trip: trips[index])
        }
    }
    
    func deleteTrip(id: Int) -> Bool {
        if DatabaseHelper.shared.deleteTrip(id: id) {
            trips.removeAll { $0.id == id }
            return true
        }
        return false
    }
    
    func getAllTrips() -> [Trip] {
        return trips
    }
    
    func getTrip(id: Int) -> Trip? {
        return trips.first { $0.id == id }
    }
    
    func getTripsForDestination(destinationId: Int) -> [Trip] {
        return trips.filter { $0.destinationId == destinationId }
    }
    
    // MARK: - Activity Methods
    
    func addActivity(tripId: Int, name: String, date: String, time: String, location: String) {
        let activity = Activity(id: 0, tripId: tripId, name: name, date: date, time: time, location: location)
        let id = DatabaseHelper.shared.saveActivity(activity: activity)
        activity.id = id
        activities.append(activity)
    }
    
    func updateActivity(id: Int, name: String, date: String, time: String, location: String) {
        if let index = activities.firstIndex(where: { $0.id == id }) {
            activities[index].name = name
            activities[index].date = date
            activities[index].time = time
            activities[index].location = location
            DatabaseHelper.shared.saveActivity(activity: activities[index])
        }
    }
    
    func deleteActivity(id: Int) -> Bool {
        if DatabaseHelper.shared.deleteActivity(id: id) {
            activities.removeAll { $0.id == id }
            return true
        }
        return false
    }
    
    func getAllActivities() -> [Activity] {
        return activities
    }
    
    func getActivity(id: Int) -> Activity? {
        return activities.first { $0.id == id }
    }
    
    func getActivitiesForTrip(tripId: Int) -> [Activity] {
        return activities.filter { $0.tripId == tripId }
    }
    
    // MARK: - Expense Methods
    
    func addExpense(tripId: Int, title: String, amount: Double, date: String) {
        let expense = Expense(id: 0, tripId: tripId, title: title, amount: amount, date: date)
        let id = DatabaseHelper.shared.saveExpense(expense: expense)
        expense.id = id
        expenses.append(expense)
    }
    
    func updateExpense(id: Int, title: String, amount: Double, date: String) {
        if let index = expenses.firstIndex(where: { $0.id == id }) {
            expenses[index].title = title
            expenses[index].amount = amount
            expenses[index].date = date
            DatabaseHelper.shared.saveExpense(expense: expenses[index])
        }
    }
    
    func deleteExpense(id: Int) -> Bool {
        if DatabaseHelper.shared.deleteExpense(id: id) {
            expenses.removeAll { $0.id == id }
            return true
        }
        return false
    }
    
    func getAllExpenses() -> [Expense] {
        return expenses
    }
    
    func getExpense(id: Int) -> Expense? {
        return expenses.first { $0.id == id }
    }
    
    func getExpensesForTrip(tripId: Int) -> [Expense] {
        return expenses.filter { $0.tripId == tripId }
    }
    
    // MARK: - Search Methods
    
    func searchDestinationsByCity(cityName: String) -> [Destination] {
        if cityName.isEmpty {
            return []
        }
        return DatabaseHelper.shared.searchDestinationsByCity(cityName: cityName)
    }
    
    func searchTripById(tripId: Int) -> Trip? {
        return DatabaseHelper.shared.searchTripById(tripId: tripId)
    }
    
    func searchActivitiesByName(name: String) -> [Activity] {
        if name.isEmpty {
            return []
        }
        return DatabaseHelper.shared.searchActivitiesByName(name: name)
    }
}
