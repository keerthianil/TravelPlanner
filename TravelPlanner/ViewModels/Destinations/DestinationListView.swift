//
//  DestinationListView.swift
//  TravelPlanner
//
//  Created by Keerthi Reddy on 4/3/25.
//

import Foundation
import SwiftUI

struct DestinationListView: View {
    @EnvironmentObject var viewModel: TravelPlannerViewModel
    @State private var searchText = ""
    @State private var isShowingAddDestination = false
    @State private var showDeleteAlert = false
    @State private var showDeleteFailAlert = false
    @State private var deleteFailMessage = ""
    @State private var destinationToDelete: Destination?
    
    var filteredDestinations: [Destination] {
        viewModel.searchDestinationsByCity(term: searchText)
    }
    struct DestinationRowView: View {
        let destination: Destination
        
        var body: some View {
            HStack(spacing: 12) {
                if let imageData = destination.imageData, let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 60, height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 60, height: 60)
                        .cornerRadius(8)
                        .overlay(
                            Image(systemName: "photo")
                                .foregroundColor(.gray)
                        )
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(destination.city), \(destination.country)")
                        .font(.headline)
                    
                    if let description = destination.description, !description.isEmpty {
                        Text(description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    } else {
                        Text("No description available")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }
    var body: some View {
        VStack {
            if filteredDestinations.isEmpty && !searchText.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "magnifyingglass")
                        .font(.largeTitle)
                        .foregroundColor(.gray)
                    Text("No destinations found matching '\(searchText)'")
                        .foregroundColor(.gray)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(filteredDestinations, id: \.id) { destination in
                        NavigationLink {
                            DestinationDetailView(destination: destination)
                        } label: {
                            DestinationRowView(destination: destination)
                        }
                    }
                    .onDelete { indexSet in
                        if let index = indexSet.first {
                            destinationToDelete = filteredDestinations[index]
                            
                            // Check if destination can be deleted
                            if viewModel.hasLinkedTrips(destinationId: destinationToDelete!.id) {
                                deleteFailMessage = "This destination has linked trips and cannot be deleted."
                                showDeleteFailAlert = true
                            } else {
                                showDeleteAlert = true
                            }
                        }
                    }
                }
                .listStyle(PlainListStyle())
            }
        }
        .navigationTitle("Destinations")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    isShowingAddDestination = true
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
        .searchable(text: $searchText, prompt: "Search by city")
        .sheet(isPresented: $isShowingAddDestination) {
            AddDestinationView()
                .environmentObject(viewModel)
        }
        .alert("Delete Destination", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let destination = destinationToDelete {
                    _ = viewModel.deleteDestination(id: destination.id)
                }
            }
        } message: {
            if let destination = destinationToDelete {
                Text("Are you sure you want to delete \(destination.city)? This cannot be undone.")
            } else {
                Text("Are you sure you want to delete this destination?")
            }
        }
        .alert("Cannot Delete", isPresented: $showDeleteFailAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(deleteFailMessage)
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
