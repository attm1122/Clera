import Foundation

/// Rule-based daily skincare plan generator.
/// Creates an AM or PM routine tailored to the user's current skin state,
/// routine adherence, product inventory, and recent changes.
enum DailyCopilotEngine {
    
    static func generatePlan(
        for period: PlanPeriod,
        currentSkinMap: SkinMap,
        weeklyInsight: WeeklyInsight?,
        productIntelligence: ProductIntelligenceReport?,
        products: [Product],
        routineLogs: [RoutineLogEntry],
        routineChanges: [RoutineChangeLogEntry],
        latestCheckIn: SkinMapCheckIn?
    ) -> DailyPlan {
        let now = Date()
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        let threeDaysAgo = calendar.date(byAdding: .day, value: -3, to: now) ?? now
        
        let activeProducts = products.filter(\.isActive)
        let periodProducts = activeProducts.filter {
            $0.period == .both ||
            ($0.period == .morning && period == .morning) ||
            ($0.period == .evening && period == .evening)
        }.sorted { $0.sortOrder < $1.sortOrder }
        
        let weekLogs = routineLogs.filter { $0.date >= weekAgo }
        let adherence = calculateAdherence(logs: weekLogs)
        let recentChanges = routineChanges.filter { $0.date >= threeDaysAgo && $0.changeType == .added }
        
        // Assess skin state
        let skinState = assessSkinState(skinMap: currentSkinMap, checkIn: latestCheckIn)
        
        // Determine strategy
        let strategy = determineStrategy(
            period: period,
            skinState: skinState,
            adherence: adherence,
            recentChanges: recentChanges,
            productIntelligence: productIntelligence,
            weeklyInsight: weeklyInsight
        )
        
        // Build recommended steps
        let steps = buildSteps(
            period: period,
            strategy: strategy,
            periodProducts: periodProducts,
            skinState: skinState,
            recentChanges: recentChanges
        )
        
        // Build avoid list
        let avoid = buildAvoidList(
            period: period,
            strategy: strategy,
            periodProducts: periodProducts,
            activeProducts: activeProducts,
            skinState: skinState,
            productIntelligence: productIntelligence
        )
        
        // Build reasoning
        let reasoning = buildReasoning(
            strategy: strategy,
            skinState: skinState,
            adherence: adherence,
            recentChanges: recentChanges,
            weeklyInsight: weeklyInsight
        )
        
        let confidence = computeConfidence(
            strategy: strategy,
            skinState: skinState,
            adherence: adherence,
            hasCheckIn: latestCheckIn != nil
        )
        
        return DailyPlan(
            generatedAt: now,
            period: period,
            focus: strategy.focus,
            recommendedSteps: steps,
            avoidSteps: avoid,
            reasoning: reasoning,
            confidenceLevel: confidence
        )
    }
    
    // MARK: - Skin State Assessment
    
    private struct SkinState {
        var hasIrritation = false
        var hasDryness = false
        var hasBreakouts = false
        var hasIncreasingRedness = false
        var worseningZones: [(ZoneType, String)] = []
        var improvingZones: [(ZoneType, String)] = []
        var overallTrend: ZoneTrend = .unknown
    }
    
    private static func assessSkinState(skinMap: SkinMap, checkIn: SkinMapCheckIn?) -> SkinState {
        var state = SkinState()
        
        // Check latest map
        for zone in skinMap.zones {
            let metrics = zone.status.metrics.filter { $0.severity != .none }
            let worsening = metrics.filter { $0.trend == .worsening }
            let improving = metrics.filter { $0.trend == .improving }
            
            if !worsening.isEmpty {
                state.worseningZones.append((zone.zoneType, worsening.map(\.label).joined(separator: ", ")))
            }
            if !improving.isEmpty {
                state.improvingZones.append((zone.zoneType, improving.map(\.label).joined(separator: ", ")))
            }
        }
        
        state.overallTrend = {
            let w = state.worseningZones.count
            let i = state.improvingZones.count
            if w > i { return .worsening }
            if i > w { return .improving }
            return .stable
        }()
        
        // Check latest check-in
        if let checkIn = checkIn {
            state.hasIrritation = checkIn.hadIrritation
            state.hasDryness = checkIn.hadDryness
            state.hasBreakouts = checkIn.hadBreakouts
        }
        
        // Check for increasing redness from map
        state.hasIncreasingRedness = skinMap.zones.contains {
            $0.status.rednessTrend == .worsening ||
            ($0.status.redness == .moderate || $0.status.redness == .high)
        }
        
        return state
    }
    
    // MARK: - Strategy
    
    private struct Strategy {
        var focus: String
        var simplify: Bool
        var skipActives: Bool
        var introduceSlowly: Bool
        var prioritizeBarrier: Bool
    }
    
