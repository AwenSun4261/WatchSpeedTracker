//
//  StatsView.swift
//  WatchSpeedTracker Watch App
//

import SwiftUI

/// 第 3 页：运动统计数据
struct StatsView: View {
    @EnvironmentObject var locationManager: LocationManager

    var body: some View {
        ZStack {
            StatusBarView()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(.horizontal, 15)
                .padding(.top, 15)
                .allowsHitTesting(false)

            ScrollView {
                VStack(spacing: 10) {
                    Text("运动统计")
                        .font(.headline)

                    // 距离
                    StatRow(label: "距离", value: formatDistance(locationManager.totalDistance))

                    // 时长
                    StatRow(label: "时长", value: formatTime(locationManager.elapsedTime))

                    // 平均速度
                    if locationManager.averageSpeed > 0 {
                        StatRow(label: "均速", value: String(format: "%.1f km/h", locationManager.averageSpeed))
                    }

                    // 最高速度
                    StatRow(label: "最高", value: String(format: "%.1f km/h", locationManager.maxSpeed))

                    // 海拔数据
                    if locationManager.hasAltitudeData {
                        StatRow(label: "最高海拔", value: String(format: "%.0f m", locationManager.maxAltitude))
                        StatRow(label: "最低海拔", value: String(format: "%.0f m", locationManager.minAltitude))
                        let gain = locationManager.maxAltitude - locationManager.minAltitude
                        StatRow(label: "海拔差", value: String(format: "%.0f m", gain))
                    }

                    // 轨迹点数
                    StatRow(label: "轨迹点", value: "\(locationManager.routeCoordinates.count)")
                }
                .padding(.horizontal, 8)
                .padding(.top, 35)
            }
        }
        .ignoresSafeArea()
    }

    private func formatDistance(_ meters: Double) -> String {
        if meters < 1000 {
            return String(format: "%.0f m", meters)
        } else {
            return String(format: "%.2f km", meters / 1000)
        }
    }

    private func formatTime(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%02d:%02d", m, s)
    }
}

/// 单行统计数据显示
struct StatRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
                .font(.caption)
            Spacer()
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
        }
    }
}

#Preview {
    StatsView()
        .environmentObject(LocationManager())
}
