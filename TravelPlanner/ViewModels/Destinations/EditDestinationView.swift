//
//  EditDestinationView.swift
//  TravelPlanner
//
//  Created by Keerthi Reddy on 4/3/25.
//

import Foundation
import SwiftUI
import PhotosUI

struct EditDestinationView: View {
    @EnvironmentObject var viewModel: TravelPlannerViewModel
    @Environment(\.dismiss) private var dismiss
    
    let destination: Destination
    
    @State private var city: String
    @State private var description: String
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    
    init(destination: Destination) {
        self.destination = destination
        _city = State(initialValue: destination.city)
        _description = State(initialValue: destination.description ?? "")
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Destination Details")) {
                    TextField("City", text: $city)
                        .autocapitalization(.words)
                    
                    // Display country as read-only
                    HStack {
                        Text("Country")
                        Spacer()
                        Text(destination.country)
                            .foregroundColor(.secondary)
                    }
                    
                    // Description is editable
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(4, reservesSpace: true)
                }
                
                Section(header: Text("Destination Image")) {
                    VStack {
                        if let imageData = destination.imageData, let uiImage = UIImage(data: imageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 200)
                        } else {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 150)
                                .overlay(
                                    Image(systemName: "photo")
                                        .foregroundColor(.gray)
                                )
                        }
                        // Images cannot be changed
                        Text("Image cannot be modified")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Edit Destination")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        updateDestination()
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
    
    private func updateDestination() {
        // Validate inputs
        if city.isEmpty {
            alertTitle = "Missing Information"
            alertMessage = "City name cannot be empty."
            showingAlert = true
            return
        }
        
        // Update city and description fields as per requirements
        viewModel.updateDestination(
            id: destination.id,
            city: city,
            description: description.isEmpty ? nil : description
        )
        
        alertTitle = "Success"
        alertMessage = "Destination updated successfully."
        showingAlert = true
    }
}