    private static func determineStrategy(
        period: PlanPeriod,
        skinState: SkinState,
        adherence: Double,
        recentChanges: [RoutineChangeLogEntry],
        productIntelligence: ProductIntelligenceReport?,
        weeklyInsight: WeeklyInsight?
    ) -> Strategy {
        // Priority 1: Skin distress signals
        if skinState.hasIrritation || skinState.hasIncreasingRedness {
            return Strategy(
                focus: CleraCopy.DailyCopilot.focusSoothe,
                simplify: true,
                skipActives: true,
                introduceSlowly: false,
                prioritizeBarrier: true
            )
        }
        
        // Priority 2: New product just added (< 3 days)
        if !recentChanges.isEmpty {
            return Strategy(
                focus: CleraCopy.DailyCopilot.focusWatch,
                simplify: true,
                skipActives: recentChanges.count > 1,
                introduceSlowly: true,
                prioritizeBarrier: false
            )
        }
        
        // Priority 3: Breakouts or dryness
        if skinState.hasBreakouts || skinState.hasDryness {
            return Strategy(
                focus: skinState.hasDryness ? CleraCopy.DailyCopilot.focusHydrate : CleraCopy.DailyCopilot.focusSimple,
                simplify: true,
                skipActives: skinState.hasDryness,
                introduceSlowly: false,
                prioritizeBarrier: skinState.hasDryness
            )
        }
        
        // Priority 4: Worsening trend
        if skinState.overallTrend == .worsening {
            return Strategy(
                focus: CleraCopy.DailyCopilot.focusReduce,
                simplify: true,
                skipActives: true,
                introduceSlowly: false,
                prioritizeBarrier: true
            )
        }
        
        // Priority 5: Low adherence
        if adherence < 0.4 {
            return Strategy(
                focus: CleraCopy.DailyCopilot.focusTrack,
                simplify: true,
                skipActives: false,
                introduceSlowly: false,
                prioritizeBarrier: false
            )
        }
        
        // Priority 6: Product intelligence warnings
        if let intel = productIntelligence {
            let hasConflict = intel.risks.contains { $0.severity == .warning && ($0.title.contains("conflict") || $0.title.contains("Multiple")) }
            if hasConflict {
                return Strategy(
                    focus: CleraCopy.DailyCopilot.focusSimplifyActives,
                    simplify: true,
                    skipActives: true,
                    introduceSlowly: false,
                    prioritizeBarrier: false
                )
            }
        }
        
        // Default: maintain
        return Strategy(
            focus: CleraCopy.DailyCopilot.focusMaintain,
            simplify: false,
            skipActives: false,
            introduceSlowly: false,
            prioritizeBarrier: false
        )
    }
    
    // MARK: - Build Steps
    
    private static func buildSteps(
        period: PlanPeriod,
        strategy: Strategy,
        periodProducts: [Product],
        skinState: SkinState,
        recentChanges: [RoutineChangeLogEntry]
    ) -> [PlanStep] {
        var steps: [PlanStep] = []
        var usedProductIDs = Set<UUID>()
        var order = 0
        
        func addStep(for category: ProductCategory, instruction: String? = nil, optional: Bool = false) {
            if let product = periodProducts.first(where: { $0.category == category && !usedProductIDs.contains($0.id) }) {
                steps.append(PlanStep(
                    order: order,
                    category: category,
                    productID: product.id,
                    productName: product.name,
                    instruction: instruction,
                    isOptional: optional
                ))
                usedProductIDs.insert(product.id)
                order += 1
            }
        }
        
        // Step 1: Cleanser (always)
        addStep(for: .cleanser)
        
        // Step 2: Treatment / Serum
        if !strategy.skipActives {
            let actives = periodProducts.filter {
                ($0.category == .serum || $0.category == .treatment) &&
                !usedProductIDs.contains($0.id)
            }
            
            if strategy.introduceSlowly && recentChanges.count == 1 {
                // Only use the new product
                if let newProduct = actives.first(where: { p in
                    recentChanges.contains(where: { $0.productId == p.id })
                }) {
                    steps.append(PlanStep(
                        order: order,
                        category: newProduct.category,
                        productID: newProduct.id,
                        productName: newProduct.name,
                        instruction: CleraCopy.DailyCopilot.newProductInstruction,
                        isOptional: false
                    ))
                    usedProductIDs.insert(newProduct.id)
                    order += 1
                }
            } else if !strategy.simplify {
                // Use up to 1 active to avoid overuse
                if let active = actives.first {
                    steps.append(PlanStep(
                        order: order,
                        category: active.category,
                        productID: active.id,
                        productName: active.name,
                        instruction: nil,
                        isOptional: false
                    ))
                    usedProductIDs.insert(active.id)
                    order += 1
                }
            }
        }
        
        // Step 3: Moisturizer (always, especially if barrier priority)
        let moisturizerInstruction = strategy.prioritizeBarrier ? CleraCopy.DailyCopilot.barrierMoisturizerInstruction : nil
        addStep(for: .moisturizer, instruction: moisturizerInstruction)
        
        // Step 4: SPF (morning only)
        if period == .morning {
            addStep(for: .sunscreen, instruction: CleraCopy.DailyCopilot.spfInstruction)
        }
        
        return steps
    }
    
