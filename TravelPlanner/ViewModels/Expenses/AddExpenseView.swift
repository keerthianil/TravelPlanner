//
//  AddExpenseView.swift
//  TravelPlanner
//
//  Created by Keerthi Reddy on 4/3/25.
//

import Foundation
import SwiftUI

struct AddExpenseView: View {
    @EnvironmentObject var viewModel: TravelPlannerViewModel
    @Environment(\.dismiss) private var dismiss
    
    let tripId: Int
    
    @State private var title = ""
    @State private var amount = ""
    @State private var date = Date()
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    
    // Date formatter for date
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Expense Details")) {
                    TextField("Expense Title", text: $title)
                        .autocapitalization(.words)
                    
                    TextField("Amount", text: $amount)
                        .keyboardType(.decimalPad)
                    
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                }
            }
            .navigationTitle("Add Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveExpense()
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
    
    private func saveExpense() {
        // Validate inputs
        if title.isEmpty {
            alertTitle = "Missing Information"
            alertMessage = "Please enter an expense title."
            showingAlert = true
            return
        }
        
        guard let amountValue = Double(amount), amountValue > 0 else {
            alertTitle = "Invalid Amount"
            alertMessage = "Please enter a valid positive amount."
            showingAlert = true
            return
        }
        
        let dateString = dateFormatter.string(from: date)
        
        viewModel.addExpense(
            tripId: tripId,
            title: title,
            amount: amountValue,
            date: dateString
        )
        
        alertTitle = "Success"
        alertMessage = "Expense added successfully."
        showingAlert = true
    }
}
