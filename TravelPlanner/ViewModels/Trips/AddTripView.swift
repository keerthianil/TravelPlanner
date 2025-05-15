//
//  AddTripView.swift
//  TravelPlanner
//
//  Created by Keerthi Reddy on 4/3/25.
//

import Foundation
import SwiftUI

struct AddTripView: View {
    @EnvironmentObject var viewModel: TravelPlannerViewModel
    @Environment(\.dismiss) private var dismiss
    
    var preselectedDestinationId: Int? = nil
    
    @State private var selectedDestinationId: Int?
    @State private var title = ""
    @State private var startDate = Date()
    @State private var endDate = Date().addingTimeInterval(86400) // Tomorrow
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    
    init(preselectedDestinationId: Int? = nil) {
        self.preselectedDestinationId = preselectedDestinationId
        _selectedDestinationId = State(initialValue: preselectedDestinationId)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Trip Details")) {
                    TextField("Trip Title", text: $title)
                        .autocapitalization(.words)
                    
                    if preselectedDestinationId == nil {
                        Picker("Destination", selection: $selectedDestinationId) {
                            Text("Select a destination").tag(nil as Int?)
                            ForEach(viewModel.destinations, id: \.id) { destination in
                                Text("\(destination.city), \(destination.country)").tag(destination.id as Int?)
                            }
                        }
                    } else if let destinationId = preselectedDestinationId,
                              let destination = viewModel.getDestination(id: destinationId) {
                        HStack {
                            Text("Destination")
                            Spacer()
                            Text("\(destination.city), \(destination.country)")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                    
                    DatePicker("End Date", selection: $endDate, in: startDate..., displayedComponents: .date)
                }
            }
            .navigationTitle("Add Trip")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveTrip()
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
    
    private func saveTrip() {
        // Validate inputs
        if title.isEmpty {
            alertTitle = "Missing Information"
            alertMessage = "Please enter a trip title."
            showingAlert = true
            return
        }
        
        guard let destinationId = selectedDestinationId ?? preselectedDestinationId else {
            alertTitle = "Missing Information"
            alertMessage = "Please select a destination for this trip."
            showingAlert = true
            return
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let startDateString = dateFormatter.string(from: startDate)
        let endDateString = dateFormatter.string(from: endDate)
        
        viewModel.addTrip(
            destinationId: destinationId,
            title: title,
            startDate: startDateString,
            endDate: endDateString
        )
        
        alertTitle = "Success"
        alertMessage = "Trip added successfully."
        showingAlert = true
    }
}
