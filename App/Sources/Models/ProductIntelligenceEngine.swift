import Foundation

/// Rule-based product and routine intelligence engine.
/// Evaluates current products, routine consistency, and skin map changes
/// to detect risks, conflicts, and possible contributors.
enum ProductIntelligenceEngine {
    
    static func generateReport(
        products: [Product],
        routineLogs: [RoutineLogEntry],
        routineChanges: [RoutineChangeLogEntry],
        sessions: [ScanSession]
    ) -> ProductIntelligenceReport {
        let now = Date()
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        
        let activeProducts = products.filter(\.isActive)
        let weekChanges = routineChanges.filter { $0.date >= weekAgo }
        let weekLogs = routineLogs.filter { $0.date >= weekAgo }
        let weekSessions = sessions.filter { $0.createdAt >= weekAgo }
        
        var risks: [ProductRisk] = []
        var explanations: [String] = []
        var suggestedActions: [String] = []
        
        // Rule 1: Overuse of exfoliating actives
        let exfoliantRisks = evaluateExfoliantOveruse(products: activeProducts)
        risks.append(contentsOf: exfoliantRisks.risks)
        explanations.append(contentsOf: exfoliantRisks.explanations)
        suggestedActions.append(contentsOf: exfoliantRisks.actions)
        
        // Rule 2: Conflicting ingredients
        let conflictRisks = evaluateConflicts(products: activeProducts)
        risks.append(contentsOf: conflictRisks.risks)
        explanations.append(contentsOf: conflictRisks.explanations)
        suggestedActions.append(contentsOf: conflictRisks.actions)
        
        // Rule 3: New product introduction
        let newProductRisks = evaluateNewProducts(
            changes: weekChanges,
            products: activeProducts,
            sessions: weekSessions
        )
        risks.append(contentsOf: newProductRisks.risks)
        explanations.append(contentsOf: newProductRisks.explanations)
        suggestedActions.append(contentsOf: newProductRisks.actions)
        
        // Rule 4: Routine inconsistency
        let consistencyRisks = evaluateConsistency(logs: weekLogs)
        risks.append(contentsOf: consistencyRisks.risks)
        explanations.append(contentsOf: consistencyRisks.explanations)
        suggestedActions.append(contentsOf: consistencyRisks.actions)
        
        // Rule 5: Photosensitizing actives without SPF
        let spfRisks = evaluateSPFGap(products: activeProducts)
        risks.append(contentsOf: spfRisks.risks)
        explanations.append(contentsOf: spfRisks.explanations)
        suggestedActions.append(contentsOf: spfRisks.actions)
        
        // Rule 6: Correlate with skin map changes
        let correlationRisks = evaluateSkinMapCorrelation(
            sessions: weekSessions,
            changes: weekChanges,
            products: activeProducts
        )
        risks.append(contentsOf: correlationRisks.risks)
        explanations.append(contentsOf: correlationRisks.explanations)
        suggestedActions.append(contentsOf: correlationRisks.actions)
        
        // Deduplicate risks by title
        var seenTitles = Set<String>()
        risks = risks.filter {
            if seenTitles.contains($0.title) { return false }
            seenTitles.insert($0.title)
            return true
        }
        
        let confidence = computeConfidence(risks: risks, scanCount: weekSessions.count, logCount: weekLogs.count)
        
        return ProductIntelligenceReport(
            generatedAt: now,
            risks: risks,
            explanations: explanations,
            suggestedActions: suggestedActions,
            confidenceLevel: confidence
        )
    }
    
    // MARK: - Rule 1: Exfoliant Overuse
    
    private static func evaluateExfoliantOveruse(products: [Product]) -> RuleResult {
        let exfoliants = products.filter { $0.ingredientTags.contains(where: \.isExfoliant) }
        guard exfoliants.count > 1 else { return RuleResult() }
        
        let amExfoliants = exfoliants.filter { $0.period == .morning || $0.period == .both }
        let pmExfoliants = exfoliants.filter { $0.period == .evening || $0.period == .both }
        
        var risks: [ProductRisk] = []
        var explanations: [String] = []
        var actions: [String] = []
        
        if amExfoliants.count >= 2 {
            risks.append(ProductRisk(
                severity: .warning,
                title: CleraCopy.ProductIntelligence.multipleAMExfoliantsTitle,
                description: CleraCopy.ProductIntelligence.multipleAMExfoliantsBody(amExfoliants.count),
                affectedProductIDs: amExfoliants.map(\.id),
                relatedZones: nil
            ))
            explanations.append(CleraCopy.ProductIntelligence.multipleAMExfoliantsExplanation)
            actions.append(CleraCopy.ProductIntelligence.multipleAMExfoliantsAction)
        }
        
        if pmExfoliants.count >= 2 {
            risks.append(ProductRisk(
                severity: .warning,
                title: CleraCopy.ProductIntelligence.multiplePMExfoliantsTitle,
                description: CleraCopy.ProductIntelligence.multiplePMExfoliantsBody(pmExfoliants.count),
                affectedProductIDs: pmExfoliants.map(\.id),
                relatedZones: nil
            ))
            explanations.append(CleraCopy.ProductIntelligence.multiplePMExfoliantsExplanation)
            actions.append(CleraCopy.ProductIntelligence.multiplePMExfoliantsAction)
        }
        
        if exfoliants.count > 2 {
            risks.append(ProductRisk(
                severity: .caution,
                title: CleraCopy.ProductIntelligence.highExfoliantCountTitle,
                description: CleraCopy.ProductIntelligence.highExfoliantCountBody(exfoliants.count),
                affectedProductIDs: exfoliants.map(\.id),
                relatedZones: nil
            ))
            actions.append(CleraCopy.ProductIntelligence.highExfoliantCountAction)
        }
        
        return RuleResult(risks: risks, explanations: explanations, actions: actions)
    }
    
