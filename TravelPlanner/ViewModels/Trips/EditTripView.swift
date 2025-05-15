//
//  EditTripView.swift
//  TravelPlanner
//
//  Created by Keerthi Reddy on 4/3/25.
//

import Foundation
import SwiftUI

struct EditTripView: View {
    @EnvironmentObject var viewModel: TravelPlannerViewModel
    @Environment(\.dismiss) private var dismiss
    
    let trip: Trip
    
    @State private var title: String
    @State private var endDate: Date
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    
    // Date formatter for converting stored string dates to Date objects
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    init(trip: Trip) {
        self.trip = trip
        _title = State(initialValue: trip.title)
        
        if let date = dateFormatter.date(from: trip.endDate) {
            _endDate = State(initialValue: date)
        } else {
            _endDate = State(initialValue: Date())
        }
    }
    
    var startDate: Date {
        dateFormatter.date(from: trip.startDate) ?? Date()
    }
    
    var destinationName: String {
        if let destination = viewModel.destinations.first(where: { $0.id == trip.destinationId }) {
            return "\(destination.city), \(destination.country)"
        }
        return "Unknown Destination"
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Trip Details")) {
                    TextField("Trip Title", text: $title)
                        .autocapitalization(.words)
                    
                    // Display destination as read-only
                    HStack {
                        Text("Destination")
                        Spacer()
                        Text(destinationName)
                            .foregroundColor(.secondary)
                    }
                    
                    // Display start date as read-only
                    HStack {
                        Text("Start Date")
                        Spacer()
                        Text(trip.startDate)
                            .foregroundColor(.secondary)
                    }
                    
                    // Only end date is editable
                    DatePicker("End Date", selection: $endDate, in: startDate..., displayedComponents: .date)
                }
            }
            .navigationTitle("Edit Trip")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        updateTrip()
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
    
    private func updateTrip() {
        // Validate inputs
        if title.isEmpty {
            alertTitle = "Missing Information"
            alertMessage = "Trip title is required"
            showingAlert = true
            return
        }
        
        let endDateString = dateFormatter.string(from: endDate)
        
        // Only update title and end date as per requirements
        viewModel.updateTrip(
            id: trip.id,
            title: title,
            endDate: endDateString
        )
        
        alertTitle = "Success"
        alertMessage = "Trip updated successfully."
        showingAlert = true
    }
}
