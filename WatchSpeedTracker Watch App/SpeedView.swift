//
//  SpeedView.swift
//  WatchSpeedTracker Watch App
//

import SwiftUI
import WatchKit

/// 第 1 页：实时速度大数字显示
struct SpeedView: View {
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var historyStore: HistoryStore

    var body: some View {
        ZStack {
            // 电量 + GPS 状态（左上角）
            StatusBarView()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(.horizontal, 15)
                .padding(.top, 15)
                .allowsHitTesting(false)

            VStack(spacing: 4) {
                // 速度 + km/h（水平排列）
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(String(format: "%.2f", locationManager.currentSpeed))
                        .font(.system(size: 58, weight: .bold, design: .rounded))
                        .foregroundColor(speedColor)

                    Text("km/h")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }

                // 计时器 + 总距离
                HStack(spacing: 8) {
                    Text(timeString(from: locationManager.elapsedTime))
                    Text(distanceText)
                        .font(.system(size: 28, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                }
                .font(.system(size: 28, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.8))

                // 最高速度 / 平均速度（未启动也显示历史最佳）
                HStack(spacing: 12) {
                    Text("最高 \(String(format: "%.1f", locationManager.maxSpeed))")
                        .font(.system(size: 16))
                        .foregroundColor(.orange)
                    Text("均速 \(String(format: "%.1f", locationManager.averageSpeed))")
                        .font(.system(size: 16))
                        .foregroundColor(.green)
                }

                Spacer(minLength: 4)

                // 按钮区：三种状态（使用 SF Symbols 图标）
                if locationManager.isTracking {
                    if locationManager.isPaused {
                        // 暂停中：恢复 + 停止
                        HStack(spacing: 12) {
                            Button {
                                WKInterfaceDevice.current().play(.start)
                                locationManager.resumeTracking()
                            } label: {
                                Image(systemName: "play.circle.fill")
                                    .font(.title2)
                            }
                            .tint(.green)

                            Button {
                                WKInterfaceDevice.current().play(.stop)
                                locationManager.stopTracking(saveTo: historyStore)
                            } label: {
                                Image(systemName: "stop.circle.fill")
                                    .font(.title2)
                            }
                            .tint(.red)
                        }
                    } else {
                        // 追踪中：暂停 + 停止
                        HStack(spacing: 12) {
                            Button {
                                WKInterfaceDevice.current().play(.click)
                                locationManager.pauseTracking()
                            } label: {
                                Image(systemName: "pause.circle.fill")
                                    .font(.title2)
                            }
                            .tint(.orange)

                            Button {
                                WKInterfaceDevice.current().play(.stop)
                                locationManager.stopTracking(saveTo: historyStore)
                            } label: {
                                Image(systemName: "stop.circle.fill")
                                    .font(.title2)
                            }
                            .tint(.red)
                        }
                    }
                } else {
                    // 未追踪：开始
                    Button {
                        WKInterfaceDevice.current().play(.start)
                        locationManager.startTracking()
                    } label: {
                        Image(systemName: "play.circle.fill")
                            .font(.title2)
                    }
                    .tint(.green)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 35)
        }
        .ignoresSafeArea()
    }

    private var speedColor: Color {
        let s = locationManager.currentSpeed
        if s < 5 { return .green }
        if s < 10 { return .green }
        if s < 20 { return .blue }
        if s < 40 { return .orange }
        return .red
    }

    /// 将秒数格式化为 mm:ss 或 h:mm:ss
    private func timeString(from seconds: Int) -> String {
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        let s = seconds % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        }
        return String(format: "%02d:%02d", m, s)
    }

    /// 距离格式化：< 1km 显示 m，≥ 1km 显示 km
    private var distanceText: String {
        let d = locationManager.totalDistance
        if d < 1000 {
            return "\(Int(d))m"
        }
        return String(format: "%.2fkm", d / 1000)
    }
}

#Preview {
    SpeedView()
        .environmentObject(LocationManager())
        .environmentObject(HistoryStore())
}
