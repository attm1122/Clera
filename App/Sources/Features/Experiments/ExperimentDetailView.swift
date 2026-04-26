import SwiftUI

struct ExperimentDetailView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.dismiss) private var dismiss

    let experiment: Experiment
    @State private var showCheckIn = false
    @State private var checkInNotes = ""
    @State private var checkInCondition = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: CleraSpacing.lg) {
                header
                progressSection
                checkInsSection
                resultSection
                Spacer(minLength: CleraSpacing.xl)
            }
            .padding(.horizontal, CleraSpacing.lg)
        }
        .scrollIndicators(.hidden)
        .background(CleraColor.background)
        .navigationTitle(experiment.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") { dismiss() }
                    .foregroundStyle(CleraColor.accent)
            }
        }
        .sheet(isPresented: $showCheckIn) {
            checkInSheet
        }
    }

    private var header: some View {
        CleraCard {
            VStack(alignment: .leading, spacing: CleraSpacing.sm) {
                HStack {
                    statusBadge
                    Spacer()
                }

                Text(experiment.hypothesis)
                    .font(.system(size: 15))
                    .foregroundStyle(CleraColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 16) {
                    Label(experiment.zone.displayName, systemImage: experiment.zone.systemImage)
                        .font(.system(size: 13))
                        .foregroundStyle(CleraColor.accent)
                    Label("\(experiment.durationDays) days", systemImage: "calendar")
                        .font(.system(size: 13))
                        .foregroundStyle(CleraColor.textSecondary)
                    Label(startDateText, systemImage: "clock")
                        .font(.system(size: 13))
                        .foregroundStyle(CleraColor.textSecondary)
                }
            }
        }
    }

    private var startDateText: String {
        let days = Calendar.current.dateComponents([.day], from: experiment.startDate, to: .now).day ?? 0
        if experiment.isActive {
            return "Day \(days)"
        }
        return experiment.startDate.formatted(date: .abbreviated, time: .omitted)
    }

    private var statusBadge: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(experiment.isActive ? CleraColor.accent : experiment.result?.outcome == .improvement ? .green : experiment.result?.outcome == .worsened ? .red : CleraColor.textSecondary)
                .frame(width: 8, height: 8)
            Text(experiment.isActive ? "Active" : experiment.result?.outcome.rawValue.capitalized ?? "Completed")
                .font(.system(size: 12, weight: .medium))
        }
        .foregroundStyle(experiment.isActive ? CleraColor.accent : CleraColor.textSecondary)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule(style: .continuous)
                .fill(experiment.isActive ? CleraColor.accentSoft : CleraColor.surface)
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(experiment.isActive ? CleraColor.accent.opacity(0.18) : CleraColor.border, lineWidth: 1)
        )
    }

    private var progressSection: some View {
        VStack(alignment: .leading, spacing: CleraSpacing.md) {
            Text(CleraCopy.Progress.subtitle)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(CleraColor.textPrimary)

            let totalDays = experiment.durationDays
            let elapsed = min(Calendar.current.dateComponents([.day], from: experiment.startDate, to: .now).day ?? 0, totalDays)
            let progress = totalDays > 0 ? Double(elapsed) / Double(totalDays) : 0

            CleraCard {
                VStack(alignment: .leading, spacing: CleraSpacing.sm) {
                    HStack {
                        Text("\(elapsed) of \(totalDays) days")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(CleraColor.textPrimary)
                        Spacer()
                        Text("\(Int(progress * 100))%")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(CleraColor.accent)
                    }

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: CleraRadius.pill, style: .continuous)
                                .fill(CleraColor.border)
                                .frame(height: 8)
                            RoundedRectangle(cornerRadius: CleraRadius.pill, style: .continuous)
                                .fill(CleraColor.accent)
                                .frame(width: max(0, geo.size.width * CGFloat(progress)), height: 8)
                        }
                    }
                    .frame(height: 8)
                }
            }

            if experiment.isActive {
                Button(CleraCopy.Experiments.checkInToday) {
                    showCheckIn = true
                }
                .buttonStyle(CleraPrimaryButtonStyle())
            }
        }
    }

    private var checkInsSection: some View {
        VStack(alignment: .leading, spacing: CleraSpacing.md) {
            HStack {
                Text("Daily Check-ins")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(CleraColor.textPrimary)
                Spacer()
                Text("\(experiment.dailyCheckIns.count) total")
                    .font(.system(size: 13))
                    .foregroundStyle(CleraColor.textSecondary)
            }

            if experiment.dailyCheckIns.isEmpty {
                CleraCard {
                    Text(CleraCopy.Experiments.noCheckIns)
                        .font(.system(size: 14))
                        .foregroundStyle(CleraColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            } else {
                ForEach(experiment.dailyCheckIns.sorted(by: { $0.date > $1.date })) { checkIn in
                    checkInRow(checkIn: checkIn)
                }
            }
        }
    }

    private func checkInRow(checkIn: DailyCheckIn) -> some View {
        CleraCard {
            VStack(alignment: .leading, spacing: CleraSpacing.sm) {
                HStack {
                    Text(checkIn.date.formatted(date: .abbreviated, time: .shortened))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(CleraColor.textPrimary)
                    Spacer()
                    Text(checkIn.skinCondition)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(CleraColor.accent)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            Capsule(style: .continuous)
                                .fill(CleraColor.accentSoft)
                        )
                }

                if let notes = checkIn.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.system(size: 14))
                        .foregroundStyle(CleraColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private var resultSection: some View {
        VStack(alignment: .leading, spacing: CleraSpacing.md) {
            if !experiment.isActive, let result = experiment.result {
                Text(CleraCopy.Experiments.resultLabel)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(CleraColor.textPrimary)

                CleraCard {
                    VStack(alignment: .leading, spacing: CleraSpacing.sm) {
                        HStack {
                            Text("Outcome")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(CleraColor.textSecondary)
                            Spacer()
                            Text(result.outcome.rawValue.capitalized)
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundStyle(result.outcome == .improvement ? .green : result.outcome == .worsened ? .red : CleraColor.textSecondary)
                        }

                        if let notes = result.notes, !notes.isEmpty {
                            Divider().background(CleraColor.border)
                            Text(notes)
                                .font(.system(size: 14))
                                .foregroundStyle(CleraColor.textPrimary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
        }
    }

    private var checkInSheet: some View {
        NavigationStack {
            Form {
                Section(CleraCopy.Experiments.checkInPrompt) {
                    TextField(CleraCopy.Experiments.checkInPlaceholder, text: $checkInCondition)
                }
                Section(CleraCopy.Experiments.notesOptional) {
                    TextField(CleraCopy.Experiments.notesPlaceholder, text: $checkInNotes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle(CleraCopy.Experiments.dailyCheckIn)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(CleraCopy.ScanFlow.cancel) { showCheckIn = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(CleraCopy.Experiments.save) {
                        let checkIn = DailyCheckIn(
                            date: .now,
                            skinCondition: checkInCondition.isEmpty ? CleraCopy.Experiments.noComment : checkInCondition,
                            notes: checkInNotes.isEmpty ? nil : checkInNotes
                        )
                        if let index = appModel.experiments.firstIndex(where: { $0.id == experiment.id }) {
                            appModel.experiments[index].dailyCheckIns.append(checkIn)
                        }
                        checkInCondition = ""
                        checkInNotes = ""
                        showCheckIn = false
                    }
                    .disabled(checkInCondition.isEmpty)
                }
            }
        }
    }
}
