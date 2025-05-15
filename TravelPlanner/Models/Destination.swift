//
//  Destination.swift
//  TravelPlanner
//
//  Created by Keerthi Reddy on 3/4/25.
//
// Destination.swift
import Foundation
import UIKit

class Destination {
    var id: Int
    var city: String
    var country: String
    var imageData: Data?
    var description: String?
    
    init(id: Int, city: String, country: String, imageData: Data? = nil, description: String? = nil) {
        self.id = id
        self.city = city
        self.country = country
        self.imageData = imageData
        self.description = description
    }
    
    func getImage() -> UIImage? {
        if let imageData = imageData {
            return UIImage(data: imageData)
        }
        return nil
    }
}
