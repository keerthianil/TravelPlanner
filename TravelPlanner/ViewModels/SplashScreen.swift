//
//  SplashScreen.swift
//  TravelPlanner
//
//  Created by Keerthi Reddy on 4/4/25.
//

import Foundation
import SwiftUI

struct SplashScreen: View {
    @State private var isActive = false
    @State private var size = 0.8
    @State private var opacity = 0.5
    
    var body: some View {
        if isActive {
            MainTabView()
        } else {
            VStack {
                VStack {
                    Image("travelplannericon")
                        .resizable()
                        .frame(width: 80, height: 80)
                        .foregroundColor(.blue)

                    Text("Travel Planner")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                .scaleEffect(size)
                .opacity(opacity)
                .onAppear {
                    withAnimation(.easeIn(duration: 1.2)) {
                        self.size = 1.0
                        self.opacity = 1.0
                    }
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    self.isActive = true
                }
            }
        }
    }
}
