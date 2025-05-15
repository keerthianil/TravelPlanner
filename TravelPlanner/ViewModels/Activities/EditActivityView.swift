//
//  EditActivityView.swift
//  TravelPlanner
//
//  Created by Keerthi Reddy on 4/3/25.
//

import Foundation
import SwiftUI

struct EditActivityView: View {
    @EnvironmentObject var viewModel: TravelPlannerViewModel
    @Environment(\.dismiss) private var dismiss
    
    let activity: Activity
    
    @State private var name: String
    @State private var date: Date
    @State private var time: Date
    @State private var location: String
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    
    // Date formatters
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
    
    init(activity: Activity) {
        self.activity = activity
        
        // Initialize state variables
        _name = State(initialValue: activity.name)
        _location = State(initialValue: activity.location)
        
        // Convert string dates to Date objects
        let defaultDate = Date()
        _date = State(initialValue: dateFormatter.date(from: activity.date) ?? defaultDate)
        
        // Parse time string
        let defaultTime = Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: defaultDate) ?? defaultDate
        _time = State(initialValue: timeFormatter.date(from: activity.time) ?? defaultTime)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Activity Details")) {
                    TextField("Activity Name", text: $name)
                        .autocapitalization(.words)
                    
                    TextField("Location", text: $location)
                        .autocapitalization(.words)
                    
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    DatePicker("Time", selection: $time, displayedComponents: .hourAndMinute)
                }
            }
            .navigationTitle("Edit Activity")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        updateActivity()
                    }
                }
            }
            .alert(alertTitle, isPresented: $showingAlert) {
                Button("OK", role: .cancel) {
                    if alertTitle == "Success" {
                        dismiss()
                    }
                }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func updateActivity() {
        // Validate inputs
        if name.isEmpty {
            alertTitle = "Missing Information"
            alertMessage = "Please enter an activity name."
            showingAlert = true
            return
        }
        
        if location.isEmpty {
            alertTitle = "Missing Information"
            alertMessage = "Please enter a location for this activity."
            showingAlert = true
            return
        }
        
        let dateString = dateFormatter.string(from: date)
        let timeString = timeFormatter.string(from: time)
        
        viewModel.updateActivity(
            id: activity.id,
            name: name,
            date: dateString,
            time: timeString,
            location: location
        )
        
        alertTitle = "Success"
        alertMessage = "Activity updated successfully."
        showingAlert = true
    }
}
