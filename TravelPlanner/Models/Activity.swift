//
//  Activity.swift
//  TravelPlanner
//
//  Created by Keerthi Reddy on 3/4/25.
//

import Foundation

class Activity {
    var id: Int
    var tripId: Int
    var name: String
    var date: String
    var time: String
    var location: String

    init(id: Int, tripId: Int, name: String, date: String, time: String, location: String) {
        self.id = id
        self.tripId = tripId
        self.name = name
        self.date = date
        self.time = time
        self.location = location
    }
}
