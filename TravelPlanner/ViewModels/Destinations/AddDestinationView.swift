//
//  AddDestinationView.swift
//  TravelPlanner
//
//  Created by Keerthi Reddy on 4/3/25.
//

import Foundation
import SwiftUI
import PhotosUI

struct AddDestinationView: View {
    @EnvironmentObject var viewModel: TravelPlannerViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var city = ""
    @State private var country = ""
    @State private var description = ""
    @State private var selectedImage: UIImage?
    @State private var selectedItem: PhotosPickerItem?
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Destination Details")) {
                    TextField("City", text: $city)
                        .autocapitalization(.words)
                    
                    TextField("Country", text: $country)
                        .autocapitalization(.words)
                    
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(4, reservesSpace: true)
                }
                
                Section(header: Text("Destination Image")) {
                    VStack {
                        if let selectedImage {
                            Image(uiImage: selectedImage)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 200)
                        }
                        
                        PhotosPicker(selection: $selectedItem, matching: .images) {
                            Label("Select Image", systemImage: "photo")
                        }
                    }
                }
            }
            .navigationTitle("Add Destination")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveDestination()
                    }
                }
            }
            .alert(alertTitle, isPresented: $showingAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
            .task(id: selectedItem) {
                if let data = try? await selectedItem?.loadTransferable(type: Data.self) {
                    if let uiImage = UIImage(data: data) {
                        selectedImage = uiImage
                        return
                    }
                }
                
                print("Failed to load image")
            }
        }
    }
    
    private func saveDestination() {
        // Validate inputs
        if city.isEmpty || country.isEmpty {
            alertTitle = "Missing Information"
            alertMessage = "Please fill in both city and country fields."
            showingAlert = true
            return
        }
        
        var imageData: Data? = nil
        if let selectedImage {
            imageData = selectedImage.jpegData(compressionQuality: 0.7)
        }
        
        viewModel.addDestination(
            city: city,
            country: country,
            description: description.isEmpty ? nil : description,
            imageData: imageData
        )
        
        alertTitle = "Success"
        alertMessage = "Destination added successfully."
        showingAlert = true
        
        // Dismiss after showing success message (with delay)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            dismiss()
        }
    }
}