    // MARK: - Rule 2: Conflicting Ingredients
    
    private static func evaluateConflicts(products: [Product]) -> RuleResult {
        var risks: [ProductRisk] = []
        var explanations: [String] = []
        var actions: [String] = []
        
        let conflicts: [([IngredientTag], [IngredientTag], String)] = [
            ([.retinol], [.aha, .bha], CleraCopy.ProductIntelligence.retinolAcidsConflict),
            ([.vitaminC], [.aha, .bha], CleraCopy.ProductIntelligence.vitaminCAcidsConflict),
            ([.benzoylPeroxide], [.retinol], CleraCopy.ProductIntelligence.benzoylRetinolConflict),
            ([.benzoylPeroxide], [.vitaminC], CleraCopy.ProductIntelligence.benzoylVitaminCConflict),
        ]
        
        for (groupA, groupB, reason) in conflicts {
            let productsA = products.filter { $0.ingredientTags.contains(where: { groupA.contains($0) }) }
            let productsB = products.filter { $0.ingredientTags.contains(where: { groupB.contains($0) }) }
            
            for prodA in productsA {
                for prodB in productsB where prodA.id != prodB.id {
                    let sameRoutine = (prodA.period == .both || prodB.period == .both || prodA.period == prodB.period)
                    if sameRoutine {
                        risks.append(ProductRisk(
                            severity: .caution,
                            title: CleraCopy.ProductIntelligence.ingredientConflictTitle,
                            description: "\(prodA.name) and \(prodB.name) may not work well together. \(reason)",
                            affectedProductIDs: [prodA.id, prodB.id],
                            relatedZones: nil
                        ))
                        explanations.append(reason)
                        actions.append(CleraCopy.ProductIntelligence.ingredientConflictAction(prodA.name, prodB.name))
                    }
                }
            }
        }
        
        return RuleResult(risks: risks, explanations: explanations, actions: actions)
    }
    
    // MARK: - Rule 3: New Products
    
    private static func evaluateNewProducts(
        changes: [RoutineChangeLogEntry],
        products: [Product],
        sessions: [ScanSession]
    ) -> RuleResult {
        var risks: [ProductRisk] = []
        var explanations: [String] = []
        var actions: [String] = []
        
        let newAdditions = changes.filter { $0.changeType == .added }
        guard !newAdditions.isEmpty else { return RuleResult() }
        
        for change in newAdditions.prefix(3) {
            if let product = products.first(where: { $0.id == change.productId }) {
                let hasActives = product.ingredientTags.contains(where: \.isActiveTreatment)
                let severity: RiskSeverity = hasActives ? .caution : .info
                
                risks.append(ProductRisk(
                    severity: severity,
                    title: CleraCopy.ProductIntelligence.newProductTitle(product.name),
                    description: CleraCopy.ProductIntelligence.newProductBody(product.name),
                    affectedProductIDs: [product.id],
                    relatedZones: nil
                ))
                
                if hasActives {
                    explanations.append(CleraCopy.ProductIntelligence.newProductActiveExplanation(product.name))
                    actions.append(CleraCopy.ProductIntelligence.newProductActiveAction(product.name))
                }
            }
        }
        
        // Detect multiple new products at once
        if newAdditions.count > 1 {
            let newProductIDs = newAdditions.map(\.productId)
            risks.append(ProductRisk(
                severity: .warning,
                title: CleraCopy.ProductIntelligence.multipleNewProductsTitle,
                description: CleraCopy.ProductIntelligence.multipleNewProductsBody(newAdditions.count),
                affectedProductIDs: newProductIDs,
                relatedZones: nil
            ))
            explanations.append(CleraCopy.ProductIntelligence.multipleNewProductsExplanation)
            actions.append(CleraCopy.ProductIntelligence.multipleNewProductsAction)
        }
        
        return RuleResult(risks: risks, explanations: explanations, actions: actions)
    }
    
