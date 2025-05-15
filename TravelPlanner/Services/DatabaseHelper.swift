//
//  DatabaseHelper.swift
//  TravelPlanner
//
//  Created by Keerthi Reddy on 3/18/25.
//

import Foundation
import SQLite3

class DatabaseHelper {
    static let shared = DatabaseHelper()
    
    private var db: OpaquePointer?
    private let dbPath: String
    
    private init() {
            // Get URL for the documents directory
            let fileURL = try! FileManager.default
                .url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
                .appendingPathComponent("TravelPlanner.sqlite")
            
            dbPath = fileURL.path
            print("Database path: \(dbPath)") // Debug: Print the db path
            
            // Check if database needs to be copied from bundle
            if !FileManager.default.fileExists(atPath: dbPath) {
                copyDatabaseFromBundle()
            }
            
            // Open the database
            if sqlite3_open(dbPath, &db) != SQLITE_OK {
                print("Error opening database")
                return
            }
            
            // Create tables if they don't exist
            createTables()
        }
        
    private func copyDatabaseFromBundle() {
        // Look for initial database in the app bundle
        if let bundleDbPath = Bundle.main.path(forResource: "TravelPlanner", ofType: "sqlite") {
            do {
                try FileManager.default.copyItem(atPath: bundleDbPath, toPath: dbPath)
                print("Database copied to documents directory")
            } catch {
                print("Error copying database: \(error.localizedDescription)")
            }
        } else {
            // If no database in bundle, create a new empty one
            FileManager.default.createFile(atPath: dbPath, contents: nil)
            print("Created new database")
        }
    }
    
    private func createTables() {
        // Create destinations table
        var createTableStatement: OpaquePointer?
            let createDestinationsTable = """
            CREATE TABLE IF NOT EXISTS destinations (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                city TEXT NOT NULL,
                country TEXT NOT NULL,
                imageData BLOB,
                description TEXT
            );
            """
        
        if sqlite3_prepare_v2(db, createDestinationsTable, -1, &createTableStatement, nil) == SQLITE_OK {
            if sqlite3_step(createTableStatement) != SQLITE_DONE {
                print("Error creating destinations table")
            }
        } else {
            print("Error preparing create destinations table statement")
        }
        sqlite3_finalize(createTableStatement)
        
        // Create trips table
        let createTripsTable = """
        CREATE TABLE IF NOT EXISTS trips (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            destinationId INTEGER NOT NULL,
            title TEXT NOT NULL,
            startDate TEXT NOT NULL,
            endDate TEXT NOT NULL,
            FOREIGN KEY (destinationId) REFERENCES destinations (id)
        );
        """
        
        if sqlite3_prepare_v2(db, createTripsTable, -1, &createTableStatement, nil) == SQLITE_OK {
            if sqlite3_step(createTableStatement) != SQLITE_DONE {
                print("Error creating trips table")
            }
        } else {
            print("Error preparing create trips table statement")
        }
        sqlite3_finalize(createTableStatement)
        
        // Create activities table
        let createActivitiesTable = """
        CREATE TABLE IF NOT EXISTS activities (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            tripId INTEGER NOT NULL,
            name TEXT NOT NULL,
            date TEXT NOT NULL,
            time TEXT NOT NULL,
            location TEXT NOT NULL,
            FOREIGN KEY (tripId) REFERENCES trips (id)
        );
        """
        
        if sqlite3_prepare_v2(db, createActivitiesTable, -1, &createTableStatement, nil) == SQLITE_OK {
            if sqlite3_step(createTableStatement) != SQLITE_DONE {
                print("Error creating activities table")
            }
        } else {
            print("Error preparing create activities table statement")
        }
        sqlite3_finalize(createTableStatement)
        
        // Create expenses table
        let createExpensesTable = """
        CREATE TABLE IF NOT EXISTS expenses (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            tripId INTEGER NOT NULL,
            title TEXT NOT NULL,
            amount REAL NOT NULL,
            date TEXT NOT NULL,
            FOREIGN KEY (tripId) REFERENCES trips (id)
        );
        """
        
        if sqlite3_prepare_v2(db, createExpensesTable, -1, &createTableStatement, nil) == SQLITE_OK {
            if sqlite3_step(createTableStatement) != SQLITE_DONE {
                print("Error creating expenses table")
            }
        } else {
            print("Error preparing create expenses table statement")
        }
        sqlite3_finalize(createTableStatement)
    }
    
    // MARK: - Destinations Operations
    
