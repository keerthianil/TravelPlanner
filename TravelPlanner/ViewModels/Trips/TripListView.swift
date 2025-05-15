//
//  TripListView.swift
//  TravelPlanner
//
//  Created by Keerthi Reddy on 4/3/25.
//

import Foundation
import SwiftUI

struct TripListView: View {
    @EnvironmentObject var viewModel: TravelPlannerViewModel
    @State private var searchText = ""
    @State private var isShowingAddTrip = false
    @State private var showDeleteAlert = false
    @State private var tripToDelete: Trip?
    
    var filteredTrips: [Trip] {
        viewModel.searchTripsByTitle(term: searchText)
    }
    
    var body: some View {
        VStack {
            if filteredTrips.isEmpty && !searchText.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "magnifyingglass")
                        .font(.largeTitle)
                        .foregroundColor(.gray)
                    Text("No trips found matching '\(searchText)'")
                        .foregroundColor(.gray)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(filteredTrips, id: \.id) { trip in
                        NavigationLink {
                            TripDetailView(trip: trip)
                        } label: {
                            TripRowView(trip: trip, cityName: viewModel.getDestinationCity(id: trip.destinationId))
                        }
                    }
                    .onDelete { indexSet in
                        if let index = indexSet.first {
                            tripToDelete = filteredTrips[index]
                            showDeleteAlert = true
                        }
                    }
                }
                .listStyle(PlainListStyle())
            }
        }
        .navigationTitle("Trips")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    isShowingAddTrip = true
                }) {
                    Image(systemName: "plus")
                }
            }
            
            ToolbarItem(placement: .navigationBarLeading) {
                if viewModel.isLoading {
                    ProgressView()
                }
            }
        }
        .refreshable {
            viewModel.refreshDataFromAPI()
        }
        .searchable(text: $searchText, prompt: "Search by title")
        .sheet(isPresented: $isShowingAddTrip) {
            AddTripView()
                .environmentObject(viewModel)
        }
        .alert("Delete Trip", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let trip = tripToDelete {
                    if !viewModel.deleteTrip(id: trip.id) {
                        // Show failure alert
                    }
                }
            }
        } message: {
            if let trip = tripToDelete {
                Text("Are you sure you want to delete '\(trip.title)'? This cannot be undone.")
            } else {
                Text("Are you sure you want to delete this trip?")
            }
        }
        .overlay {
            if viewModel.errorMessage != nil {
                VStack {
                    Spacer()
                    Text(viewModel.errorMessage ?? "")
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.red.opacity(0.8))
                        .cornerRadius(10)
                        .padding()
                    Spacer().frame(height: 40)
                }
            }
        }
    }
}

struct TripRowView: View {
    @EnvironmentObject var viewModel: TravelPlannerViewModel
    let trip: Trip
    let cityName: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(trip.title)
                    .font(.headline)
                
                Text(cityName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("\(trip.startDate) to \(trip.endDate)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: viewModel.getTripDurationIcon(trip: trip))
                .foregroundColor(.blue)
                .font(.title2)
        }
        .padding(.vertical, 4)
    }
}
