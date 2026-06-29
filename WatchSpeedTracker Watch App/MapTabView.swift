//
//  MapTabView.swift
//  WatchSpeedTracker Watch App
//

import SwiftUI
import MapKit
import Combine

/// 第 2 页：地图 + 轨迹
struct MapTabView: View {
    @EnvironmentObject var locationManager: LocationManager
    @State private var zoomLevel: Int = 1
    @Namespace private var mapScope

    var body: some View {
        ZStack {
            // Map 始终存在，避免首次切换时卡顿
            RouteMap(
                coordinates: locationManager.routeCoordinates,
                currentCoordinate: locationManager.currentCoordinate,
                isTracking: locationManager.isTracking,
                zoomLevel: zoomLevel,
                heading: locationManager.heading,
                scope: mapScope
            )

            // 无轨迹时显示占位提示
            if locationManager.routeCoordinates.isEmpty {
                VStack(spacing: 6) {
                    Image(systemName: "map")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    Text("开始运动后\n这里显示轨迹")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }

            // 速度浮层（左下角）
            if !locationManager.routeCoordinates.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    Text(String(format: "%.1f", locationManager.currentSpeed))
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text("km/h")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.top, -5)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 6)
                .background(.black.opacity(0.45))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                .padding(.horizontal, 15)
                .padding(.bottom, 15)
                .allowsHitTesting(false)
            }

            // 原生指南针（左下角，避开顶部时间显示）
//                MapLocationCompass(scope: mapScope)
//                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
//                    .padding(.leading, 20)
//                    .padding(.bottom, 20)
//                    .allowsHitTesting(false)

            // 缩放按钮（右下角）
            if !locationManager.routeCoordinates.isEmpty {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button {
                            withAnimation { zoomLevel = (zoomLevel + 1) % 3 }
                        } label: {
                            zoomIcon
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 32, height: 32)
                                .background(.black.opacity(0.45))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                        .padding(20)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                .allowsHitTesting(true)
            }

            // 电量 + GPS 状态（左上角）
            StatusBarView()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(.horizontal, 15)
                .padding(.top, 15)
                .allowsHitTesting(false)
        }
        .ignoresSafeArea()
    }

    private var zoomIcon: some View {
        switch zoomLevel {
        case 0: Image(systemName: "plus")
        case 1: Image(systemName: "circle")
        default: Image(systemName: "minus")
        }
    }
}

/// 地图视图（支持车头向上旋转）
struct RouteMap: View {
    let coordinates: [CLLocationCoordinate2D]
    var currentCoordinate: CLLocationCoordinate2D?
    let isTracking: Bool
    var zoomLevel: Int = 1
    var heading: Double = 0
    var scope: Namespace.ID

    @State private var position: MapCameraPosition = .userLocation(followsHeading: true, fallback: .automatic)

    private var cameraAltitude: Double {
        switch zoomLevel {
        case 0: return 250
        case 1: return 600
        default: return 1500
        }
    }

    var body: some View {
        Map(position: $position, scope: scope) {
            UserAnnotation()
            if coordinates.count >= 2 {
                MapPolyline(coordinates: coordinates)
                    .stroke(.red, lineWidth: 4)
            }
        }
        .mapStyle(.standard)
        .mapControlVisibility(.hidden)
        .allowsHitTesting(false)
        .ignoresSafeArea()
        .onAppear { updateCamera() }
        .onChange(of: currentCoordinate?.latitude) { _, _ in updateCamera() }
        .onChange(of: zoomLevel) { _, _ in updateCamera() }
        .onChange(of: heading) { _, _ in updateCamera() }
    }

    private func updateCamera() {
        // 优先用当前 GPS 位置，其次用最后一个轨迹点
        let center = currentCoordinate ?? coordinates.last
        if let center {
            let camera = MapCamera(
                centerCoordinate: center,
                distance: cameraAltitude,
                heading: heading,
                pitch: 0
            )
            position = .camera(camera)
        } else {
            // 都没有时跟随用户位置
            position = .userLocation(followsHeading: true, fallback: .automatic)
        }
    }
}

#Preview {
    let lm = LocationManager()
    lm.currentSpeed = 12.5
    lm.routeCoordinates = [
        CLLocationCoordinate2D(latitude: 39.9042, longitude: 116.4074),
        CLLocationCoordinate2D(latitude: 39.9045, longitude: 116.4078),
        CLLocationCoordinate2D(latitude: 39.9049, longitude: 116.4083),
        CLLocationCoordinate2D(latitude: 39.9054, longitude: 116.4089),
        CLLocationCoordinate2D(latitude: 39.9058, longitude: 116.4095),
    ]
    lm.isTracking = true
    lm.isPaused = false
    lm.currentCoordinate = CLLocationCoordinate2D(latitude: 39.9058, longitude: 116.4095)
    lm.heading = 45

    return MapTabView()
        .environmentObject(lm)
        .environmentObject(HistoryStore())
}
