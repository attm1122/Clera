import SwiftUI

struct ExperimentsView: View {
    @Environment(AppModel.self) private var appModel
    @State private var showStartExperiment = false
    @State private var selectedExperiment: Experiment?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: CleraSpacing.lg) {
                    CleraSectionHeader(
                        eyebrow: "Test & Learn",
                        title: "Experiments",
                        subtitle: "Run controlled tests to discover what works for your skin."
                    )
                    .padding(.top, CleraSpacing.xl)

                    activeExperimentSection
                    pastExperimentsSection
                    Spacer(minLength: CleraSpacing.xl)
                }
                .padding(.horizontal, CleraSpacing.lg)
            }
            .scrollIndicators(.hidden)
            .background(CleraColor.background)
            .sheet(isPresented: $showStartExperiment) {
                StartExperimentView { experiment in
                    appModel.startExperiment(experiment)
                    showStartExperiment = false
                }
            }
            .navigationDestination(item: $selectedExperiment) { experiment in
                ExperimentDetailView(experiment: experiment)
            }
        }
    }

    private var activeExperimentSection: some View {
        VStack(alignment: .leading, spacing: CleraSpacing.md) {
            HStack {
                Text(CleraCopy.Experiments.activeExperiment)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(CleraColor.textPrimary)
                Spacer()
                if appModel.canStartExperiment {
                    Button {
                        showStartExperiment = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(CleraColor.accent)
                    }
                }
            }

            if let experiment = appModel.activeExperiment {
                experimentCard(experiment: experiment, isActive: true)

                Text(CleraCopy.State.completeBeforeNew)
                    .font(.system(size: 13))
                    .foregroundStyle(CleraColor.textSecondary)
            } else {
                CleraCard {
                    VStack(spacing: CleraSpacing.md) {
                        Image(systemName: "flask")
                            .font(.system(size: 40))
                            .foregroundStyle(CleraColor.textSecondary)
                        Text(CleraCopy.State.noActiveExperiment)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(CleraColor.textPrimary)
                        Text(CleraCopy.State.noActiveExperimentBody)
                            .font(.system(size: 14))
                            .foregroundStyle(CleraColor.textSecondary)
                            .multilineTextAlignment(.center)
                        Button(CleraCopy.State.startExperiment) {
                            showStartExperiment = true
                        }
                        .buttonStyle(CleraPrimaryButtonStyle())
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, CleraSpacing.xl)
                }
            }
        }
    }

    private var pastExperimentsSection: some View {
        VStack(alignment: .leading, spacing: CleraSpacing.md) {
            Text(CleraCopy.Experiments.pastExperiments)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(CleraColor.textPrimary)

            let past = appModel.experiments.filter { !$0.isActive }
            if past.isEmpty {
                Text(CleraCopy.State.noPastExperiments)
                    .font(.system(size: 14))
                    .foregroundStyle(CleraColor.textSecondary)
            } else {
                ForEach(past) { experiment in
                    experimentCard(experiment: experiment, isActive: false)
                }
            }
        }
    }

    private func experimentCard(experiment: Experiment, isActive: Bool) -> some View {
        Button {
            selectedExperiment = experiment
        } label: {
            CleraCard {
                VStack(alignment: .leading, spacing: CleraSpacing.sm) {
                    HStack {
                        Text(experiment.name)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(CleraColor.textPrimary)
                        Spacer()
                        statusBadge(isActive: isActive, result: experiment.result)
                    }

                    Text(experiment.hypothesis)
                        .font(.system(size: 14))
                        .foregroundStyle(CleraColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 12) {
                        Label(experiment.zone.displayName, systemImage: experiment.zone.systemImage)
                            .font(.system(size: 12))
                            .foregroundStyle(CleraColor.accent)
                        Label("\(experiment.durationDays) days", systemImage: "calendar")
                            .font(.system(size: 12))
                            .foregroundStyle(CleraColor.textSecondary)
                    }

                    if isActive {
                        HStack {
                            Text(CleraCopy.Experiments.tapToCheckIn)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(CleraColor.accent)
                            Spacer()
                        }
                        .padding(.top, 4)
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func statusBadge(isActive: Bool, result: ExperimentResult?) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(isActive ? CleraColor.accent : result?.outcome == .improvement ? .green : result?.outcome == .worsened ? .red : CleraColor.textSecondary)
                .frame(width: 8, height: 8)
            Text(isActive ? "Active" : result?.outcome.rawValue.capitalized ?? "Completed")
                .font(.system(size: 12, weight: .medium))
        }
        .foregroundStyle(isActive ? CleraColor.accent : CleraColor.textSecondary)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule(style: .continuous)
                .fill(isActive ? CleraColor.accentSoft : CleraColor.surface)
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(isActive ? CleraColor.accent.opacity(0.18) : CleraColor.border, lineWidth: 1)
        )
    }
}

struct StartExperimentView: View {
    var onStart: (Experiment) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var zone: ZoneType = .forehead
    @State private var hypothesis = ""
    @State private var durationDays = 14

    var body: some View {
        NavigationStack {
            Form {
                Section(CleraCopy.Experiments.experimentDetails) {
                    TextField(CleraCopy.Experiments.nameLabel, text: $name)
                    Picker(CleraCopy.Experiments.zoneLabel, selection: $zone) {
                        ForEach(Array(ZoneType.allCases), id: \.self) { z in
                            Text(z.displayName).tag(z)
                        }
                    }
                    TextField(CleraCopy.Experiments.hypothesisLabel, text: $hypothesis, axis: .vertical)
                        .lineLimit(3...6)
                }
                Section(CleraCopy.Experiments.durationLabel) {
                    Stepper("\(durationDays) days", value: $durationDays, in: 7...56)
                }
            }
            .navigationTitle(CleraCopy.Experiments.newExperiment)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(CleraCopy.ScanFlow.cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(CleraCopy.Experiments.start) {
                        let experiment = Experiment(
                            name: name,
                            zone: zone,
                            hypothesis: hypothesis,
                            durationDays: durationDays,
                            isActive: true,
                            relatedProductIDs: [],
                            dailyCheckIns: []
                        )
                        onStart(experiment)
                    }
                    .disabled(name.isEmpty || hypothesis.isEmpty)
                }
            }
        }
    }
}
