//
//  ContentView.swift
//  WatchSpeedTracker Watch App
//

import SwiftUI

/// 主界面 — 底部 TabView 切换四个页面
struct ContentView: View {
    @EnvironmentObject var locationManager: LocationManager

    var body: some View {
        TabView {
            // 第 1 页：实时速度
            SpeedView()
                .tag(0)

            // 第 2 页：地图轨迹
            MapTabView()
                .tag(1)

            // 第 3 页：统计数据
            StatsView()
                .tag(2)

            // 第 4 页：历史记录
            HistoryView()
                .tag(3)
        }
        .tabViewStyle(.page)
    }
}

#Preview {
    ContentView()
        .environmentObject(LocationManager())
        .environmentObject(HistoryStore())
}
