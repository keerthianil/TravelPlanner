//
//  Trip.swift
//  TravelPlanner
//
//  Created by Keerthi Reddy on 3/4/25.
//


import Foundation

class Trip {
    var id: Int
    var destinationId: Int
    var title: String
    var startDate: String
    var endDate: String
    
    init(id: Int, destinationId: Int, title: String, startDate: String, endDate: String) {
        self.id = id
        self.destinationId = destinationId
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
    }
}
