//
//  EditExpenseView.swift
//  TravelPlanner
//
//  Created by Keerthi Reddy on 4/3/25.
//

import Foundation
import SwiftUI

struct EditExpenseView: View {
    @EnvironmentObject var viewModel: TravelPlannerViewModel
    @Environment(\.dismiss) private var dismiss
    
    let expense: Expense
    
    @State private var title: String
    @State private var amount: String
    @State private var date: Date
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    
    // Date formatter
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    init(expense: Expense) {
        self.expense = expense
        
        // Initialize state variables
        _title = State(initialValue: expense.title)
        _amount = State(initialValue: String(format: "%.2f", expense.amount))
        
        // Convert string date to Date object
        let defaultDate = Date()
        _date = State(initialValue: dateFormatter.date(from: expense.date) ?? defaultDate)
    }
    
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
            .navigationTitle("Edit Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        updateExpense()
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
    
    private func updateExpense() {
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
        
        viewModel.updateExpense(
            id: expense.id,
            title: title,
            amount: amountValue,
            date: dateString
        )
        
        alertTitle = "Success"
        alertMessage = "Expense updated successfully."
        showingAlert = true
    }
}
