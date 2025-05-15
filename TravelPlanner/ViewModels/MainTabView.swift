//
//  MainTabView.swift
//  TravelPlanner
//
//  Created by Keerthi Reddy on 4/3/25.
//

import Foundation
import SwiftUI

struct MainTabView: View {
    @StateObject var viewModel = TravelPlannerViewModel()
    
    var body: some View {
        TabView {
            NavigationView {
                DestinationListView()
                    .navigationTitle("Travel Planner")
            }
            .navigationViewStyle(StackNavigationViewStyle())
            .tabItem {
                Label("Destinations", systemImage: "mappin.and.ellipse")
            }
            
            NavigationView {
                TripListView()
                    .navigationTitle("Travel Planner")
            }
            .navigationViewStyle(StackNavigationViewStyle())
            .tabItem {
                Label("Trips", systemImage: "airplane")
            }
        }
        .environmentObject(viewModel)
        .onAppear {
            // Perform initial data load and API refresh
            viewModel.loadAllData()
            if NetworkReachability.isConnectedToNetwork() {
                viewModel.refreshDataFromAPI()
            }
        }
    }
}


//struct MainTabView_Previews: PreviewProvider{static var previews: some View {MainTabView()}}