    // MARK: - Rule 4: Routine Consistency
    
    private static func evaluateConsistency(logs: [RoutineLogEntry]) -> RuleResult {
        guard logs.count >= 3 else { return RuleResult() }
        
        let adherence = Double(logs.filter(\.followedRoutine).count) / Double(max(logs.count, 1))
        
        if adherence >= 0.7 {
            return RuleResult()
        }
        
        return RuleResult(
            risks: [ProductRisk(
                severity: .caution,
                title: CleraCopy.ProductIntelligence.routineInconsistencyTitle,
                description: CleraCopy.ProductIntelligence.routineInconsistencyBody(Int(adherence * 100)),
                affectedProductIDs: [],
                relatedZones: nil
            )],
            explanations: [CleraCopy.ProductIntelligence.routineInconsistencyExplanation],
            actions: [CleraCopy.ProductIntelligence.routineInconsistencyAction]
        )
    }
    
    // MARK: - Rule 5: SPF Gap
    
    private static func evaluateSPFGap(products: [Product]) -> RuleResult {
        let hasSPF = products.contains { $0.ingredientTags.contains(.spf) || $0.category == .sunscreen }
        let hasPhotosensitizers = products.contains { $0.ingredientTags.contains(where: \.isPhotosensitizing) }
        
        if hasPhotosensitizers && !hasSPF {
            return RuleResult(
                risks: [ProductRisk(
                    severity: .warning,
                    title: CleraCopy.ProductIntelligence.spfGapTitle,
                    description: CleraCopy.ProductIntelligence.spfGapBody,
                    affectedProductIDs: products.filter { $0.ingredientTags.contains(where: \.isPhotosensitizing) }.map(\.id),
                    relatedZones: nil
                )],
                explanations: [CleraCopy.ProductIntelligence.spfGapExplanation],
                actions: [CleraCopy.ProductIntelligence.spfGapAction]
            )
        }
        
        return RuleResult()
    }
    
    // MARK: - Rule 6: Skin Map Correlation
    
    private static func evaluateSkinMapCorrelation(
        sessions: [ScanSession],
        changes: [RoutineChangeLogEntry],
        products: [Product]
    ) -> RuleResult {
        guard sessions.count >= 2, !changes.isEmpty else { return RuleResult() }
        
        let sorted = sessions.sorted(by: { $0.createdAt < $1.createdAt })
        guard let first = sorted.first?.skinMap, let latest = sorted.last?.skinMap else { return RuleResult() }
        
        var risks: [ProductRisk] = []
        var explanations: [String] = []
        var actions: [String] = []
        
        // Find worsening zones
        for zone in latest.zones {
            guard let firstZone = first.zones.first(where: { $0.zoneType == zone.zoneType }) else { continue }
            
            let metrics: [(String, ZoneSeverity, ZoneSeverity)] = [
                ("breakouts", firstZone.status.breakouts, zone.status.breakouts),
                ("redness", firstZone.status.redness, zone.status.redness),
                ("dryness", firstZone.status.dryness, zone.status.dryness),
                ("irritation", firstZone.status.irritation, zone.status.irritation)
            ]
            
            for (metricName, firstSev, latestSev) in metrics {
                if latestSev.numericScore > firstSev.numericScore {
                    // Zone worsened — check if new products were added
                    let newProducts = changes.filter { $0.changeType == .added }
                    if !newProducts.isEmpty {
                        let productNames = newProducts.compactMap { change in
                            products.first(where: { $0.id == change.productId })?.name
                        }.joined(separator: ", ")
                        
                        risks.append(ProductRisk(
                            severity: .caution,
                            title: CleraCopy.ProductIntelligence.skinMapCorrelationTitle(zone.zoneType.displayName, metricName),
                            description: CleraCopy.ProductIntelligence.skinMapCorrelationBody(zone.zoneType.displayName, metricName),
                            affectedProductIDs: newProducts.map(\.productId),
                            relatedZones: [zone.zoneType]
                        ))
                        explanations.append(CleraCopy.ProductIntelligence.skinMapCorrelationExplanation)
                        actions.append(CleraCopy.ProductIntelligence.skinMapCorrelationAction(zone.zoneType.displayName, productNames))
                    }
                }
            }
        }
        
        return RuleResult(risks: risks, explanations: explanations, actions: actions)
    }
    
    // MARK: - Helpers
    
    private struct RuleResult {
        var risks: [ProductRisk] = []
        var explanations: [String] = []
        var actions: [String] = []
    }
    
    private static func computeConfidence(risks: [ProductRisk], scanCount: Int, logCount: Int) -> InsightConfidence {
        if scanCount < 2 || logCount < 3 { return .low }
        let warnings = risks.filter { $0.severity == .warning }.count
        if warnings > 0 && scanCount >= 3 { return .moderate }
        if scanCount >= 5 && logCount >= 7 { return .high }
        return .moderate
    }
    
}
