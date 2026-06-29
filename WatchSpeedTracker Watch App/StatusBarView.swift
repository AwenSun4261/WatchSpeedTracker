//
//  StatusBarView.swift
//  WatchSpeedTracker Watch App
//

import SwiftUI
import WatchKit
import Combine

/// 电量 + GPS 信号状态条（左上角悬浮）
struct StatusBarView: View {
    @EnvironmentObject var locationManager: LocationManager
    @State private var batteryLevel: Float = 1.0

    var body: some View {
        HStack(spacing: 6) {
            // 电量
            HStack(spacing: 2) {
                Image(systemName: batteryIcon)
                    .font(.system(size: 11))
                    .foregroundColor(batteryColor)
                Text(batteryLevel < 0 ? "--" : "\(Int(batteryLevel * 100))%")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
            }

            // GPS 信号
            HStack(spacing: 2) {
                Image(systemName: gpsIcon)
                    .font(.system(size: 9))
                    .foregroundColor(gpsColor)
                Text(gpsText)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(gpsColor)
            }
        }
        .onAppear {
            WKInterfaceDevice.current().isBatteryMonitoringEnabled = true
            batteryLevel = WKInterfaceDevice.current().batteryLevel
        }
        .onReceive(Timer.publish(every: 30, on: .main, in: .common).autoconnect()) { _ in
            batteryLevel = WKInterfaceDevice.current().batteryLevel
        }
    }

    // MARK: - 电池
    private var batteryIcon: String {
        if batteryLevel < 0 { return "battery.100" }
        let pct = batteryLevel
        if pct >= 0.875 { return "battery.100" }
        if pct >= 0.625 { return "battery.75" }
        if pct >= 0.375 { return "battery.50" }
        if pct >= 0.125 { return "battery.25" }
        return "battery.0"
    }

    private var batteryColor: Color {
        if batteryLevel < 0 { return .secondary }
        if batteryLevel >= 1.0 { return .secondary }
        if batteryLevel < 0.2 { return .red }
        if batteryLevel < 0.4 { return .orange }
        return .secondary
    }

    // MARK: - GPS 信号
    private var gpsColor: Color {
        let acc = locationManager.horizontalAccuracy
        if !locationManager.isTracking || acc < 0 { return .secondary }
        if acc <= 10 { return .green }
        if acc <= 50 { return .green }
        if acc <= 100 { return .orange }
        return .red
    }

    private var gpsText: String {
        let acc = locationManager.horizontalAccuracy
        if !locationManager.isTracking { return "待机" }
        if acc < 0 { return "搜星" }
        if acc <= 10 { return "精准" }
        if acc <= 50 { return "良好" }
        if acc <= 100 { return "一般" }
        return "弱"
    }

    private var gpsIcon: String {
        let acc = locationManager.horizontalAccuracy
        if !locationManager.isTracking { return "location.slash" }
        if acc < 0 { return "location" }
        if acc > 100 { return "location.slash" }
        return "location"
    }
}
