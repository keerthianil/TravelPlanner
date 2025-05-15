//
//  DestinationDetailView.swift
//  TravelPlanner
//
//  Created by Keerthi Reddy on 4/3/25.
//

import Foundation
import SwiftUI

struct DestinationDetailView: View {
    @EnvironmentObject var viewModel: TravelPlannerViewModel
    let destination: Destination
    @State private var isShowingEditSheet = false
    @State private var isShowingAddTrip = false
    @State private var showDeleteFailAlert = false
    @State private var deleteFailMessage = ""
    
    var trips: [Trip] {
        viewModel.trips.filter { $0.destinationId == destination.id }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Destination Image
                if let imageData = destination.imageData, let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .cornerRadius(12)
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 200)
                        .cornerRadius(12)
                        .overlay(
                            Image(systemName: "photo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 50)
                                .foregroundColor(.gray)
                        )
                }
                
                // Destination Details
                VStack(alignment: .leading, spacing: 8) {
                    Text("\(destination.city), \(destination.country)")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    if let description = destination.description, !description.isEmpty {
                        Text(description)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)
                
                // Trips Section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Trips")
                            .font(.headline)
                        
                        Spacer()
                        
                        Button(action: {
                            isShowingAddTrip = true
                        }) {
                            Label("Add Trip", systemImage: "plus")
                                .font(.subheadline)
                        }
                    }
                    .padding(.horizontal)
                    
                    if trips.isEmpty {
                        Text("No trips planned for this destination yet.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                    } else {
                        ForEach(trips, id: \.id) { trip in
                            NavigationLink(destination: TripDetailView(trip: trip)) {
                                TripRowView(trip: trip, cityName: destination.city)
                                    .padding(.horizontal)
                                    .padding(.vertical, 8)
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(8)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.top)
            }
            .padding(.vertical)
        }
        .navigationTitle(destination.city)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    isShowingEditSheet = true
                }) {
                    Text("Edit")
                }
            }
        }
        .sheet(isPresented: $isShowingEditSheet) {
            EditDestinationView(destination: destination)
                .environmentObject(viewModel)
        }
        .sheet(isPresented: $isShowingAddTrip) {
            AddTripView(preselectedDestinationId: destination.id)
                .environmentObject(viewModel)
        }
        .alert("Cannot Delete", isPresented: $showDeleteFailAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(deleteFailMessage)
        }
    }
}
