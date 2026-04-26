import SwiftUI

struct TodayView: View {
    @Environment(AppModel.self) private var appModel
    @State private var showScanFlow = false
    @State private var showDailyCopilot = false
    @State private var selectedExperiment: Experiment?
    @State private var showDailyAdviceDetail = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: CleraSpacing.lg) {
                header
                dailyAdviceCard
                dailyCopilotCard
                scanCard
                whatChangedSection
                dataDensitySection
                nudgesSection
                if !appModel.currentProducts.isEmpty {
                    routineChecklist
                }
                if let experiment = appModel.activeExperiment {
                    activeExperimentCard(experiment: experiment)
                }
                quickActions
                insightsSection
                Spacer(minLength: CleraSpacing.xl)
            }
            .padding(.horizontal, CleraSpacing.lg)
        }
        .scrollIndicators(.hidden)
        .background(CleraColor.background)
        .fullScreenCover(isPresented: $showScanFlow) {
            ScanFlowView { photos, skinMap, note, checkIn, scanQuality in
                appModel.recordSession(kind: .daily, photos: photos, skinMap: skinMap, note: note, checkIn: checkIn, scanQuality: scanQuality)
            }
        }
        .sheet(item: $selectedExperiment) { experiment in
            ExperimentDetailView(experiment: experiment)
        }
        .sheet(isPresented: $showDailyAdviceDetail) {
            if let advice = appModel.dailyAdvice {
                DailyAdviceDetailView(
                    advice: advice,
                    onScanTapped: { showScanFlow = true },
                    onRoutineTapped: { appModel.selectedTab = .routine },
                    onProfileTapped: { appModel.selectedTab = .profile }
                )
            }
        }
        .sheet(isPresented: $showDailyCopilot) {
            if let result = appModel.latestSkinSessionResult {
                DailyCopilotView(plan: result.dailyPlan, failures: result.failureState.map { SessionFailure(
                    failureCode: $0.code,
                    userMessage: $0.userMessage,
                    recommendedAction: $0.recommendedAction,
                    canContinue: $0.canContinue,
                    confidenceImpact: $0.confidenceImpact
                ) } != nil ? [SessionFailure(
                    failureCode: result.failureState!.code,
                    userMessage: result.failureState!.userMessage,
                    recommendedAction: result.failureState!.recommendedAction,
                    canContinue: result.failureState!.canContinue,
                    confidenceImpact: result.failureState!.confidenceImpact
                )] : [])
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(greeting)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(CleraColor.textPrimary)
            Text(Date().formatted(date: .long, time: .omitted))
                .font(.system(size: 15))
                .foregroundStyle(CleraColor.textSecondary)
        }
        .padding(.top, CleraSpacing.xl)
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: .now)
        let name = appModel.userProfile?.name ?? ""
        let prefix = hour < 12 ? "Good morning" : hour < 17 ? "Good afternoon" : "Good evening"
        return name.isEmpty ? prefix : "\(prefix), \(name)"
    }

    @ViewBuilder
    private var dailyAdviceCard: some View {
        if let advice = appModel.dailyAdvice {
            DailyAdviceCard(advice: advice) {
                showDailyAdviceDetail = true
            }
        }
    }

    @ViewBuilder
    private var dailyCopilotCard: some View {
        if let result = appModel.latestSkinSessionResult {
            Button {
                showDailyCopilot = true
            } label: {
                CleraCard {
                    VStack(alignment: .leading, spacing: CleraSpacing.md) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(result.dailyPlan.period.displayName)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(CleraColor.textSecondary)
                                    .textCase(.uppercase)
                                    .tracking(0.8)
                                Text(result.dailyPlan.focus)
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundStyle(CleraColor.textPrimary)
                                    .lineLimit(1)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(CleraColor.textSecondary)
                        }

                        HStack(spacing: CleraSpacing.md) {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.circle")
                                    .font(.system(size: 12))
                                Text("\(result.dailyPlan.recommendedSteps.count) steps")
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .foregroundStyle(CleraColor.success)

                            if !result.dailyPlan.avoidSteps.isEmpty {
                                HStack(spacing: 4) {
                                    Image(systemName: "xmark.circle")
                                        .font(.system(size: 12))
                                    Text("\(result.dailyPlan.avoidSteps.count) to avoid")
                                        .font(.system(size: 12, weight: .medium))
                                }
                                .foregroundStyle(Color(hex: 0xC75B39).opacity(0.8))
                            }

                            HStack(spacing: 4) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 12))
                                Text(result.dailyPlan.confidenceLevel.displayName)
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .foregroundStyle(CleraColor.accent)
                        }
                    }
                }
            }
            .buttonStyle(.plain)
        } else {
            EmptyView()
        }
    }

    private var scanCard: some View {
        CleraCard {
            VStack(alignment: .leading, spacing: CleraSpacing.md) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(appModel.todayScanned ? CleraCopy.Today.checkedIn : CleraCopy.Today.dailySkinScan)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(CleraColor.textPrimary)
                        Text(appModel.todayScanned ? CleraCopy.Today.greatJob : CleraCopy.Today.capturePrompt)
                            .font(.system(size: 14))
                            .foregroundStyle(CleraColor.textSecondary)
                    }
                    Spacer()
                    Image(systemName: appModel.todayScanned ? "checkmark.circle.fill" : "camera.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(appModel.todayScanned ? CleraColor.success : CleraColor.accent)
                }

                if !appModel.todayScanned {
                    Button(CleraCopy.Today.scanNow) {
                        showScanFlow = true
                    }
                    .buttonStyle(CleraPrimaryButtonStyle())
                    .accessibilityLabel(CleraCopy.Today.scanAccessibilityLabel)
                    .accessibilityHint(CleraCopy.Today.scanAccessibilityHint)
                } else if let result = appModel.latestSkinSessionResult {
                    if let failure = result.failureState {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: failure.canContinue ? "exclamationmark.triangle.fill" : "xmark.octagon.fill")
                                    .font(.system(size: 12))
                                    .foregroundStyle(failure.canContinue ? Color(hex: 0xD4A017) : Color(hex: 0xC75B39))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(failure.userMessage)
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundStyle(CleraColor.textPrimary)
                                    if !failure.recommendedAction.isEmpty {
                                        Text(failure.recommendedAction)
                                            .font(.system(size: 11))
                                            .foregroundStyle(CleraColor.textSecondary)
                                    }
                                }
                            }
                        }
                    } else if result.scanStatus == .savedLowConfidence {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(result.userMessages, id: \.self) { message in
                                HStack(spacing: 6) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .font(.system(size: 10))
                                        .foregroundStyle(Color(hex: 0xD4A017))
                                    Text(message)
                                        .font(.system(size: 12))
                                        .foregroundStyle(CleraColor.textSecondary)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var whatChangedSection: some View {
        if let result = appModel.latestSkinSessionResult,
           let whatChanged = result.timelineEnrichment?.whatChanged,
           whatChanged.hasChanges {
            WhatChangedCard(result: whatChanged) {
                appModel.selectedTab = .progress
            }
        }
    }

    private var dataDensitySection: some View {
        DataDensityBadge(density: DataDensity(scanCount: appModel.sessions.count))
    }

    private var nudgesSection: some View {
        let activeNudges = appModel.nudges.filter {
            !$0.isDismissed && ($0.expiresAt == nil || $0.expiresAt! > Date())
        }
        return ForEach(activeNudges.prefix(2)) { nudge in
            nudgeCard(nudge: nudge)
        }
    }

    private func nudgeCard(nudge: Nudge) -> some View {
        CleraCard {
            VStack(alignment: .leading, spacing: CleraSpacing.sm) {
                HStack {
                    Text(nudge.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(CleraColor.textPrimary)
                    Spacer()
                    Button {
                        appModel.dismissNudge(id: nudge.id)
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 12))
                            .foregroundStyle(CleraColor.textSecondary)
                    }
                }

                Text(nudge.body)
                    .font(.system(size: 14))
                    .foregroundStyle(CleraColor.textSecondary)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)

                if let actionLabel = nudge.actionLabel {
                    Button(actionLabel) {
                        handleNudgeAction(route: nudge.actionRoute)
                    }
                    .buttonStyle(CleraSecondaryButtonStyle())
                }
            }
        }
    }

    private func handleNudgeAction(route: String?) {
        guard let route = route else { return }
        switch route {
        case "scan":
            showScanFlow = true
        case "timeline":
            appModel.selectedTab = .progress
        case "routine":
            appModel.selectedTab = .routine
        default:
            break
        }
    }

    private var routineChecklist: some View {
        CleraCard {
            VStack(alignment: .leading, spacing: CleraSpacing.md) {
                HStack {
                    Text(CleraCopy.Today.todaysRoutine)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(CleraColor.textPrimary)
                    Spacer()
                    Text(CleraCopy.Today.routineProgress(appModel.todayRoutineLogs.count))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(CleraColor.textSecondary)
                }

                HStack(spacing: CleraSpacing.md) {
                    routinePeriodButton(period: .morning, icon: "sun.max.fill")
                    routinePeriodButton(period: .evening, icon: "moon.fill")
                }
            }
        }
    }

    private func routinePeriodButton(period: Period, icon: String) -> some View {
        let isDone = appModel.todayRoutineLogs.contains { log in
            let hour = Calendar.current.component(.hour, from: log.date)
            if period == .morning { return hour < 12 }
            return hour >= 12
        }

        return Button {
            let entry = RoutineLogEntry(
                date: .now,
                followedRoutine: true,
                productIDs: appModel.currentProducts.filter { $0.period == period || $0.period == .both }.map(\.id),
                notes: nil
            )
            appModel.logRoutine(entry)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: isDone ? "checkmark.circle.fill" : icon)
                    .font(.system(size: 18))
                    .foregroundStyle(isDone ? CleraColor.success : CleraColor.accent)
                Text(period.displayName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(CleraColor.textPrimary)
                Spacer()
            }
            .padding(.vertical, 12)
            .padding(.horizontal, CleraSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: CleraRadius.large, style: .continuous)
                    .fill(isDone ? CleraColor.success.opacity(0.08) : CleraColor.elevatedSurface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: CleraRadius.large, style: .continuous)
                    .stroke(isDone ? CleraColor.success.opacity(0.25) : CleraColor.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(isDone)
    }

    private func activeExperimentCard(experiment: Experiment) -> some View {
        Button {
            selectedExperiment = experiment
        } label: {
            CleraCard {
                VStack(alignment: .leading, spacing: CleraSpacing.sm) {
                    HStack {
                        Text(CleraCopy.Today.activeExperiment)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(CleraColor.textSecondary)
                            .textCase(.uppercase)
                            .tracking(0.8)
                        Spacer()
                        HStack(spacing: 4) {
                            Circle()
                                .fill(CleraColor.accent)
                                .frame(width: 6, height: 6)
                            Text("Day \(daysSince(experiment.startDate)) of \(experiment.durationDays)")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(CleraColor.textSecondary)
                        }
                    }

                    Text(experiment.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(CleraColor.textPrimary)

                    Text(experiment.hypothesis)
                        .font(.system(size: 13))
                        .foregroundStyle(CleraColor.textSecondary)
                        .lineLimit(2)

                    HStack(spacing: 12) {
                        Label(experiment.zone.displayName, systemImage: experiment.zone.systemImage)
                            .font(.system(size: 12))
                            .foregroundStyle(CleraColor.accent)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12))
                            .foregroundStyle(CleraColor.textSecondary)
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func daysSince(_ date: Date) -> Int {
        Calendar.current.dateComponents([.day], from: date, to: .now).day ?? 0
    }

    private var quickActions: some View {
        VStack(alignment: .leading, spacing: CleraSpacing.md) {
            Text(CleraCopy.Today.quickActions)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(CleraColor.textPrimary)

            HStack(spacing: CleraSpacing.md) {
                quickActionButton(icon: "face.smiling", title: CleraCopy.Today.viewMap, hint: CleraCopy.Today.viewMapHint) {
                    appModel.selectedTab = .map
                }
                // Experiments quick action hidden until navigation target is available
                quickActionButton(icon: "chart.line.uptrend.xyaxis", title: CleraCopy.Today.progress, hint: CleraCopy.Today.progressHint) {
                    appModel.selectedTab = .progress
                }
            }
        }
    }

    private func quickActionButton(icon: String, title: String, hint: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundStyle(CleraColor.accent)
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(CleraColor.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, CleraSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: CleraRadius.large, style: .continuous)
                    .fill(CleraColor.elevatedSurface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: CleraRadius.large, style: .continuous)
                    .stroke(CleraColor.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityHint(hint)
    }

    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: CleraSpacing.md) {
            Text(CleraCopy.Today.latestInsights)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(CleraColor.textPrimary)

            if appModel.insights.isEmpty {
                Text(CleraCopy.State.noInsights)
                    .font(.system(size: 14))
                    .foregroundStyle(CleraColor.textSecondary)
                    .padding(.vertical, CleraSpacing.md)
            } else {
                ForEach(appModel.insights.prefix(3)) { insight in
                    InsightCard(insight: insight)
                }
            }
        }
    }
}