    func saveDestination(destination: Destination) -> Int {
        var id = destination.id
        
        // If id is 0, it's a new record to insert
        if id == 0 {
            let insertSQL = "INSERT INTO destinations (city, country, imageData, description) VALUES (?, ?, ?, ?);"
            var insertStatement: OpaquePointer?
            
            if sqlite3_prepare_v2(db, insertSQL, -1, &insertStatement, nil) == SQLITE_OK {
                sqlite3_bind_text(insertStatement, 1, (destination.city as NSString).utf8String, -1, nil)
                sqlite3_bind_text(insertStatement, 2, (destination.country as NSString).utf8String, -1, nil)
                
                if let imageData = destination.imageData {
                    sqlite3_bind_blob(insertStatement, 3, (imageData as NSData).bytes, Int32(imageData.count), nil)
                } else {
                    sqlite3_bind_null(insertStatement, 3)
                }
                
                if let description = destination.description {
                    sqlite3_bind_text(insertStatement, 4, (description as NSString).utf8String, -1, nil)
                } else {
                    sqlite3_bind_null(insertStatement, 4)
                }
                
                if sqlite3_step(insertStatement) == SQLITE_DONE {
                    id = Int(sqlite3_last_insert_rowid(db))
                } else {
                    print("Error inserting destination")
                }
            } else {
                print("Error preparing insert destination statement")
            }
            sqlite3_finalize(insertStatement)
        } else {
            // Update existing record
            let updateSQL = "UPDATE destinations SET city = ?, country = ?, imageData = ?, description = ? WHERE id = ?;"
            var updateStatement: OpaquePointer?
            
            if sqlite3_prepare_v2(db, updateSQL, -1, &updateStatement, nil) == SQLITE_OK {
                sqlite3_bind_text(updateStatement, 1, (destination.city as NSString).utf8String, -1, nil)
                sqlite3_bind_text(updateStatement, 2, (destination.country as NSString).utf8String, -1, nil)
                
                if let imageData = destination.imageData {
                    sqlite3_bind_blob(updateStatement, 3, (imageData as NSData).bytes, Int32(imageData.count), nil)
                } else {
                    sqlite3_bind_null(updateStatement, 3)
                }
                
                if let description = destination.description {
                    sqlite3_bind_text(updateStatement, 4, (description as NSString).utf8String, -1, nil)
                } else {
                    sqlite3_bind_null(updateStatement, 4)
                }
                
                sqlite3_bind_int(updateStatement, 5, Int32(id))
                
                if sqlite3_step(updateStatement) != SQLITE_DONE {
                    print("Error updating destination")
                }
            } else {
                print("Error preparing update destination statement")
            }
            sqlite3_finalize(updateStatement)
        }
        
        return id
    }
    
    func deleteDestination(id: Int) -> Bool {
        // First check if destination has linked trips
        if hasLinkedTrips(destinationId: id) {
            return false
        }
        
        let deleteSQL = "DELETE FROM destinations WHERE id = ?;"
        var deleteStatement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, deleteSQL, -1, &deleteStatement, nil) == SQLITE_OK {
            sqlite3_bind_int(deleteStatement, 1, Int32(id))
            
            if sqlite3_step(deleteStatement) != SQLITE_DONE {
                print("Error deleting destination")
                sqlite3_finalize(deleteStatement)
                return false
            }
        } else {
            print("Error preparing delete destination statement")
            sqlite3_finalize(deleteStatement)
            return false
        }
        
