//
//  TravelAPIService.swift
//  TravelPlanner
//
//  Created by Keerthi Reddy on 3/30/25.
//
import Foundation
import UIKit

class TravelAPIService {
    static let shared = TravelAPIService()
    
    // Update baseURL to match the endpoint shown in your mockAPI dashboard
    private let baseURL = "https://67e8429220e3af747c40d4d5.mockapi.io/TravelPlanner"
    
    func fetchDestinations(completion: @escaping ([Destination]?, Error?) -> Void) {
        // Check network reachability
        guard NetworkReachability.isConnectedToNetwork() else {
            completion(nil, NSError(domain: "NetworkError", code: 0, userInfo: [NSLocalizedDescriptionKey: "No internet connection"]))
            return
        }
        
        let urlString = "\(baseURL)/destinations"
        guard let url = URL(string: urlString) else {
            completion(nil, NSError(domain: "URLError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"]))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 30 // Increase timeout to handle slow responses
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(nil, error)
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(nil, NSError(domain: "ServerError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid server response"]))
                return
            }
            
            // Print response for debugging
            print("Destination API Response Status: \(httpResponse.statusCode)")
            
            if !(200...299).contains(httpResponse.statusCode) {
                completion(nil, NSError(domain: "ServerError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Server returned status code \(httpResponse.statusCode)"]))
                return
            }
            
            guard let data = data else {
                completion(nil, NSError(domain: "DataError", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data received"]))
                return
            }
            
            // Print received data for debugging
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Received destination data: \(jsonString)")
            }
            
            do {
                // Try to manually parse the JSON to handle different image URL field names
                if let jsonArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                    var destinations: [Destination] = []
                    let group = DispatchGroup()
                    var hasImagestoDownload = false
                    
                    for item in jsonArray {
                        // Extract basic fields
                        guard let id = item["id"] as? Int ?? Int(item["id"] as? String ?? "0"),
                              let city = item["city"] as? String,
                              let country = item["country"] as? String else {
                            continue
                        }
                        
                        let description = item["description"] as? String
                        
                        // Check both imageURL and imageUrl fields
                        let imageURLString = (item["imageURL"] as? String) ?? (item["imageUrl"] as? String)
                        
                        // Create destination object
                        let destination = Destination(id: id, city: city, country: country, description: description)
                        
                        // Download image if available
                        if let imageURLString = imageURLString, !imageURLString.isEmpty,
                           let imageURL = URL(string: imageURLString) {
                            
                            print("Found image URL: \(imageURLString)")
                            hasImagestoDownload = true
                            group.enter()
                            
                            self.downloadImage(from: imageURL) { imageData in
                                if let imageData = imageData {
                                    print("Successfully got image data for \(city), \(imageData.count) bytes")
                                    destination.imageData = imageData
                                } else {
                                    print("Failed to get image data for \(city)")
                                }
                                
                                destinations.append(destination)
                                
                                // Save to local database
                                DispatchQueue.main.async {
                                    _ = DatabaseHelper.shared.saveDestination(destination: destination)
                                }
                                
                                group.leave()
                            }
                        } else {
                            print("No image URL found for destination: \(city)")
                            destinations.append(destination)
                            
                            // Save to local database even without image
                            DispatchQueue.main.async {
                                _ = DatabaseHelper.shared.saveDestination(destination: destination)
                            }
                        }
                    }
                    
                    if !hasImagestoDownload {
                        // If no destinations have images to download
                        DispatchQueue.main.async {
                            NotificationCenter.default.post(name: NSNotification.Name("DestinationsUpdated"), object: nil)
                            completion(destinations, nil)
                        }
                    } else {
                        group.notify(queue: .main) {
                            NotificationCenter.default.post(name: NSNotification.Name("DestinationsUpdated"), object: nil)
                            completion(destinations, nil)
                        }
                    }
                } else {
                    throw NSError(domain: "JSONParsingError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Could not parse JSON as array"])
                }
            } catch {
                print("JSON parsing error: \(error)")
                completion(nil, error)
            }
        }.resume()
    }
    func updateDestinationInAPI(destination: Destination, completion: @escaping (Bool, Error?) -> Void) {
        // Check network reachability
        guard NetworkReachability.isConnectedToNetwork() else {
            completion(false, NSError(domain: "NetworkError", code: 0, userInfo: [NSLocalizedDescriptionKey: "No internet connection"]))
            return
        }
        
        let urlString = "\(baseURL)/destinations/\(destination.id)"
        guard let url = URL(string: urlString) else {
            completion(false, NSError(domain: "URLError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"]))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30
        
        // Create a dictionary representation of the destination
        var destinationDict: [String: Any] = [
            "city": destination.city,
            "country": destination.country
        ]
        
        // Add optional fields if they exist
        if let description = destination.description {
            destinationDict["description"] = description
        }
        
        // For mockAPI, we don't actually upload the image, just use a placeholder URL if we have image data
        if destination.imageData != nil {
            destinationDict["imageUrl"] = "https://picsum.photos/200"
        }
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: destinationDict)
            request.httpBody = jsonData
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("Error updating destination: \(error)")
                    completion(false, error)
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    completion(false, NSError(domain: "ServerError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid server response"]))
                    return
                }
                
                print("Update destination API response: \(httpResponse.statusCode)")
                
                if !(200...299).contains(httpResponse.statusCode) {
                    completion(false, NSError(domain: "ServerError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Server returned status code \(httpResponse.statusCode)"]))
                    return
                }
                
                completion(true, nil)
            }.resume()
        } catch {
            print("JSON serialization error: \(error)")
            completion(false, error)
        }
    }
    func fetchTrips(completion: @escaping ([Trip]?, Error?) -> Void) {
        // Check network reachability
        guard NetworkReachability.isConnectedToNetwork() else {
            completion(nil, NSError(domain: "NetworkError", code: 0, userInfo: [NSLocalizedDescriptionKey: "No internet connection"]))
            return
        }
        
        let urlString = "\(baseURL)/trips"
        guard let url = URL(string: urlString) else {
            completion(nil, NSError(domain: "URLError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"]))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 30 // Increase timeout to handle slow responses
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(nil, error)
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(nil, NSError(domain: "ServerError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid server response"]))
                return
            }
            
            // Print response for debugging
            print("Trip API Response Status: \(httpResponse.statusCode)")
            
            if !(200...299).contains(httpResponse.statusCode) {
                completion(nil, NSError(domain: "ServerError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Server returned status code \(httpResponse.statusCode)"]))
                return
            }
            
            guard let data = data else {
                completion(nil, NSError(domain: "DataError", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data received"]))
                return
            }
            
            // Print received data for debugging
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Received trip data: \(jsonString)")
            }
            
            do {
                // Decode the JSON data
                let tripDTOs = try JSONDecoder().decode([TripDTO].self, from: data)
                
                // Convert DTOs to Trip objects and save to database
                let trips = tripDTOs.map { dto in
                    let trip = Trip(id: dto.id, destinationId: dto.destinationId, title: dto.title,
                                  startDate: dto.startDate, endDate: dto.endDate)
                    
                    // Save to local database
                    DispatchQueue.main.async {
                        _ = DatabaseHelper.shared.saveTrip(trip: trip)
                    }
                    
                    return trip
                }
                
                DispatchQueue.main.async {
                    // Notify that trips have been updated
                    NotificationCenter.default.post(name: NSNotification.Name("TripsUpdated"), object: nil)
                    completion(trips, nil)
                }
            } catch {
                print("JSON decoding error: \(error)")
                completion(nil, error)
            }
        }.resume()
    }
    
    private func downloadImage(from url: URL, completion: @escaping (Data?) -> Void) {
        print("Attempting to download image from: \(url.absoluteString)")
        
        let request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: 30)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error downloading image: \(error)")
                completion(nil)
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("Invalid response when downloading image")
                completion(nil)
                return
            }
            
            if !(200...299).contains(httpResponse.statusCode) {
                print("Server error when downloading image: \(httpResponse.statusCode)")
                completion(nil)
                return
            }
            
            if let data = data, data.count > 0 {
                print("Successfully downloaded image data: \(data.count) bytes")
                completion(data)
            } else {
                print("Image data is empty or nil")
                completion(nil)
            }
        }.resume()
    }
    func addDestinationToAPI(destination: Destination, completion: @escaping (Bool, Error?) -> Void) {
        // Check network reachability
        guard NetworkReachability.isConnectedToNetwork() else {
            completion(false, NSError(domain: "NetworkError", code: 0, userInfo: [NSLocalizedDescriptionKey: "No internet connection"]))
            return
        }
        
        let urlString = "\(baseURL)/destinations"
        guard let url = URL(string: urlString) else {
            completion(false, NSError(domain: "URLError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"]))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30
        
        // Create a dictionary representation of your destination
        // Note: For mockAPI, we don't need to convert the image to base64 - we'll use a placeholder URL
        let destinationDict: [String: Any] = [
            "city": destination.city,
            "country": destination.country,
            "description": destination.description ?? "",
            "imageUrl": "https://picsum.photos/200" // Use a placeholder image URL
        ]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: destinationDict)
            request.httpBody = jsonData
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("Error posting destination: \(error)")
                    completion(false, error)
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    completion(false, NSError(domain: "ServerError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid server response"]))
                    return
                }
                
                print("Add destination API response: \(httpResponse.statusCode)")
                
                if !(200...299).contains(httpResponse.statusCode) {
                    completion(false, NSError(domain: "ServerError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Server returned status code \(httpResponse.statusCode)"]))
                    return
                }
                
                completion(true, nil)
            }.resume()
        } catch {
            print("JSON serialization error: \(error)")
            completion(false, error)
        }
    }
}

// Data Transfer Objects for JSON parsing
struct DestinationDTO: Codable {
    let id: Int
    let city: String
    let country: String
    let imageURL: String?
    let description: String?
    
    enum CodingKeys: String, CodingKey {
        case id, city, country, description
        case imageURL = "imageUrl"
    }
}

struct TripDTO: Codable {
    let id: Int
    let destinationId: Int
    let title: String
    let startDate: String
    let endDate: String
}
