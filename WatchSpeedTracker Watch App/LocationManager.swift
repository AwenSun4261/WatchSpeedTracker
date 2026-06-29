//
//  LocationManager.swift
//  WatchSpeedTracker Watch App
//

import Foundation
import CoreLocation
import Combine
import MapKit

/// GPS 定位管理器 — 整个 App 的数据核心
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {

    // MARK: - 发布给 UI 的数据
    @Published var currentSpeed: Double = 0          // 实时速度 km/h
    @Published var maxSpeed: Double = 0              // 本次最高速度 km/h
    @Published var averageSpeed: Double = 0          // 本次平均速度 km/h
    @Published var totalDistance: Double = 0         // 本次总距离 米
    @Published var elapsedTime: Int = 0             // 本次已运动秒数
    @Published var routeCoordinates: [CLLocationCoordinate2D] = []
    @Published var currentCoordinate: CLLocationCoordinate2D?  // 当前 GPS 位置
    @Published var isTracking = false
    @Published var isPaused = false
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var horizontalAccuracy: Double = -1   // GPS 精度（米），-1=无信号
    @Published var heading: Double = 0               // 罗盘方向（度，0=北）

    // 海拔数据
    @Published var maxAltitude: Double = 0
    @Published var minAltitude: Double = 0
    @Published var hasAltitudeData: Bool = false

    // MARK: - 私有属性
    private let locationManager = CLLocationManager()
    private var timer: Timer?
    private var speedSum: Double = 0
    private var speedCount: Int = 0
    private var lastLocation: CLLocation?
    private var pendingStart = false

    // 用于保存记录的字段
    var recordStartTime: Date = Date()
    var recordStartCoordinate: CLLocationCoordinate2D?

    // MARK: - 初始化
    override init() {
        super.init()
        authorizationStatus = locationManager.authorizationStatus
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 5
        locationManager.activityType = .fitness
    }

    // MARK: - CLLocationManagerDelegate

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard isTracking, !isPaused else { return }
        guard let location = locations.last else { return }

        // 过滤无效速度（负数或过大）
        let speed = max(0, location.speed * 3.6)
        let accuracy = location.horizontalAccuracy

        // 海拔
        let alt = location.altitude

        // 距离累加
        var newDistance: Double = 0
        if let last = lastLocation {
            newDistance = location.distance(from: last)
        }

        // 轨迹点
        let coord = location.coordinate
        let shouldAppend: Bool = {
            guard let lastCoord = routeCoordinates.last else { return true }
            return lastCoord.latitude != coord.latitude || lastCoord.longitude != coord.longitude
        }()

        // 一次性派发到主线程，减少 UI 刷新次数
        DispatchQueue.main.async {
            self.currentSpeed = speed
            self.horizontalAccuracy = accuracy
            self.currentCoordinate = coord
            if speed > 0 {
                self.speedSum += speed
                self.speedCount += 1
                self.averageSpeed = self.speedSum / Double(self.speedCount)
            }
            if speed > self.maxSpeed {
                self.maxSpeed = speed
            }

            if !self.hasAltitudeData {
                self.hasAltitudeData = true
                self.maxAltitude = alt
                self.minAltitude = alt
            } else {
                if alt > self.maxAltitude { self.maxAltitude = alt }
                if alt < self.minAltitude { self.minAltitude = alt }
            }

            self.totalDistance += newDistance

            if shouldAppend {
                self.routeCoordinates.append(coord)
            }
        }

        lastLocation = location
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // error 0 = locationUnknown，是 GPS 搜星时的正常状态，不需要打印
        let nsError = error as NSError
        if nsError.code != 0 {
            print("定位错误: \(error.localizedDescription)")
        }
    }

    /// 罗盘方向更新
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        guard isTracking, !isPaused else { return }
        let h = newHeading.trueHeading
        guard h >= 0 else { return }  // -1 = 无效
        DispatchQueue.main.async {
            self.heading = h
        }
    }

    /// 权限状态变化时回调
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async {
            self.authorizationStatus = manager.authorizationStatus
            print("权限状态变化: \(manager.authorizationStatus.rawValue)")
            if self.pendingStart && manager.authorizationStatus == .authorizedWhenInUse ||
                self.pendingStart && manager.authorizationStatus == .authorizedAlways {
                self.pendingStart = false
                self.startTracking()
            }
        }
    }

    // MARK: - 公开方法

    /// 开始追踪
    func startTracking() {
        let status = locationManager.authorizationStatus
        if status == .notDetermined {
            pendingStart = true
            locationManager.requestWhenInUseAuthorization()
            return
        }
        if status == .denied || status == .restricted {
            return
        }

        // 重置数据
        currentSpeed = 0
        maxSpeed = 0
        averageSpeed = 0
        totalDistance = 0
        elapsedTime = 0
        routeCoordinates.removeAll()
        speedSum = 0
        speedCount = 0
        lastLocation = nil
        hasAltitudeData = false
        maxAltitude = 0
        minAltitude = 0
        horizontalAccuracy = -1
        heading = 0
        currentCoordinate = nil
        recordStartTime = Date()
        recordStartCoordinate = nil

        isTracking = true
        isPaused = false
        locationManager.startUpdatingLocation()
        locationManager.startUpdatingHeading()

        // 计时器
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            DispatchQueue.main.async { self.elapsedTime += 1 }
        }
    }

    /// 暂停追踪
    func pauseTracking() {
        isPaused = true
        currentSpeed = 0
        locationManager.stopUpdatingLocation()
        locationManager.stopUpdatingHeading()
        timer?.invalidate()
        timer = nil
    }

    /// 恢复追踪
    func resumeTracking() {
        isPaused = false
        locationManager.startUpdatingLocation()
        locationManager.startUpdatingHeading()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            DispatchQueue.main.async { self.elapsedTime += 1 }
        }
    }

    /// 停止追踪 — 保存记录
    func stopTracking(saveTo store: HistoryStore? = nil) {
        isTracking = false
        isPaused = false
        locationManager.stopUpdatingLocation()
        locationManager.stopUpdatingHeading()
        timer?.invalidate()
        timer = nil
        currentSpeed = 0

        // 保存记录（运动 >3 秒或有轨迹点才保存）
        if let store = store,
           (elapsedTime > 3 || !routeCoordinates.isEmpty) {
            let record = WorkoutRecord(
                id: UUID(),
                date: recordStartTime,
                duration: elapsedTime,
                totalDistance: totalDistance,
                maxSpeed: maxSpeed,
                averageSpeed: averageSpeed,
                maxAltitude: hasAltitudeData ? maxAltitude : nil,
                minAltitude: hasAltitudeData ? minAltitude : nil,
                coordinates: routeCoordinates.map { Coord(lat: $0.latitude, lon: $0.longitude) }
            )
            store.add(record)
        }

        // 清除数据，恢复未开始状态
        routeCoordinates.removeAll()
        currentCoordinate = nil
        currentSpeed = 0
        maxSpeed = 0
        averageSpeed = 0
        totalDistance = 0
        elapsedTime = 0
        horizontalAccuracy = -1
        heading = 0
        hasAltitudeData = false
        maxAltitude = 0
        minAltitude = 0
    }
}
