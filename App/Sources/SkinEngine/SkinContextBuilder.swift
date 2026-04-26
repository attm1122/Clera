import Foundation

// MARK: - Skin Context Builder

enum SkinContextBuilder {

    static func build(from appState: PersistedAppState, weather: DailyWeatherSnapshot? = nil, airQuality: AirQualitySnapshot? = nil) -> SkinContext {
        let sortedSessions = appState.sessions.sorted { $0.createdAt > $1.createdAt }
        let latestScan = sortedSessions.first
        let previousScan = sortedSessions.dropFirst().first
        let baselineScan = sortedSessions.first { $0.kind == .baseline }

        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: .now) ?? .now
        let scansLastSevenDays = sortedSessions.filter { $0.createdAt >= sevenDaysAgo }

        let latestSkinMap = latestScan?.skinMap ?? appState.skinMapHistory.last
        let baselineSkinMap = baselineScan?.skinMap ?? appState.baselineSkinMap

        let allCheckIns = sortedSessions.compactMap { $0.skinMap.checkIn }
        let latestCheckIn = latestSkinMap?.checkIn

        let isFirstTimeUser = !appState.hasCompletedOnboarding || sortedSessions.isEmpty

        return SkinContext(
            latestScan: latestScan,
            baselineScan: baselineScan,
            previousScan: previousScan,
            scansLastSevenDays: scansLastSevenDays,
            skinProfile: appState.skinProfile,
            latestSkinMap: latestSkinMap,
            baselineSkinMap: baselineSkinMap,
            routineLogs: appState.routineLogs,
            routineChanges: appState.routineChanges,
            products: appState.currentProducts,
            weatherSnapshot: weather,
            airQualitySnapshot: airQuality,
            latestCheckIn: latestCheckIn,
            checkInHistory: allCheckIns,
            hasCompletedOnboarding: appState.hasCompletedOnboarding,
            isFirstTimeUser: isFirstTimeUser
        )
    }
}
