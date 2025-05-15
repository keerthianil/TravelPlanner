//
//  Expense.swift
//  TravelPlanner
//
//  Created by Keerthi Reddy on 3/4/25.
//
import Foundation

class Expense {
    var id: Int
    var tripId: Int
    var title: String
    var amount: Double
    var date: String

    init(id: Int, tripId: Int, title: String, amount: Double, date: String) {
        self.id = id
        self.tripId = tripId
        self.title = title
        self.amount = amount
        self.date = date
    }
}
