//
//  WorkoutRecord.swift
//  WatchSpeedTracker Watch App
//

import Foundation
import CoreLocation
import MapKit
import Combine

// MARK: - 坐标模型（可编码）

struct Coord: Codable, Hashable {
    let lat: Double
    let lon: Double
}

// MARK: - 运动记录模型

struct WorkoutRecord: Codable, Identifiable, Hashable {
    let id: UUID
    let date: Date
    let duration: Int          // 秒
    let totalDistance: Double    // 米
    let maxSpeed: Double        // km/h
    let averageSpeed: Double    // km/h
    let maxAltitude: Double?
    let minAltitude: Double?
    let coordinates: [Coord]

    /// 中文习惯日期格式 yyyy-MM-dd
    var formattedDate: String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }

    /// 开始时间 HH:mm
    var formattedStartTime: String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f.string(from: date)
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    static func == (lhs: WorkoutRecord, rhs: WorkoutRecord) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - 历史记录存储

class HistoryStore: ObservableObject {
    @Published var records: [WorkoutRecord] = []

    private let key = "workout_records"

    init() {
        load()
    }

    func add(_ record: WorkoutRecord) {
        records.insert(record, at: 0)
        save()
    }

    func delete(_ record: WorkoutRecord) {
        records.removeAll { $0.id == record.id }
        save()
    }

    private func save() {
        do {
            let data = try JSONEncoder().encode(records)
            UserDefaults.standard.set(data, forKey: key)
        } catch {
            print("保存失败: \(error)")
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key) else { return }
        do {
            records = try JSONDecoder().decode([WorkoutRecord].self, from: data)
        } catch {
            print("读取失败: \(error)")
        }
    }
}
