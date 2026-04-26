import Foundation

/// Deterministic change detection engine that compares skin maps across time
/// to identify per-zone, per-metric trends. Uses both scan-derived severities
/// and user-reported check-in data.
enum ChangeDetectionEngine {
    
    // MARK: - Public API
    
    /// Compare the two most recent skin maps.
    static func compareLatestPair(from skinMaps: [SkinMap]) -> ChangeDetectionResult {
        guard skinMaps.count >= 2 else {
            return ChangeDetectionResult(generatedAt: .now, mode: .latestPair, zoneChanges: [])
        }
        let sorted = skinMaps.sorted(by: { $0.date < $1.date })
        let previous = sorted[sorted.count - 2]
        let latest = sorted[sorted.count - 1]
        
        let changes = computeZoneChanges(
            from: previous,
            to: latest,
            mode: .latestPair,
            checkIn: latest.checkIn
        )
        
        return ChangeDetectionResult(generatedAt: .now, mode: .latestPair, zoneChanges: changes)
    }
    
    /// Rolling trend across the last 3 scans.
    static func rolling3ScanTrend(from skinMaps: [SkinMap]) -> ChangeDetectionResult {
        guard skinMaps.count >= 3 else {
            return compareLatestPair(from: skinMaps)
        }
        let sorted = skinMaps.sorted(by: { $0.date < $1.date })
        let window = Array(sorted.suffix(3))
        let earliest = window[0]
        let latest = window[2]
        
        let changes = computeZoneChanges(
            from: earliest,
            to: latest,
            mode: .rolling3Scan,
            checkIn: latest.checkIn
        )
        
        return ChangeDetectionResult(generatedAt: .now, mode: .rolling3Scan, zoneChanges: changes)
    }
    
    /// 7-day trend: compare the map from ~7 days ago to the latest.
    static func sevenDayTrend(from skinMaps: [SkinMap]) -> ChangeDetectionResult {
        guard skinMaps.count >= 2 else {
            return ChangeDetectionResult(generatedAt: .now, mode: .sevenDay, zoneChanges: [])
        }
        let sorted = skinMaps.sorted(by: { $0.date < $1.date })
        let latest = sorted.last!
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: latest.date) ?? latest.date
        
        // Find the map closest to 7 days ago
        let historical = sorted
            .filter { $0.date <= weekAgo }
            .last ?? sorted.first!
        
        let changes = computeZoneChanges(
            from: historical,
            to: latest,
            mode: .sevenDay,
            checkIn: latest.checkIn
        )
        
