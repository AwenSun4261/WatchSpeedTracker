# WatchSpeedTracker

一款 Apple Watch 测速追踪 App，实时显示移动速度、记录运动轨迹，并提供历史数据回顾。

## 功能概览

App 采用左右滑动切换的 TabView（`.page` 样式），共四个页面：

| 页面 | 视图 | 功能 |
|------|------|------|
| 第 1 页 | SpeedView | 实时速度 + 计时器 + 运动控制 |
| 第 2 页 | MapTabView | 实时地图轨迹 + 速度浮层 |
| 第 3 页 | StatsView | 本次运动统计数据 |
| 第 4 页 | HistoryView | 历史记录列表与详情 |

## 技术栈

- **SwiftUI** — 声明式 UI 框架
- **CoreLocation** — GPS 定位与速度获取
- **MapKit** — 地图显示与轨迹绘制
- **Combine** — 响应式数据绑定（`@Published` + `@EnvironmentObject`）
- **UserDefaults** — 历史记录本地持久化

## 部署环境

- watchOS 26.5+
- Xcode 26.6
- Swift 5.9+

## 项目结构

```
WatchSpeedTracker Watch App/
├── WatchSpeedTrackerApp.swift   # App 入口，注入全局环境对象
├── ContentView.swift            # 主界面，TabView 四页切换
├── SpeedView.swift              # 第 1 页：实时速度显示
├── MapTabView.swift             # 第 2 页：地图与轨迹
├── StatsView.swift              # 第 3 页：运动统计
├── HistoryView.swift            # 第 4 页：历史记录
├── LocationManager.swift        # GPS 定位管理器（数据核心）
└── WorkoutRecord.swift          # 运动记录模型 + 本地存储
```

## 功能详解与实现

### 1. 实时速度（SpeedView）

**功能：** 大号数字显示当前移动速度，颜色随速度变化，附设计时器与最高/平均速度。

**实现：**
- 速度来源：`CLLocation.location.speed`（m/s）× 3.6 转换为 km/h
- 速度颜色分级：`< 5` 绿色 → `< 20` 蓝色 → `< 40` 橙色 → `≥ 40` 红色
- 计时器：读取 `LocationManager.elapsedTime`，格式化为 `mm:ss`（超过 1 小时自动切换 `h:mm:ss`）
- 运动控制：三种状态切换（未开始 → 追踪中 → 暂停），每种状态显示对应按钮
- 触觉反馈：`WKHapticType` — 开始用 `.start`，暂停用 `.click`，停止用 `.stop`

### 2. 地图轨迹（MapTabView）

**功能：** 实时绘制运动轨迹，地图随行进方向旋转（车头向上），左上角速度浮层，右下角缩放按钮。

**实现：**
- 地图渲染：`Map(position:scope:)` + `MapPolyline` 绘制红色轨迹线
- 车头向上：通过 `MapCamera(centerCoordinate:distance:heading:pitch:)` 设置相机朝向，heading 由相邻两个轨迹点的 `atan2(dx, dy)` 计算得出
- 速度浮层：ZStack 叠加，半透明黑色背景 + 圆角，`.allowsHitTesting(false)` 不阻挡地图交互
- 缩放控制：三档循环（250m / 600m / 1500m），通过 `zoomLevel` 状态切换 `cameraAltitude`
- 全屏布局：`.ignoresSafeArea()` 让地图铺满屏幕

### 3. 运动统计（StatsView）

**功能：** 显示本次运动的距离、时长、平均速度、最高速度、海拔数据。

**实现：**
- 数据来源：`LocationManager` 的 `@Published` 属性，UI 自动响应更新
- 距离格式化：`< 1000m` 显示米，`≥ 1000m` 显示公里
- 海拔数据：仅在获取到 GPS 海拔时显示，包含最高/最低海拔及海拔差
- ScrollView + VStack 垂直排列，`StatRow` 复用行组件

### 4. 历史记录（HistoryView）

**功能：** 列表展示所有历史运动记录，点击查看详情，左滑删除。

**实现：**
- 列表样式：`.listStyle(.carousel)` — watchOS 轮播式列表
- 导航：`NavigationStack` + `navigationDestination(for:)` 类型安全路由
- 详情页：包含小地图（`RecordMap` 重绘轨迹）+ 完整统计数据
- 删除操作：`.swipeActions` 左滑删除，同步更新 UserDefaults

### 5. GPS 定位管理器（LocationManager）