    // MARK: - Avoid List
    
    private static func buildAvoidList(
        period: PlanPeriod,
        strategy: Strategy,
        periodProducts: [Product],
        activeProducts: [Product],
        skinState: SkinState,
        productIntelligence: ProductIntelligenceReport?
    ) -> [String] {
        var avoid: [String] = []
        
        if strategy.skipActives {
            let activeNames = periodProducts
                .filter { $0.ingredientTags.contains(where: \.isActiveTreatment) }
                .map(\.name)
            if !activeNames.isEmpty {
                avoid.append("\(CleraCopy.DailyCopilot.avoidActivesPrefix) \(activeNames.joined(separator: ", "))")
            }
        }
        
        if strategy.introduceSlowly {
            let nonNewActives = periodProducts.filter {
                $0.ingredientTags.contains(where: \.isActiveTreatment)
            }
            if nonNewActives.count > 1 {
                avoid.append(CleraCopy.DailyCopilot.avoidMultipleActives)
            }
        }
        
        if skinState.hasIrritation || skinState.hasIncreasingRedness {
            avoid.append(CleraCopy.DailyCopilot.avoidSensitivity)
        }
        
        if period == .morning {
            let retinolProducts = activeProducts.filter { $0.ingredientTags.contains(.retinol) }
            if !retinolProducts.isEmpty {
                avoid.append(CleraCopy.DailyCopilot.avoidMorningRetinol)
            }
        }
        
        if let intel = productIntelligence {
            for risk in intel.risks where risk.severity == .warning {
                if risk.title.contains("exfoliant") {
                    avoid.append(CleraCopy.DailyCopilot.avoidExfoliation)
                }
            }
        }
        
        return avoid
    }
    
    // MARK: - Reasoning
    
    private static func buildReasoning(
        strategy: Strategy,
        skinState: SkinState,
        adherence: Double,
        recentChanges: [RoutineChangeLogEntry],
        weeklyInsight: WeeklyInsight?
    ) -> [String] {
        var reasoning: [String] = []
        
        reasoning.append(CleraCopy.DailyCopilot.reasoningBase)
        
        if skinState.hasIrritation {
            reasoning.append(CleraCopy.DailyCopilot.reasoningIrritation)
        }
        if skinState.hasDryness {
            reasoning.append(CleraCopy.DailyCopilot.reasoningDryness)
        }
        if skinState.hasBreakouts {
            reasoning.append(CleraCopy.DailyCopilot.reasoningBreakouts)
        }
        
        if !recentChanges.isEmpty {
            reasoning.append(CleraCopy.DailyCopilot.reasoningNewProduct)
        }
        
        if skinState.overallTrend == .worsening {
            reasoning.append(CleraCopy.DailyCopilot.reasoningWorsening)
        } else if skinState.overallTrend == .improving {
            reasoning.append(CleraCopy.DailyCopilot.reasoningImproving)
        }
        
        if adherence < 0.4 {
            reasoning.append(CleraCopy.DailyCopilot.reasoningLowAdherence)
        }
        
        if strategy.skipActives {
            reasoning.append(CleraCopy.DailyCopilot.reasoningSkipActives)
        }
        
        if let insight = weeklyInsight {
            if insight.confidenceLevel == .low {
                reasoning.append(CleraCopy.DailyCopilot.reasoningLowConfidence)
            }
        }
        
        return reasoning
    }
    
    // MARK: - Confidence
    
    private static func computeConfidence(
        strategy: Strategy,
        skinState: SkinState,
        adherence: Double,
        hasCheckIn: Bool
    ) -> InsightConfidence {
        if !hasCheckIn { return .low }
        if skinState.hasIrritation && skinState.hasBreakouts { return .low }
        if strategy.skipActives && skinState.overallTrend == .worsening { return .moderate }
        if adherence < 0.3 { return .low }
        if adherence >= 0.7 && !skinState.hasIrritation && !skinState.hasDryness { return .high }
        return .moderate
    }
    
    // MARK: - Helpers
    
    private static func calculateAdherence(logs: [RoutineLogEntry]) -> Double {
        let expected = 14.0
        guard !logs.isEmpty else { return 0 }
        let followed = Double(logs.filter(\.followedRoutine).count)
        return min(followed / expected, 1.0)
    }
    
    static func currentPeriod() -> PlanPeriod {
        let hour = Calendar.current.component(.hour, from: Date())
        return hour >= 5 && hour < 17 ? .morning : .evening
    }
}