        return ChangeDetectionResult(generatedAt: .now, mode: .sevenDay, zoneChanges: changes)
    }
    
    /// Run all three modes and return a composite result.
    /// Used by downstream engines that need a single source of truth.
    static func compositeResult(from skinMaps: [SkinMap]) -> ChangeDetectionResult {
        let pairResult = compareLatestPair(from: skinMaps)
        let rollingResult = rolling3ScanTrend(from: skinMaps)
        let sevenDayResult = sevenDayTrend(from: skinMaps)
        
        var merged: [ZoneChange] = []
        let allZones = ZoneType.allCases
        let allMetrics = ["breakouts", "redness", "dryness", "texture", "congestion", "irritation"]
        
        for zone in allZones {
            for metric in allMetrics {
                let pair = pairResult.zoneChanges.first { $0.zone == zone && $0.metric == metric }
                let rolling = rollingResult.zoneChanges.first { $0.zone == zone && $0.metric == metric }
                let sevenDay = sevenDayResult.zoneChanges.first { $0.zone == zone && $0.metric == metric }
                
                let composite = mergeChanges(
                    zone: zone,
                    metric: metric,
                    pair: pair,
                    rolling: rolling,
                    sevenDay: sevenDay
                )
                merged.append(composite)
            }
        }
        
        return ChangeDetectionResult(generatedAt: .now, mode: .latestPair, zoneChanges: merged)
    }
    
    /// Updates a SkinMap's ZoneStatus trend fields in-place using the latest pair comparison.
    static func updateTrends(on skinMap: inout SkinMap, using skinMapHistory: [SkinMap]) {
        let result = compareLatestPair(from: skinMapHistory)
        
        for i in skinMap.zones.indices {
            let zoneType = skinMap.zones[i].zoneType
            let metrics = [
                ("breakouts", \ZoneStatus.breakoutsTrend),
                ("redness", \ZoneStatus.rednessTrend),
                ("dryness", \ZoneStatus.drynessTrend),
                ("texture", \ZoneStatus.textureTrend),
                ("congestion", \ZoneStatus.congestionTrend),
                ("irritation", \ZoneStatus.irritationTrend)
            ]
            
            for (metricName, keyPath) in metrics {
                if let change = result.zoneChanges.first(where: { $0.zone == zoneType && $0.metric == metricName }) {
                    skinMap.zones[i].status[keyPath: keyPath] = change.direction.zoneTrend
                }
            }
        }
    }
    
    // MARK: - Core Computation
    
    private static func computeZoneChanges(
        from previous: SkinMap,
        to latest: SkinMap,
        mode: DetectionMode,
        checkIn: SkinMapCheckIn?
    ) -> [ZoneChange] {
        var changes: [ZoneChange] = []
        
        for zone in latest.zones {
            guard let prevZone = previous.zones.first(where: { $0.zoneType == zone.zoneType }) else { continue }
            
            let metrics: [(String, ZoneSeverity, ZoneSeverity, (SkinMapCheckIn?) -> Bool)] = [
                ("breakouts", prevZone.status.breakouts, zone.status.breakouts, { $0?.hadBreakouts ?? false }),
                ("redness", prevZone.status.redness, zone.status.redness, { _ in false }),
                ("dryness", prevZone.status.dryness, zone.status.dryness, { $0?.hadDryness ?? false }),
                ("texture", prevZone.status.texture, zone.status.texture, { _ in false }),
                ("congestion", prevZone.status.congestion, zone.status.congestion, { _ in false }),
                ("irritation", prevZone.status.irritation, zone.status.irritation, { $0?.hadIrritation ?? false })
            ]
            
            for (metricName, prevSeverity, latestSeverity, checkInFlag) in metrics {
                let delta = severityScore(latestSeverity) - severityScore(prevSeverity)
                let direction: ChangeDirection
                var magnitude: ChangeMagnitude
                
                if delta > 0 {
                    direction = .increasing
                    magnitude = delta >= 2 ? .significant : .moderate
                } else if delta < 0 {
                    direction = .decreasing
                    magnitude = abs(delta) >= 2 ? .significant : .moderate
                } else {
                    direction = .stable
                    magnitude = .slight
                }
                
                // Adjust magnitude for slight changes
                if abs(delta) == 1 && magnitude != .slight {
                    magnitude = .slight
                }
                
                var confidence = baseConfidence(mode: mode, hasCheckIn: checkIn != nil)
                var explanation = explanationFor(
                    zone: zone.zoneType,
                    metric: metricName,
                    direction: direction,
                    magnitude: magnitude,
                    prev: prevSeverity,
                    latest: latestSeverity,
                    mode: mode
                )
                
                // Incorporate check-in data
                let reportedIssue = checkInFlag(checkIn)
                if reportedIssue {
                    if direction == .increasing || direction == .stable {
                        confidence = min(confidence + 0.15, 0.95)
                        explanation += CleraCopy.ChangeDetection.checkInSupports
                    } else {
                        confidence = max(confidence - 0.1, 0.3)
                        explanation += CleraCopy.ChangeDetection.checkInMismatch
                    }
                }
                
                changes.append(ZoneChange(
                    zone: zone.zoneType,
                    metric: metricName,
                    direction: direction,
                    magnitude: magnitude,
                    confidence: confidence,
                    explanation: explanation,
                    comparedMapIDs: [previous.id, latest.id]
                ))
            }
        }
        
        return changes
    }
    
    // MARK: - Merge Logic
    
    private static func mergeChanges(
        zone: ZoneType,
        metric: String,
        pair: ZoneChange?,
        rolling: ZoneChange?,
        sevenDay: ZoneChange?
    ) -> ZoneChange {
        let all = [pair, rolling, sevenDay].compactMap { $0 }
        guard !all.isEmpty else {
            return ZoneChange(
                zone: zone,
                metric: metric,
                direction: .stable,
                magnitude: .slight,
                confidence: 0.3,
                explanation: CleraCopy.ChangeDetection.notEnoughData,
                comparedMapIDs: []
            )
        }
        
        // Majority vote for direction
        let increasingCount = all.filter { $0.direction == .increasing }.count
        let decreasingCount = all.filter { $0.direction == .decreasing }.count
        let stableCount = all.filter { $0.direction == .stable }.count
        
        let direction: ChangeDirection
        if increasingCount > decreasingCount && increasingCount > stableCount {
            direction = .increasing
        } else if decreasingCount > increasingCount && decreasingCount > stableCount {
            direction = .decreasing
        } else {
            direction = .stable
        }
        
        // Take max magnitude among agreeing directions
        let agreeing = all.filter { $0.direction == direction }
        let magnitude = agreeing.map { magnitudeScore($0.magnitude) }.max() ?? 0
        let maxMagnitude: ChangeMagnitude = magnitude >= 3 ? .significant : magnitude >= 2 ? .moderate : .slight
        
        // Average confidence
        let avgConfidence = all.map(\.confidence).reduce(0, +) / Double(all.count)
        
        // Build composite explanation
        var explanation = ""
        if let pair = pair {
            explanation += "\(CleraCopy.ChangeDetection.latestScanPrefix) \(pair.direction.displayName.lowercased()). "
        }
        if let rolling = rolling, rolling.direction != pair?.direction {
            explanation += "\(CleraCopy.ChangeDetection.threeScanPrefix) \(rolling.direction.displayName.lowercased()). "
        }
        if let sevenDay = sevenDay, sevenDay.direction != pair?.direction {
            explanation += "\(CleraCopy.ChangeDetection.sevenDayPrefix) \(sevenDay.direction.displayName.lowercased()). "
        }
        if explanation.isEmpty {
            explanation = "\(CleraCopy.ChangeDetection.allComparisonsAgree) \(direction.displayName.lowercased())."
        }
        
        let mapIDs = all.flatMap(\.comparedMapIDs).uniqued()
        
        return ZoneChange(
            zone: zone,
            metric: metric,
            direction: direction,
            magnitude: maxMagnitude,
            confidence: avgConfidence,
            explanation: explanation.trimmingCharacters(in: .whitespaces),
            comparedMapIDs: mapIDs
        )
    }
    
    // MARK: - Helpers
    
    private static func baseConfidence(mode: DetectionMode, hasCheckIn: Bool) -> Double {
        var base: Double
        switch mode {
        case .latestPair: base = 0.75
        case .rolling3Scan: base = 0.80
        case .sevenDay: base = 0.70
        }
        if hasCheckIn { base += 0.05 }
        return min(base, 0.95)
    }
    
    private static func explanationFor(
        zone: ZoneType,
        metric: String,
        direction: ChangeDirection,
        magnitude: ChangeMagnitude,
        prev: ZoneSeverity,
        latest: ZoneSeverity,
        mode: DetectionMode
    ) -> String {
        let modeText = mode == .latestPair ? "since your last scan" :
                       mode == .rolling3Scan ? "over the last 3 scans" :
                       "over the past 7 days"
        
        switch direction {
        case .increasing:
            return CleraCopy.ChangeDetection.increasedExplanation(
                zone: zone.displayName, metric: metric,
                magnitude: magnitude.displayName.lowercased(), mode: modeText,
                from: prev.displayName.lowercased(), to: latest.displayName.lowercased()
            )
        case .decreasing:
            return CleraCopy.ChangeDetection.decreasedExplanation(
                zone: zone.displayName, metric: metric,
                magnitude: magnitude.displayName.lowercased(), mode: modeText,
                from: prev.displayName.lowercased(), to: latest.displayName.lowercased()
            )
        case .stable:
            return CleraCopy.ChangeDetection.stableExplanation(
                zone: zone.displayName, metric: metric, mode: modeText,
                level: latest.displayName.lowercased()
            )
        }
    }
    
    private static func severityScore(_ severity: ZoneSeverity) -> Int {
        switch severity {
        case .none: return 0
        case .low: return 1
        case .moderate: return 2
        case .high: return 3
        }
    }
    
    private static func magnitudeScore(_ magnitude: ChangeMagnitude) -> Int {
        switch magnitude {
        case .slight: return 1
        case .moderate: return 2
        case .significant: return 3
        }
    }
}

// MARK: - Array Helpers

private extension Array where Element == UUID {
    func uniqued() -> [UUID] {
        var seen = Set<UUID>()
        return filter { seen.insert($0).inserted }
    }
}
