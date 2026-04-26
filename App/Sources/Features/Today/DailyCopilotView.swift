import SwiftUI

struct DailyCopilotView: View {
    let plan: DailyPlan
    var failures: [SessionFailure] = []
    @Environment(AppModel.self) private var appModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: CleraSpacing.lg) {
                    header
                    focusCard
                    stepsSection
                    avoidSection
                    reasoningSection
                    failuresSection
                    confidenceCard
                    Spacer(minLength: CleraSpacing.xl)
                }
                .padding(.horizontal, CleraSpacing.lg)
                .padding(.top, CleraSpacing.lg)
            }
            .scrollIndicators(.hidden)
            .background(CleraColor.background)
            .navigationTitle(plan.period.displayName)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(CleraCopy.DailyCopilot.done) { dismiss() }
                        .foregroundStyle(CleraColor.accent)
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(plan.generatedAt.formatted(date: .long, time: .omitted))
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(CleraColor.textSecondary)
                .textCase(.uppercase)
                .tracking(0.8)
            Text(CleraCopy.DailyCopilot.viewTitle)
                .font(.system(size: 15))
                .foregroundStyle(CleraColor.textSecondary)
        }
    }

    private var focusCard: some View {
        CleraCard {
            HStack(spacing: CleraSpacing.md) {
                Image(systemName: focusIcon)
                    .font(.system(size: 28))
                    .foregroundStyle(focusColor)
                    .frame(width: 52, height: 52)
                    .background(
                        Circle()
                            .fill(focusColor.opacity(0.1))
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(CleraCopy.DailyCopilot.focusLabel)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(CleraColor.textSecondary)
                    Text(plan.focus)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(focusColor)
                }

                Spacer()
            }
        }
    }

    private var stepsSection: some View {
        VStack(alignment: .leading, spacing: CleraSpacing.md) {
            Text(CleraCopy.DailyCopilot.whatToUse)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(CleraColor.textPrimary)

            if plan.recommendedSteps.isEmpty {
                Text(CleraCopy.DailyCopilot.noProductsAssigned)
                    .font(.system(size: 14))
                    .foregroundStyle(CleraColor.textSecondary)
            } else {
                ForEach(plan.recommendedSteps.sorted(by: { $0.order < $1.order })) { step in
                    stepCard(step: step)
                }
            }
        }
    }

    private func stepCard(step: PlanStep) -> some View {
        let product = appModel.currentProducts.first(where: { $0.id == step.productID })
        let hasTags = product?.ingredientTags.isEmpty == false

        return CleraCard {
            HStack(spacing: CleraSpacing.md) {
                ZStack {
                    Circle()
                        .fill(CleraColor.accentSoft)
                        .frame(width: 36, height: 36)
                    Text("\(step.order + 1)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(CleraColor.accent)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(step.productName ?? step.category.displayName)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(CleraColor.textPrimary)
                        if step.isOptional {
                            Text(CleraCopy.DailyCopilot.optionalLabel)
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(CleraColor.textSecondary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule(style: .continuous)
                                        .fill(CleraColor.border.opacity(0.5))
                                )
                        }
                    }

                    if let instruction = step.instruction {
                        Text(instruction)
                            .font(.system(size: 13))
                            .foregroundStyle(CleraColor.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    if hasTags, let product = product {
                        FlowLayout(spacing: 6) {
                            ForEach(product.ingredientTags, id: \.self) { tag in
                                Text(tag.displayName)
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundStyle(Color(hex: tag.color))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(
                                        Capsule(style: .continuous)
                                            .fill(Color(hex: tag.color).opacity(0.12))
                                    )
                            }
                        }
                    }
                }

                Spacer()
            }
        }
    }

    private var avoidSection: some View {
        VStack(alignment: .leading, spacing: CleraSpacing.md) {
            Text(CleraCopy.DailyCopilot.whatToAvoid)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(CleraColor.textPrimary)

            if plan.avoidSteps.isEmpty {
                Text(CleraCopy.DailyCopilot.nothingToAvoid)
                    .font(.system(size: 14))
                    .foregroundStyle(CleraColor.textSecondary)
            } else {
                ForEach(plan.avoidSteps.indices, id: \.self) { index in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(Color(hex: 0xC75B39).opacity(0.7))
                        Text(plan.avoidSteps[index])
                            .font(.system(size: 14))
                            .foregroundStyle(CleraColor.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }

    private var reasoningSection: some View {
        VStack(alignment: .leading, spacing: CleraSpacing.md) {
            Text(CleraCopy.DailyCopilot.whyThisPlan)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(CleraColor.textPrimary)

            ForEach(plan.reasoning.indices, id: \.self) { index in
                HStack(alignment: .top, spacing: 8) {
                    Text("\(index + 1)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(CleraColor.accent)
                        .frame(width: 20, height: 20)
                        .background(Circle().fill(CleraColor.accentSoft))
                    Text(plan.reasoning[index])
                        .font(.system(size: 14))
                        .foregroundStyle(CleraColor.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 4)
            }
        }
    }

    private var failuresSection: some View {
        let unresolved = failures.filter { !$0.isResolved }
        guard !unresolved.isEmpty else { return AnyView(EmptyView()) }
        return AnyView(
            VStack(alignment: .leading, spacing: CleraSpacing.md) {
                Text(CleraCopy.DailyCopilot.notesLabel)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(CleraColor.textPrimary)
                ForEach(unresolved.prefix(3)) { failure in
                    failureCard(failure: failure)
                }
            }
        )
    }

    private func failureCard(failure: SessionFailure) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: failure.canContinue ? "exclamationmark.triangle.fill" : "xmark.octagon.fill")
                .font(.system(size: 14))
                .foregroundStyle(failure.canContinue ? Color(hex: 0xD4A017) : Color(hex: 0xC75B39))
            VStack(alignment: .leading, spacing: 2) {
                Text(failure.userMessage)
                    .font(.system(size: 14))
                    .foregroundStyle(CleraColor.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                if !failure.recommendedAction.isEmpty {
                    Text(failure.recommendedAction)
                        .font(.system(size: 12))
                        .foregroundStyle(CleraColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var confidenceCard: some View {
        CleraCard {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(CleraCopy.DailyCopilot.confidenceLabel)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(CleraColor.textSecondary)
                    Text(plan.confidenceLevel.displayName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(confidenceColor(plan.confidenceLevel))
                }
                Spacer()
                confidenceIndicator(plan.confidenceLevel)
            }
        }
    }

    // MARK: - Helpers

    private var focusIcon: String {
        switch plan.focus.lowercased() {
        case let s where s.contains("soothe"): "heart.fill"
        case let s where s.contains("hydrate"): "drop.fill"
        case let s where s.contains("simplify"): "arrow.down.circle.fill"
        case let s where s.contains("maintain"): "checkmark.shield.fill"
        case let s where s.contains("watch"): "eye.fill"
        case let s where s.contains("track"): "list.bullet.clipboard.fill"
        default: "sparkles"
        }
    }

    private var focusColor: Color {
        switch plan.focus.lowercased() {
        case let s where s.contains("soothe"): Color(hex: 0x5A8A9C)
        case let s where s.contains("hydrate"): Color(hex: 0x5B8C5A)
        case let s where s.contains("simplify"): Color(hex: 0xD4A017)
        case let s where s.contains("maintain"): CleraColor.success
        case let s where s.contains("watch"): CleraColor.accent
        case let s where s.contains("track"): CleraColor.accent
        default: CleraColor.accent
        }
    }

    private func confidenceColor(_ confidence: InsightConfidence) -> Color {
        switch confidence {
        case .high: CleraColor.success
        case .moderate: CleraColor.accent
        case .low: CleraColor.textSecondary
        }
    }

    private func confidenceIndicator(_ confidence: InsightConfidence) -> some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { i in
                Circle()
                    .fill(i < confidenceBars(confidence) ? confidenceColor(confidence) : CleraColor.border)
                    .frame(width: 8, height: 8)
            }
        }
    }

    private func confidenceBars(_ confidence: InsightConfidence) -> Int {
        switch confidence {
        case .high: return 3
        case .moderate: return 2
        case .low: return 1
        }
    }
}