        sqlite3_finalize(deleteStatement)
        return true
    }
    
    func hasLinkedTrips(destinationId: Int) -> Bool {
        let querySQL = "SELECT COUNT(*) FROM trips WHERE destinationId = ?;"
        var queryStatement: OpaquePointer?
        var count = 0
        
        if sqlite3_prepare_v2(db, querySQL, -1, &queryStatement, nil) == SQLITE_OK {
            sqlite3_bind_int(queryStatement, 1, Int32(destinationId))
            
            if sqlite3_step(queryStatement) == SQLITE_ROW {
                count = Int(sqlite3_column_int(queryStatement, 0))
            }
        }
        
        sqlite3_finalize(queryStatement)
        return count > 0
    }
    
    func getAllDestinations() -> [Destination] {
        var destinations: [Destination] = []
        let querySQL = "SELECT id, city, country, imageData, description FROM destinations ORDER BY id;"
        var queryStatement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, querySQL, -1, &queryStatement, nil) == SQLITE_OK {
            while sqlite3_step(queryStatement) == SQLITE_ROW {
                let id = Int(sqlite3_column_int(queryStatement, 0))
                let city = String(cString: sqlite3_column_text(queryStatement, 1))
                let country = String(cString: sqlite3_column_text(queryStatement, 2))
                
                var imageData: Data? = nil
                var description: String? = nil
                
                if let blob = sqlite3_column_blob(queryStatement, 3) {
                    let blobLength = Int(sqlite3_column_bytes(queryStatement, 3))
                    imageData = Data(bytes: blob, count: blobLength)
                }
                
                if let descText = sqlite3_column_text(queryStatement, 4) {
                    description = String(cString: descText)
                }
                
                let destination = Destination(id: id, city: city, country: country, imageData: imageData, description: description)
                destinations.append(destination)
            }
        } else {
            print("Error preparing select destinations statement")
        }
        
        sqlite3_finalize(queryStatement)
        return destinations
    }


    func getDestination(id: Int) -> Destination? {
        let querySQL = "SELECT city, country, imageData, description FROM destinations WHERE id = ?;"
        var queryStatement: OpaquePointer?
        var destination: Destination? = nil
        
        if sqlite3_prepare_v2(db, querySQL, -1, &queryStatement, nil) == SQLITE_OK {
            sqlite3_bind_int(queryStatement, 1, Int32(id))
            
            if sqlite3_step(queryStatement) == SQLITE_ROW {
                let city = String(cString: sqlite3_column_text(queryStatement, 0))
                let country = String(cString: sqlite3_column_text(queryStatement, 1))
                
                var imageData: Data? = nil
                var description: String? = nil
                
                if let blob = sqlite3_column_blob(queryStatement, 2) {
                    let blobLength = Int(sqlite3_column_bytes(queryStatement, 2))
                    imageData = Data(bytes: blob, count: blobLength)
                }
                
                if let descText = sqlite3_column_text(queryStatement, 3) {
                    description = String(cString: descText)
                }
                
                destination = Destination(id: id, city: city, country: country, imageData: imageData, description: description)
            }
        } else {
            print("Error preparing select destination statement")
        }
        
        sqlite3_finalize(queryStatement)
        return destination
    }
    
    func deleteTrip(id: Int) -> Bool {
        // First check if trip has linked activities or expenses
        if hasLinkedActivities(tripId: id) || hasLinkedExpenses(tripId: id) {
            return false
        }
        
        let deleteSQL = "DELETE FROM trips WHERE id = ?;"
        var deleteStatement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, deleteSQL, -1, &deleteStatement, nil) == SQLITE_OK {
            sqlite3_bind_int(deleteStatement, 1, Int32(id))
            
            if sqlite3_step(deleteStatement) != SQLITE_DONE {
                print("Error deleting trip")
                sqlite3_finalize(deleteStatement)
                return false
            }
        } else {
            print("Error preparing delete trip statement")
            sqlite3_finalize(deleteStatement)
            return false
        }
        
        sqlite3_finalize(deleteStatement)
        return true
    }
    
    func hasLinkedActivities(tripId: Int) -> Bool {
        let querySQL = "SELECT COUNT(*) FROM activities WHERE tripId = ?;"
        var queryStatement: OpaquePointer?
        var count = 0
        
        if sqlite3_prepare_v2(db, querySQL, -1, &queryStatement, nil) == SQLITE_OK {
            sqlite3_bind_int(queryStatement, 1, Int32(tripId))
            
            if sqlite3_step(queryStatement) == SQLITE_ROW {
                count = Int(sqlite3_column_int(queryStatement, 0))
            }
        }
        
        sqlite3_finalize(queryStatement)
        return count > 0
    }
    
    func hasLinkedExpenses(tripId: Int) -> Bool {
        let querySQL = "SELECT COUNT(*) FROM expenses WHERE tripId = ?;"
        var queryStatement: OpaquePointer?
        var count = 0
        
        if sqlite3_prepare_v2(db, querySQL, -1, &queryStatement, nil) == SQLITE_OK {
            sqlite3_bind_int(queryStatement, 1, Int32(tripId))
            
            if sqlite3_step(queryStatement) == SQLITE_ROW {
                count = Int(sqlite3_column_int(queryStatement, 0))
            }
        }
        
        sqlite3_finalize(queryStatement)
        return count > 0
    }
    
    func getAllTrips() -> [Trip] {
        var trips: [Trip] = []
        let querySQL = "SELECT id, destinationId, title, startDate, endDate FROM trips ORDER BY id;"
        var queryStatement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, querySQL, -1, &queryStatement, nil) == SQLITE_OK {
            while sqlite3_step(queryStatement) == SQLITE_ROW {
                let id = Int(sqlite3_column_int(queryStatement, 0))
                let destinationId = Int(sqlite3_column_int(queryStatement, 1))
                let title = String(cString: sqlite3_column_text(queryStatement, 2))
                let startDate = String(cString: sqlite3_column_text(queryStatement, 3))
                let endDate = String(cString: sqlite3_column_text(queryStatement, 4))
                
                let trip = Trip(id: id, destinationId: destinationId, title: title, startDate: startDate, endDate: endDate)
                trips.append(trip)
            }
        } else {
            print("Error preparing select trips statement")
        }
        
        sqlite3_finalize(queryStatement)
        return trips
    }
    
    func getTrip(id: Int) -> Trip? {
        let querySQL = "SELECT destinationId, title, startDate, endDate FROM trips WHERE id = ?;"
        var queryStatement: OpaquePointer?
        var trip: Trip? = nil
        
        if sqlite3_prepare_v2(db, querySQL, -1, &queryStatement, nil) == SQLITE_OK {
            sqlite3_bind_int(queryStatement, 1, Int32(id))
            
            if sqlite3_step(queryStatement) == SQLITE_ROW {
                let destinationId = Int(sqlite3_column_int(queryStatement, 0))
                let title = String(cString: sqlite3_column_text(queryStatement, 1))
                let startDate = String(cString: sqlite3_column_text(queryStatement, 2))
                let endDate = String(cString: sqlite3_column_text(queryStatement, 3))
                
                trip = Trip(id: id, destinationId: destinationId, title: title, startDate: startDate, endDate: endDate)
            }
        } else {
            print("Error preparing select trip statement")
        }
        
        sqlite3_finalize(queryStatement)
        return trip
    }
    
    func getTripsForDestination(destinationId: Int) -> [Trip] {
        var trips: [Trip] = []
        let querySQL = "SELECT id, title, startDate, endDate FROM trips WHERE destinationId = ? ORDER BY id;"
        var queryStatement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, querySQL, -1, &queryStatement, nil) == SQLITE_OK {
            sqlite3_bind_int(queryStatement, 1, Int32(destinationId))
            
            while sqlite3_step(queryStatement) == SQLITE_ROW {
                let id = Int(sqlite3_column_int(queryStatement, 0))
                let title = String(cString: sqlite3_column_text(queryStatement, 1))
                let startDate = String(cString: sqlite3_column_text(queryStatement, 2))
                let endDate = String(cString: sqlite3_column_text(queryStatement, 3))
                
                let trip = Trip(id: id, destinationId: destinationId, title: title, startDate: startDate, endDate: endDate)
                trips.append(trip)
            }
        } else {
            print("Error preparing select trips for destination statement")
        }
        
        sqlite3_finalize(queryStatement)
        return trips
    }

    func saveTrip(trip: Trip) -> Int {
        var id = trip.id
        
        // If id is 0, it's a new record to insert
        if id == 0 {
            let insertSQL = "INSERT INTO trips (destinationId, title, startDate, endDate) VALUES (?, ?, ?, ?);"
            var insertStatement: OpaquePointer?
            
            if sqlite3_prepare_v2(db, insertSQL, -1, &insertStatement, nil) == SQLITE_OK {
                sqlite3_bind_int(insertStatement, 1, Int32(trip.destinationId))
                sqlite3_bind_text(insertStatement, 2, (trip.title as NSString).utf8String, -1, nil)
                sqlite3_bind_text(insertStatement, 3, (trip.startDate as NSString).utf8String, -1, nil)
                sqlite3_bind_text(insertStatement, 4, (trip.endDate as NSString).utf8String, -1, nil)
                
                if sqlite3_step(insertStatement) == SQLITE_DONE {
                    id = Int(sqlite3_last_insert_rowid(db))
                } else {
                    print("Error inserting trip")
                }
            } else {
                print("Error preparing insert trip statement")
            }
            sqlite3_finalize(insertStatement)
        } else {
            // Update existing record
            let updateSQL = "UPDATE trips SET title = ?, startDate = ?, endDate = ? WHERE id = ?;"
            var updateStatement: OpaquePointer?
            
            if sqlite3_prepare_v2(db, updateSQL, -1, &updateStatement, nil) == SQLITE_OK {
                sqlite3_bind_text(updateStatement, 1, (trip.title as NSString).utf8String, -1, nil)
                sqlite3_bind_text(updateStatement, 2, (trip.startDate as NSString).utf8String, -1, nil)
                sqlite3_bind_text(updateStatement, 3, (trip.endDate as NSString).utf8String, -1, nil)
                sqlite3_bind_int(updateStatement, 4, Int32(id))
                
                if sqlite3_step(updateStatement) != SQLITE_DONE {
                    print("Error updating trip")
                }
            } else {
                print("Error preparing update trip statement")
            }
            sqlite3_finalize(updateStatement)
        }
        
        return id
    }
    // MARK: - Activities Operations
    
    func saveActivity(activity: Activity) -> Int {
        var id = activity.id
        
        // If id is 0, it's a new record to insert
        if id == 0 {
            let insertSQL = "INSERT INTO activities (tripId, name, date, time, location) VALUES (?, ?, ?, ?, ?);"
            var insertStatement: OpaquePointer?
            
            if sqlite3_prepare_v2(db, insertSQL, -1, &insertStatement, nil) == SQLITE_OK {
                sqlite3_bind_int(insertStatement, 1, Int32(activity.tripId))
                sqlite3_bind_text(insertStatement, 2, (activity.name as NSString).utf8String, -1, nil)
                sqlite3_bind_text(insertStatement, 3, (activity.date as NSString).utf8String, -1, nil)
                sqlite3_bind_text(insertStatement, 4, (activity.time as NSString).utf8String, -1, nil)
                sqlite3_bind_text(insertStatement, 5, (activity.location as NSString).utf8String, -1, nil)
                
                if sqlite3_step(insertStatement) == SQLITE_DONE {
                    id = Int(sqlite3_last_insert_rowid(db))
                } else {
                    print("Error inserting activity")
                }
            } else {
                print("Error preparing insert activity statement")
            }
            sqlite3_finalize(insertStatement)
        } else {
            // Update existing record
            let updateSQL = "UPDATE activities SET name = ?, date = ?, time = ?, location = ? WHERE id = ?;"
            var updateStatement: OpaquePointer?
            
            if sqlite3_prepare_v2(db, updateSQL, -1, &updateStatement, nil) == SQLITE_OK {
                sqlite3_bind_text(updateStatement, 1, (activity.name as NSString).utf8String, -1, nil)
                sqlite3_bind_text(updateStatement, 2, (activity.date as NSString).utf8String, -1, nil)
                sqlite3_bind_text(updateStatement, 3, (activity.time as NSString).utf8String, -1, nil)
                sqlite3_bind_text(updateStatement, 4, (activity.location as NSString).utf8String, -1, nil)
                sqlite3_bind_int(updateStatement, 5, Int32(id))
                
                if sqlite3_step(updateStatement) != SQLITE_DONE {
                    print("Error updating activity")
                }
            } else {
                print("Error preparing update activity statement")
            }
            sqlite3_finalize(updateStatement)
        }
        
        return id
    }
    
    func deleteActivity(id: Int) -> Bool {
        // First check if activity is in the past
        if let activity = getActivity(id: id) {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            if let activityDate = dateFormatter.date(from: activity.date),
               activityDate < Date() {
                return false // Activity is in the past
            }
        }
        
        let deleteSQL = "DELETE FROM activities WHERE id = ?;"
        var deleteStatement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, deleteSQL, -1, &deleteStatement, nil) == SQLITE_OK {
            sqlite3_bind_int(deleteStatement, 1, Int32(id))
            
            if sqlite3_step(deleteStatement) != SQLITE_DONE {
                print("Error deleting activity")
                sqlite3_finalize(deleteStatement)
                return false
            }
        } else {
            print("Error preparing delete activity statement")
            sqlite3_finalize(deleteStatement)
            return false
        }
        
        sqlite3_finalize(deleteStatement)
        return true
    }
    
    func getAllActivities() -> [Activity] {
        var activities: [Activity] = []
        let querySQL = "SELECT id, tripId, name, date, time, location FROM activities ORDER BY id;"
        var queryStatement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, querySQL, -1, &queryStatement, nil) == SQLITE_OK {
            while sqlite3_step(queryStatement) == SQLITE_ROW {
                let id = Int(sqlite3_column_int(queryStatement, 0))
                let tripId = Int(sqlite3_column_int(queryStatement, 1))
                let name = String(cString: sqlite3_column_text(queryStatement, 2))
                let date = String(cString: sqlite3_column_text(queryStatement, 3))
                let time = String(cString: sqlite3_column_text(queryStatement, 4))
                let location = String(cString: sqlite3_column_text(queryStatement, 5))
                
                let activity = Activity(id: id, tripId: tripId, name: name, date: date, time: time, location: location)
                activities.append(activity)
            }
        } else {
            print("Error preparing select activities statement")
        }
        
        sqlite3_finalize(queryStatement)
        return activities
    }
    
    func getActivity(id: Int) -> Activity? {
        let querySQL = "SELECT tripId, name, date, time, location FROM activities WHERE id = ?;"
        var queryStatement: OpaquePointer?
        var activity: Activity? = nil
        
        if sqlite3_prepare_v2(db, querySQL, -1, &queryStatement, nil) == SQLITE_OK {
            sqlite3_bind_int(queryStatement, 1, Int32(id))
            
            if sqlite3_step(queryStatement) == SQLITE_ROW {
                let tripId = Int(sqlite3_column_int(queryStatement, 0))
                let name = String(cString: sqlite3_column_text(queryStatement, 1))
                let date = String(cString: sqlite3_column_text(queryStatement, 2))
                let time = String(cString: sqlite3_column_text(queryStatement, 3))
                let location = String(cString: sqlite3_column_text(queryStatement, 4))
                
                activity = Activity(id: id, tripId: tripId, name: name, date: date, time: time, location: location)
            }
        } else {
            print("Error preparing select activity statement")
        }
        
        sqlite3_finalize(queryStatement)
        return activity
    }
    
    func getActivitiesForTrip(tripId: Int) -> [Activity] {
        var activities: [Activity] = []
        let querySQL = "SELECT id, name, date, time, location FROM activities WHERE tripId = ? ORDER BY date, time;"
        var queryStatement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, querySQL, -1, &queryStatement, nil) == SQLITE_OK {
            sqlite3_bind_int(queryStatement, 1, Int32(tripId))
            
            while sqlite3_step(queryStatement) == SQLITE_ROW {
                let id = Int(sqlite3_column_int(queryStatement, 0))
                let name = String(cString: sqlite3_column_text(queryStatement, 1))
                let date = String(cString: sqlite3_column_text(queryStatement, 2))
                let time = String(cString: sqlite3_column_text(queryStatement, 3))
                let location = String(cString: sqlite3_column_text(queryStatement, 4))
                
                let activity = Activity(id: id, tripId: tripId, name: name, date: date, time: time, location: location)
                activities.append(activity)
            }
        } else {
            print("Error preparing select activities for trip statement")
        }
        
        sqlite3_finalize(queryStatement)
        return activities
    }
    
    // MARK: - Expenses Operations
    
    func saveExpense(expense: Expense) -> Int {
        var id = expense.id
        
        // If id is 0, it's a new record to insert
        if id == 0 {
            let insertSQL = "INSERT INTO expenses (tripId, title, amount, date) VALUES (?, ?, ?, ?);"
            var insertStatement: OpaquePointer?
            
            if sqlite3_prepare_v2(db, insertSQL, -1, &insertStatement, nil) == SQLITE_OK {
                sqlite3_bind_int(insertStatement, 1, Int32(expense.tripId))
                sqlite3_bind_text(insertStatement, 2, (expense.title as NSString).utf8String, -1, nil)
                sqlite3_bind_double(insertStatement, 3, expense.amount)
                sqlite3_bind_text(insertStatement, 4, (expense.date as NSString).utf8String, -1, nil)
                
                if sqlite3_step(insertStatement) == SQLITE_DONE {
                    id = Int(sqlite3_last_insert_rowid(db))
                } else {
                    print("Error inserting expense")
                }
            } else {
                print("Error preparing insert expense statement")
            }
            sqlite3_finalize(insertStatement)
        } else {
            // Update existing record
            let updateSQL = "UPDATE expenses SET title = ?, amount = ?, date = ? WHERE id = ?;"
            var updateStatement: OpaquePointer?
            
            if sqlite3_prepare_v2(db, updateSQL, -1, &updateStatement, nil) == SQLITE_OK {
                sqlite3_bind_text(updateStatement, 1, (expense.title as NSString).utf8String, -1, nil)
                sqlite3_bind_double(updateStatement, 2, expense.amount)
                sqlite3_bind_text(updateStatement, 3, (expense.date as NSString).utf8String, -1, nil)
                sqlite3_bind_int(updateStatement, 4, Int32(id))
                
                if sqlite3_step(updateStatement) != SQLITE_DONE {
                    print("Error updating expense")
                }
            } else {
                print("Error preparing update expense statement")
            }
            sqlite3_finalize(updateStatement)
        }
        
        return id
    }
    
    func deleteExpense(id: Int) -> Bool {
        // First check if expense is older than 30 days
        if let expense = getExpense(id: id) {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            if let expenseDate = dateFormatter.date(from: expense.date),
               let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()),
               expenseDate < thirtyDaysAgo {
                return false // Expense is older than 30 days
            }
        }
        
        let deleteSQL = "DELETE FROM expenses WHERE id = ?;"
        var deleteStatement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, deleteSQL, -1, &deleteStatement, nil) == SQLITE_OK {
            sqlite3_bind_int(deleteStatement, 1, Int32(id))
            
            if sqlite3_step(deleteStatement) != SQLITE_DONE {
                print("Error deleting expense")
                sqlite3_finalize(deleteStatement)
                return false
            }
        } else {
            print("Error preparing delete expense statement")
            sqlite3_finalize(deleteStatement)
            return false
        }
        
        sqlite3_finalize(deleteStatement)
        return true
    }
    
    func getAllExpenses() -> [Expense] {
        var expenses: [Expense] = []
        let querySQL = "SELECT id, tripId, title, amount, date FROM expenses ORDER BY id;"
        var queryStatement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, querySQL, -1, &queryStatement, nil) == SQLITE_OK {
            while sqlite3_step(queryStatement) == SQLITE_ROW {
                let id = Int(sqlite3_column_int(queryStatement, 0))
                let tripId = Int(sqlite3_column_int(queryStatement, 1))
                let title = String(cString: sqlite3_column_text(queryStatement, 2))
                let amount = sqlite3_column_double(queryStatement, 3)
                let date = String(cString: sqlite3_column_text(queryStatement, 4))
                
                let expense = Expense(id: id, tripId: tripId, title: title, amount: amount, date: date)
                expenses.append(expense)
            }
        } else {
            print("Error preparing select expenses statement")
        }
        
        sqlite3_finalize(queryStatement)
        return expenses
    }
    
    func getExpense(id: Int) -> Expense? {
        let querySQL = "SELECT tripId, title, amount, date FROM expenses WHERE id = ?;"
        var queryStatement: OpaquePointer?
        var expense: Expense? = nil
        
        if sqlite3_prepare_v2(db, querySQL, -1, &queryStatement, nil) == SQLITE_OK {
            sqlite3_bind_int(queryStatement, 1, Int32(id))
            
            if sqlite3_step(queryStatement) == SQLITE_ROW {
                let tripId = Int(sqlite3_column_int(queryStatement, 0))
                let title = String(cString: sqlite3_column_text(queryStatement, 1))
                let amount = sqlite3_column_double(queryStatement, 2)
                let date = String(cString: sqlite3_column_text(queryStatement, 3))
                
                expense = Expense(id: id, tripId: tripId, title: title, amount: amount, date: date)
            }
        } else {
            print("Error preparing select expense statement")
        }
        
        sqlite3_finalize(queryStatement)
        return expense
    }
    
    func getExpensesForTrip(tripId: Int) -> [Expense] {
        var expenses: [Expense] = []
        let querySQL = "SELECT id, title, amount, date FROM expenses WHERE tripId = ? ORDER BY date;"
        var queryStatement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, querySQL, -1, &queryStatement, nil) == SQLITE_OK {
            sqlite3_bind_int(queryStatement, 1, Int32(tripId))
            
            while sqlite3_step(queryStatement) == SQLITE_ROW {
                let id = Int(sqlite3_column_int(queryStatement, 0))
                let title = String(cString: sqlite3_column_text(queryStatement, 1))
                let amount = sqlite3_column_double(queryStatement, 2)
                let date = String(cString: sqlite3_column_text(queryStatement, 3))
                
                let expense = Expense(id: id, tripId: tripId, title: title, amount: amount, date: date)
                expenses.append(expense)
            }
        } else {
            print("Error preparing select expenses for trip statement")
        }
        
        sqlite3_finalize(queryStatement)
        return expenses
    }
    
    // MARK: - Search Operations
    
    func searchDestinationsByCity(cityName: String) -> [Destination] {
        var destinations: [Destination] = []
        let searchPattern = "%\(cityName)%"
        let querySQL = "SELECT id, city, country FROM destinations WHERE city LIKE ? ORDER BY id;"
        var queryStatement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, querySQL, -1, &queryStatement, nil) == SQLITE_OK {
            sqlite3_bind_text(queryStatement, 1, (searchPattern as NSString).utf8String, -1, nil)
            
            while sqlite3_step(queryStatement) == SQLITE_ROW {
                let id = Int(sqlite3_column_int(queryStatement, 0))
                let city = String(cString: sqlite3_column_text(queryStatement, 1))
                let country = String(cString: sqlite3_column_text(queryStatement, 2))
                
                let destination = Destination(id: id, city: city, country: country)
                destinations.append(destination)
            }
        } else {
            print("Error preparing search destinations statement")
        }
        
        sqlite3_finalize(queryStatement)
        return destinations
    }
    
    func searchTripById(tripId: Int) -> Trip? {
        return getTrip(id: tripId)
    }
    
    func searchActivitiesByName(name: String) -> [Activity] {
        var activities: [Activity] = []
        let searchPattern = "%\(name)%"
        let querySQL = "SELECT id, tripId, name, date, time, location FROM activities WHERE name LIKE ? ORDER BY id;"
        var queryStatement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, querySQL, -1, &queryStatement, nil) == SQLITE_OK {
            sqlite3_bind_text(queryStatement, 1, (searchPattern as NSString).utf8String, -1, nil)
            
            while sqlite3_step(queryStatement) == SQLITE_ROW {
                let id = Int(sqlite3_column_int(queryStatement, 0))
                let tripId = Int(sqlite3_column_int(queryStatement, 1))
                let name = String(cString: sqlite3_column_text(queryStatement, 2))
                let date = String(cString: sqlite3_column_text(queryStatement, 3))
                let time = String(cString: sqlite3_column_text(queryStatement, 4))
                let location = String(cString: sqlite3_column_text(queryStatement, 5))
                
                let activity = Activity(id: id, tripId: tripId, name: name, date: date, time: time, location: location)
                activities.append(activity)
            }
        } else {
            print("Error preparing search activities statement")
        }
        
        sqlite3_finalize(queryStatement)
        return activities
    }
    
    // Add any sample data for initial database
    func insertSampleData() {
        // Only insert if database is empty
        let countQuery = "SELECT COUNT(*) FROM destinations;"
        var queryStatement: OpaquePointer?
        var count = 0
        
        if sqlite3_prepare_v2(db, countQuery, -1, &queryStatement, nil) == SQLITE_OK {
            if sqlite3_step(queryStatement) == SQLITE_ROW {
                count = Int(sqlite3_column_int(queryStatement, 0))
            }
        }
        sqlite3_finalize(queryStatement)
        
        if count > 0 {
            return  // Database already has data
        }
        
        // Insert sample destinations
        let paris = Destination(id: 0, city: "Paris", country: "France")
        let tokyo = Destination(id: 0, city: "Tokyo", country: "Japan")
        let newYork = Destination(id: 0, city: "New York", country: "USA")
        
        let parisId = saveDestination(destination: paris)
        let tokyoId = saveDestination(destination: tokyo)
        let newYorkId = saveDestination(destination: newYork)
        
        // Insert sample trips
        let parisTrip1 = Trip(id: 0, destinationId: parisId, title: "Summer Vacation", startDate: "2025-06-01", endDate: "2025-06-10")
        let parisTrip2 = Trip(id: 0, destinationId: parisId, title: "Winter Getaway", startDate: "2025-12-20", endDate: "2025-12-30")
        
        let tokyoTrip1 = Trip(id: 0, destinationId: tokyoId, title: "Cherry Blossom Tour", startDate: "2025-04-01", endDate: "2025-04-10")
        let tokyoTrip2 = Trip(id: 0, destinationId: tokyoId, title: "Business Trip", startDate: "2025-09-15", endDate: "2025-09-22")
        
        let nyTrip1 = Trip(id: 0, destinationId: newYorkId, title: "Fall in NYC", startDate: "2025-10-05", endDate: "2025-10-12")
        let nyTrip2 = Trip(id: 0, destinationId: newYorkId, title: "New Year's Eve", startDate: "2025-12-28", endDate: "2026-01-03")
        
        let parisTripId1 = saveTrip(trip: parisTrip1)
        let parisTripId2 = saveTrip(trip: parisTrip2)
        let tokyoTripId1 = saveTrip(trip: tokyoTrip1)
        let tokyoTripId2 = saveTrip(trip: tokyoTrip2)
        let nyTripId1 = saveTrip(trip: nyTrip1)
        let nyTripId2 = saveTrip(trip: nyTrip2)
        
        // Insert sample activities
        let parisActivity1 = Activity(id: 0, tripId: parisTripId1, name: "Eiffel Tower Tour", date: "2025-06-02", time: "10:00", location: "Eiffel Tower")
        let parisActivity2 = Activity(id: 0, tripId: parisTripId1, name: "Louvre Museum Visit", date: "2025-06-03", time: "14:00", location: "Louvre Museum")
        
        let parisActivity3 = Activity(id: 0, tripId: parisTripId2, name: "Christmas Markets", date: "2025-12-22", time: "18:00", location: "Champs-Élysées")
        let parisActivity4 = Activity(id: 0, tripId: parisTripId2, name: "New Year's Eve Dinner", date: "2025-12-31", time: "20:00", location: "Le Jules Verne")
        
        let tokyoActivity1 = Activity(id: 0, tripId: tokyoTripId1, name: "Hanami in Ueno Park", date: "2025-04-02", time: "11:00", location: "Ueno Park")
        let tokyoActivity2 = Activity(id: 0, tripId: tokyoTripId1, name: "Shinjuku Gyoen Visit", date: "2025-04-03", time: "13:00", location: "Shinjuku Gyoen")
        
        let tokyoActivity3 = Activity(id: 0, tripId: tokyoTripId2, name: "Business Meeting", date: "2025-09-16", time: "09:00", location: "Tokyo International Forum")
        let tokyoActivity4 = Activity(id: 0, tripId: tokyoTripId2, name: "Networking Dinner", date: "2025-09-17", time: "19:00", location: "Ginza District")
        
        let nyActivity1 = Activity(id: 0, tripId: nyTripId1, name: "Central Park Walk", date: "2025-10-06", time: "10:00", location: "Central Park")
        let nyActivity2 = Activity(id: 0, tripId: nyTripId1, name: "Broadway Show", date: "2025-10-07", time: "19:30", location: "Broadway Theater")
        
        let nyActivity3 = Activity(id: 0, tripId: nyTripId2, name: "Times Square New Year", date: "2025-12-31", time: "20:00", location: "Times Square")
        let nyActivity4 = Activity(id: 0, tripId: nyTripId2, name: "Brooklyn Bridge Walk", date: "2026-01-01", time: "11:00", location: "Brooklyn Bridge")
        
        saveActivity(activity: parisActivity1)
        saveActivity(activity: parisActivity2)
        saveActivity(activity: parisActivity3)
        saveActivity(activity: parisActivity4)
        saveActivity(activity: tokyoActivity1)
        saveActivity(activity: tokyoActivity2)
        saveActivity(activity: tokyoActivity3)
        saveActivity(activity: tokyoActivity4)
        saveActivity(activity: nyActivity1)
        saveActivity(activity: nyActivity2)
        saveActivity(activity: nyActivity3)
        saveActivity(activity: nyActivity4)
        
        // Insert sample expenses
        let parisExpense1 = Expense(id: 0, tripId: parisTripId1, title: "Hotel Booking", amount: 1200.00, date: "2025-06-01")
        let parisExpense2 = Expense(id: 0, tripId: parisTripId1, title: "Dinner at Restaurant", amount: 150.00, date: "2025-06-02")
        
        let parisExpense3 = Expense(id: 0, tripId: parisTripId2, title: "Flights", amount: 800.00, date: "2025-12-20")
        let parisExpense4 = Expense(id: 0, tripId: parisTripId2, title: "New Year's Eve Celebration", amount: 300.00, date: "2025-12-31")
        
        let tokyoExpense1 = Expense(id: 0, tripId: tokyoTripId1, title: "Ryokan Stay", amount: 900.00, date: "2025-04-01")
        let tokyoExpense2 = Expense(id: 0, tripId: tokyoTripId1, title: "Sushi Dinner", amount: 200.00, date: "2025-04-02")
        
        let tokyoExpense3 = Expense(id: 0, tripId: tokyoTripId2, title: "Hotel", amount: 1500.00, date: "2025-09-15")
        let tokyoExpense4 = Expense(id: 0, tripId: tokyoTripId2, title: "Taxi Services", amount: 120.00, date: "2025-09-16")
        
        let nyExpense1 = Expense(id: 0, tripId: nyTripId1, title: "Manhattan Hotel", amount: 1800.00, date: "2025-10-05")
        let nyExpense2 = Expense(id: 0, tripId: nyTripId1, title: "Broadway Tickets", amount: 250.00, date: "2025-10-07")
        
        let nyExpense3 = Expense(id: 0, tripId: nyTripId2, title: "Times Square Package", amount: 500.00, date: "2025-12-31")
        let nyExpense4 = Expense(id: 0, tripId: nyTripId2, title: "New Year's Day Brunch", amount: 150.00, date: "2026-01-01")
        
        saveExpense(expense: parisExpense1)
        saveExpense(expense: parisExpense2)
        saveExpense(expense: parisExpense3)
        saveExpense(expense: parisExpense4)
        saveExpense(expense: tokyoExpense1)
        saveExpense(expense: tokyoExpense2)
        saveExpense(expense: tokyoExpense3)
        saveExpense(expense: tokyoExpense4)
        saveExpense(expense: nyExpense1)
        saveExpense(expense: nyExpense2)
        saveExpense(expense: nyExpense3)
        saveExpense(expense: nyExpense4)
    }
    func forceRefreshFromAPI(completion: @escaping (Bool) -> Void) {
            TravelAPIService.shared.fetchDestinations { _, error in
                if let error = error {
                    print("Error refreshing destinations from API: \(error)")
                    completion(false)
                    return
                }
                
                TravelAPIService.shared.fetchTrips { _, error in
                    if let error = error {
                        print("Error refreshing trips from API: \(error)")
                        completion(false)
                        return
                    }
                    
                    completion(true)
                }
            }
        }
}
