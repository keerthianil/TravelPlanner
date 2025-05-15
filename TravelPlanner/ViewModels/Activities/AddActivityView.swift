//
//  AddActivityView.swift
//  TravelPlanner
//
//  Created by Keerthi Reddy on 4/3/25.
//

import Foundation
import SwiftUI

struct AddActivityView: View {
    @EnvironmentObject var viewModel: TravelPlannerViewModel
    @Environment(\.dismiss) private var dismiss
    
    let tripId: Int
    
    @State private var name = ""
    @State private var date = Date()
    @State private var time = Date()
    @State private var location = ""
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    
    // Date formatter for date
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    // Time formatter
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
    
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
            .navigationTitle("Add Activity")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveActivity()
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
    
    private func saveActivity() {
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
        
        viewModel.addActivity(
            tripId: tripId,
            name: name,
            date: dateString,
            time: timeString,
            location: location
        )
        
        alertTitle = "Success"
        alertMessage = "Activity added successfully."
        showingAlert = true
    }
}
