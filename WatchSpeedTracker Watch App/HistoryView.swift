//
//  HistoryView.swift
//  WatchSpeedTracker Watch App
//

import SwiftUI
import MapKit

// MARK: - 历史列表页

struct HistoryView: View {
    @EnvironmentObject var historyStore: HistoryStore
    @EnvironmentObject var locationManager: LocationManager

    var body: some View {
        ZStack(alignment: .topLeading) {
//            StatusBarView()
//                .allowsHitTesting(false)

            NavigationStack {
                List {
                    if historyStore.records.isEmpty {
                        Text("暂无记录")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(historyStore.records) { record in
                            NavigationLink(value: record) {
                                HistoryRow(record: record)
                            }
                            .swipeActions {
                                Button("删除", role: .destructive) {
                                    historyStore.delete(record)
                                }
                            }
                        }
                    }
                }
                .listStyle(.carousel)
                .navigationTitle("历史")
                .navigationDestination(for: WorkoutRecord.self) { record in
                    RecordDetailView(record: record)
                }
            }
        }
    }
}

// MARK: - 列表行

struct HistoryRow: View {
    let record: WorkoutRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(record.formattedDate + " " + record.formattedStartTime)
                .font(.caption)
                .fontWeight(.medium)
            HStack(spacing: 8) {
                Text(formatDistance(record.totalDistance))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text(formatTime(record.duration))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 2)
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

// MARK: - 记录详情页

struct RecordDetailView: View {
    let record: WorkoutRecord

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                // 小地图
                if !record.coordinates.isEmpty {
                    RecordMap(coordinates: record.coordinates)
                        .frame(height: 100)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                // 数据
                VStack(spacing: 6) {
                    StatRow(label: "距离", value: formatDistance(record.totalDistance))
                    StatRow(label: "时长", value: formatTime(record.duration))
                    StatRow(label: "均速", value: String(format: "%.1f km/h", record.averageSpeed))
                    StatRow(label: "最高", value: String(format: "%.1f km/h", record.maxSpeed))
                    if let maxAlt = record.maxAltitude {
                        StatRow(label: "最高海拔", value: String(format: "%.0f m", maxAlt))
                    }
                    if let minAlt = record.minAltitude {
                        StatRow(label: "最低海拔", value: String(format: "%.0f m", minAlt))
                    }
                    StatRow(label: "轨迹点", value: "\(record.coordinates.count)")
                }
            }
            .padding(.horizontal, 8)
        }
        .navigationTitle(record.formattedDate)
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

// MARK: - 详情页小地图

struct RecordMap: View {
    let coordinates: [Coord]

    @State private var position: MapCameraPosition = .automatic

    var body: some View {
        Map(position: $position) {
            if coordinates.count >= 2 {
                MapPolyline(
                    coordinates: coordinates.map {
                        CLLocationCoordinate2D(latitude: $0.lat, longitude: $0.lon)
                    }
                )
                .stroke(.red, lineWidth: 3)
            }
        }
        .mapStyle(.standard)
        .allowsHitTesting(false)
        .onAppear {
            if let first = coordinates.first {
                position = .region(MKCoordinateRegion(
                    center: CLLocationCoordinate2D(latitude: first.lat, longitude: first.lon),
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                ))
            }
        }
    }
}

#Preview {
    let store = HistoryStore()
    let sampleRecord = WorkoutRecord(
        id: UUID(),
        date: Date(),
        duration: 300,
        totalDistance: 1200,
        maxSpeed: 18.5,
        averageSpeed: 14.4,
        maxAltitude: 85,
        minAltitude: 62,
        coordinates: []
    )
    store.add(sampleRecord)

    return HistoryView()
        .environmentObject(store)
        .environmentObject(LocationManager())
}
