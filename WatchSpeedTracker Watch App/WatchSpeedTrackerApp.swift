//
//  WatchSpeedTrackerApp.swift
//  WatchSpeedTracker Watch App
//

import SwiftUI

@main
struct WatchSpeedTrackerApp: App {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var historyStore = HistoryStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(locationManager)
                .environmentObject(historyStore)
        }
    }
}
