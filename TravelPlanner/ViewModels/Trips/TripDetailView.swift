//
//  TripDetailView.swift
//  TravelPlanner
//
//  Created by Keerthi Reddy on 4/3/25.
//

import Foundation
//
//  TripDetailView.swift
//  TravelPlanner
//
//  Created by Keerthi Reddy on 4/3/25.
//

import Foundation
import SwiftUI

struct TripDetailView: View {
    @EnvironmentObject var viewModel: TravelPlannerViewModel
    let trip: Trip
    @State private var isShowingEditSheet = false
    @State private var isShowingAddActivity = false
    @State private var isShowingAddExpense = false
    @State private var showDeleteAlert = false
    @State private var showDeleteFailAlert = false
    @State private var deleteFailMessage = ""
    
    var activities: [Activity] {
        viewModel.getActivitiesForTrip(tripId: trip.id)
    }
    
    var expenses: [Expense] {
        viewModel.getExpensesForTrip(tripId: trip.id)
    }
    
    var destinationName: String {
        if let destination = viewModel.destinations.first(where: { $0.id == trip.destinationId }) {
            return "\(destination.city), \(destination.country)"
        }
        return "Unknown Destination"
    }
    
    var totalExpenses: Double {
        expenses.reduce(0) { $0 + $1.amount }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Trip Details
                VStack(alignment: .leading, spacing: 8) {
                    Text(trip.title)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text(destinationName)
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Text("From: \(trip.startDate)")
                        Spacer()
                        Text("To: \(trip.endDate)")
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    
                    HStack {
                        Text("Duration: \(viewModel.getTripDuration(trip: trip)) days")
                        Spacer()
                        Image(systemName: viewModel.getTripDurationIcon(trip: trip))
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                
                // Activities Section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Activities")
                            .font(.headline)
                        
                        Spacer()
                        
                        Button(action: {
                            isShowingAddActivity = true
                        }) {
                            Label("Add", systemImage: "plus")
                                .font(.subheadline)
                        }
                    }
                    .padding(.horizontal)
                    
                    if activities.isEmpty {
                        Text("No activities planned for this trip yet.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                    } else {
                        ForEach(activities, id: \.id) { activity in
                            ActivityRow(activity: activity, canDelete: canDeleteActivity(activity: activity))
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                                .padding(.horizontal)
                        }
                    }
                }
                .padding(.top)
                
                // Expenses Section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Expenses")
                            .font(.headline)
                        
                        Spacer()
                        
                        Button(action: {
                            isShowingAddExpense = true
                        }) {
                            Label("Add", systemImage: "plus")
                                .font(.subheadline)
                        }
                    }
                    .padding(.horizontal)
                    
                    if expenses.isEmpty {
                        Text("No expenses recorded for this trip yet.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                    } else {
                        Text("Total: $\(String(format: "%.2f", totalExpenses))")
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                        
                        ForEach(expenses, id: \.id) { expense in
                            ExpenseRow(expense: expense, canDelete: canDeleteExpense(expense: expense))
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                                .padding(.horizontal)
                        }
                    }
                }
                .padding(.top)
            }
            .padding(.vertical)
        }
        .navigationTitle(trip.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: {
                        isShowingEditSheet = true
                    }) {
                        Label("Edit", systemImage: "pencil")
                    }
                    
                    Button(role: .destructive, action: {
                        if !activities.isEmpty || !expenses.isEmpty {
                            deleteFailMessage = "This trip cannot be deleted because it has linked activities or expenses."
                            showDeleteFailAlert = true
                        } else {
                            showDeleteAlert = true
                        }
                    }) {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $isShowingEditSheet) {
            EditTripView(trip: trip)
                .environmentObject(viewModel)
        }
        .sheet(isPresented: $isShowingAddActivity) {
            AddActivityView(tripId: trip.id)
                .environmentObject(viewModel)
        }
        .sheet(isPresented: $isShowingAddExpense) {
            AddExpenseView(tripId: trip.id)
                .environmentObject(viewModel)
        }
        .alert("Delete Trip", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                _ = viewModel.deleteTrip(id: trip.id)
            }
        } message: {
            Text("Are you sure you want to delete this trip? This cannot be undone.")
        }
        .alert("Cannot Delete", isPresented: $showDeleteFailAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(deleteFailMessage)
        }
    }
    
    private func canDeleteActivity(activity: Activity) -> Bool {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        if let activityDate = dateFormatter.date(from: activity.date),
           activityDate < Date() {
            return false
        }
        return true
    }
    
    private func canDeleteExpense(expense: Expense) -> Bool {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        if let expenseDate = dateFormatter.date(from: expense.date),
           let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()),
           expenseDate < thirtyDaysAgo {
            return false
        }
        return true
    }
}

struct ActivityRow: View {
    @EnvironmentObject var viewModel: TravelPlannerViewModel
    let activity: Activity
    let canDelete: Bool
    @State private var showingEditSheet = false
    @State private var showDeleteAlert = false
    @State private var showDeleteFailAlert = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(activity.name)
                    .font(.headline)
                
                Spacer()
                
                Menu {
                    Button(action: {
                        showingEditSheet = true
                    }) {
                        Label("Edit", systemImage: "pencil")
                    }
                    
                    if canDelete {
                        Button(role: .destructive, action: {
                            showDeleteAlert = true
                        }) {
                            Label("Delete", systemImage: "trash")
                        }
                    } else {
                        Button(action: {
                            showDeleteFailAlert = true
                        }) {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.gray)
                }
            }
            
            Text("Date: \(activity.date) at \(activity.time)")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text("Location: \(activity.location)")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .sheet(isPresented: $showingEditSheet) {
            EditActivityView(activity: activity)
                .environmentObject(viewModel)
        }
        .alert("Delete Activity", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                _ = viewModel.deleteActivity(id: activity.id)
            }
        } message: {
            Text("Are you sure you want to delete this activity? This action cannot be undone.")
        }
        .alert("Cannot Delete", isPresented: $showDeleteFailAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Activities scheduled in the past cannot be deleted.")
        }
    }
}

struct ExpenseRow: View {
    @EnvironmentObject var viewModel: TravelPlannerViewModel
    let expense: Expense
    let canDelete: Bool
    @State private var showingEditSheet = false
    @State private var showDeleteAlert = false
    @State private var showDeleteFailAlert = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(expense.title)
                    .font(.headline)
                
                Spacer()
                
                Menu {
                    Button(action: {
                        showingEditSheet = true
                    }) {
                        Label("Edit", systemImage: "pencil")
                    }
                    
                    if canDelete {
                        Button(role: .destructive, action: {
                            showDeleteAlert = true
                        }) {
                            Label("Delete", systemImage: "trash")
                        }
                    } else {
                        Button(action: {
                            showDeleteFailAlert = true
                        }) {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.gray)
                }
            }
            
            HStack {
                Text("$\(String(format: "%.2f", expense.amount))")
                    .foregroundColor(.blue)
                
                Spacer()
                
                Text("Date: \(expense.date)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            EditExpenseView(expense: expense)
                .environmentObject(viewModel)
        }
        .alert("Delete Expense", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                _ = viewModel.deleteExpense(id: expense.id)
            }
        } message: {
            Text("Are you sure you want to delete this expense? This action cannot be undone.")
        }
        .alert("Cannot Delete", isPresented: $showDeleteFailAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Expenses older than 30 days cannot be deleted.")
        }
    }
}