**功能：** 整个 App 的数据核心，管理 GPS 定位、速度计算、距离累加、轨迹记录、计时。

**实现：**
- 继承 `NSObject` + `ObservableObject`，实现 `CLLocationManagerDelegate`
- 定位配置：`kCLLocationAccuracyBest` 最高精度，`distanceFilter: 5` 每 5 米更新一次，`activityType: .fitness` 运动模式
- 速度过滤：`max(0, location.speed * 3.6)` 过滤负值（GPS 搜星时可能返回 -1）
- 平均速度：累计有效速度值之和 ÷ 有效次数
- 距离累加：`location.distance(from: lastLocation)` 计算相邻定位点距离
- 轨迹去重：与上一个坐标不同才追加到 `routeCoordinates`
- 计时器：`Timer.scheduledTimer` 每秒 +1，暂停时停止计时
- 状态管理：`isTracking` + `isPaused` 双标志位控制追踪/暂停/恢复/停止

### 6. 数据持久化（WorkoutRecord + HistoryStore）

**功能：** 运动记录的模型定义与本地存储。

**实现：**
- `WorkoutRecord`：`Codable` 结构体，包含日期、时长、距离、速度、海拔、轨迹坐标
- `Coord`：可编码的坐标模型（lat/lon），用于序列化 `CLLocationCoordinate2D`
- `HistoryStore`：`ObservableObject`，通过 `UserDefaults` 存储 `[WorkoutRecord]` 的 JSON 编码数据
- 保存条件：运动时长 > 3 秒或轨迹非空才保存，避免误触产生空记录

## 架构设计

```
WatchSpeedTrackerApp (入口)
  ├── LocationManager (@StateObject) ── GPS 数据核心
  └── HistoryStore (@StateObject) ────── 本地存储
        │
        ▼ environmentObject 注入
  ContentView (TabView)
    ├── SpeedView    ← LocationManager
    ├── MapTabView   ← LocationManager
    ├── StatsView    ← LocationManager
    └── HistoryView  ← HistoryStore
```

采用 SwiftUI 的 `@EnvironmentObject` 实现数据单向流：`LocationManager` 采集 GPS 数据 → `@Published` 属性变化 → 各页面 UI 自动更新。无需手动刷新。

## 权限说明

App 需要以下权限：

- **位置权限（Always）**：运动追踪需要持续获取 GPS 数据
  - `NSLocationAlwaysAndWhenInUseUsageDescription`
  - watchOS 需使用 `requestWhenInUseAuthorization()` 请求

## 运行要求

1. 使用 Xcode 26+ 打开 `WatchSpeedTracker.xcodeproj`
2. 选择 Apple Watch 模拟器或真机
3. 真机调试需在 iPhone 的 Watch App 中开启开发者模式

---

## 更新日志

### 2026-07-02 03:06

#### MapTabView
- 地图始终渲染（不再 `if isEmpty` 条件创建），修复首次切换卡顿
- 地图旋转改用罗盘传感器 `CLHeading.trueHeading`，不再靠轨迹坐标推算
- 相机中心改用当前 GPS 位置 `currentCoordinate`，不再跟随最后轨迹点
- 初始位置改为 `.userLocation(followsHeading: true, fallback: .automatic)`
- 速度浮层挪到左下角，字号放大（速度 30pt，km/h 13pt）
- 删除无用 `currentTime` 定时器（每秒触发但时间显示已注释掉）
- `stopTracking()` 后清除所有数据，地图恢复"开始运动后这里显示轨迹"占位界面
- 尝试原生 `MapLocationCompass`（失败：脱离 `.mapControls` 不工作，已注释）

#### LocationManager
- GPS 回调中 4 次 `DispatchQueue.main.async` 合并为 1 次，减少 75% UI 刷新
- 新增 `@Published var currentCoordinate` — 当前 GPS 位置（相机跟随用）
- 新增 `@Published var heading` — 罗盘真北方向（地图旋转用）
- 新增 `@Published var horizontalAccuracy` — GPS 精度（信号等级显示用）
- 新增 `didUpdateHeading` 代理方法
- `startTracking` / `resumeTracking` 加 `startUpdatingHeading()`
- `pauseTracking` / `stopTracking` 加 `stopUpdatingHeading()`
- `stopTracking()` 保存记录后清零所有数据

#### 新增文件
- `StatusBarView.swift` — 电量 + GPS 信号状态条，4 个页面共用组件
