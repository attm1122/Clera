import SwiftUI

struct ProductIntelligenceView: View {
    let report: ProductIntelligenceReport
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: CleraSpacing.lg) {
                    header
                    risksSection
                    explanationsSection
                    actionsSection
                    Spacer(minLength: CleraSpacing.xl)
                }
                .padding(.horizontal, CleraSpacing.lg)
                .padding(.top, CleraSpacing.lg)
            }
            .scrollIndicators(.hidden)
            .background(CleraColor.background)
            .navigationTitle(CleraCopy.ProductIntelligence.viewTitle)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(CleraColor.accent)
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(report.generatedAt.formatted(date: .long, time: .omitted))
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(CleraColor.textSecondary)
                .textCase(.uppercase)
                .tracking(0.8)

            let warnings = report.risks.filter { $0.severity == .warning }.count
            let cautions = report.risks.filter { $0.severity == .caution }.count

            if warnings > 0 {
                Text("\(warnings) warning\(warnings == 1 ? "" : "s") found")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(hex: 0xC75B39))
            } else if cautions > 0 {
                Text("\(cautions) caution\(cautions == 1 ? "" : "s") found")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(hex: 0xD4A017))
            } else {
                Text(CleraCopy.ProductIntelligence.routineLooksGood)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(CleraColor.success)
            }

            Text("Based on your current products, routine logs, and recent skin map changes.")
                .font(.system(size: 14))
                .foregroundStyle(CleraColor.textSecondary)
                .padding(.top, 2)
        }
    }

    private var risksSection: some View {
        VStack(alignment: .leading, spacing: CleraSpacing.md) {
            Text(CleraCopy.ProductIntelligence.detectedRisks)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(CleraColor.textPrimary)

            if report.risks.isEmpty {
                CleraCard {
                    HStack(spacing: CleraSpacing.md) {
                        Image(systemName: "checkmark.shield.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(CleraColor.success)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(CleraCopy.ProductIntelligence.noIssues)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(CleraColor.textPrimary)
                            Text(CleraCopy.ProductIntelligence.noIssuesBody)
                                .font(.system(size: 13))
                                .foregroundStyle(CleraColor.textSecondary)
                        }
                    }
                }
            } else {
                ForEach(report.risks) { risk in
                    riskCard(risk: risk)
                }
            }
        }
    }

    private func riskCard(risk: ProductRisk) -> some View {
        let color = Color(hex: risk.severity.color)
        return CleraCard {
            VStack(alignment: .leading, spacing: CleraSpacing.sm) {
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: risk.severity == .warning ? "exclamationmark.triangle.fill" : risk.severity == .caution ? "exclamationmark.circle.fill" : "info.circle.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(color)
                        Text(risk.severity.displayName)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(color)
                    }
                    Spacer()
                }

                Text(risk.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(CleraColor.textPrimary)

                Text(risk.description)
                    .font(.system(size: 13))
                    .foregroundStyle(CleraColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: CleraRadius.large, style: .continuous)
                .stroke(color.opacity(0.25), lineWidth: 1.5)
        )
    }

    private var explanationsSection: some View {
        VStack(alignment: .leading, spacing: CleraSpacing.md) {
            Text(CleraCopy.ProductIntelligence.whyThisMatters)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(CleraColor.textPrimary)

            if report.explanations.isEmpty {
                Text(CleraCopy.ProductIntelligence.noAdditionalContext)
                    .font(.system(size: 14))
                    .foregroundStyle(CleraColor.textSecondary)
            } else {
                ForEach(report.explanations.indices, id: \.self) { index in
                    HStack(alignment: .top, spacing: 8) {
                        Text("\(index + 1)")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(CleraColor.accent)
                            .frame(width: 20, height: 20)
                            .background(Circle().fill(CleraColor.accentSoft))
                        Text(report.explanations[index])
                            .font(.system(size: 14))
                            .foregroundStyle(CleraColor.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }

    private var actionsSection: some View {
        VStack(alignment: .leading, spacing: CleraSpacing.md) {
            Text(CleraCopy.ProductIntelligence.suggestedActions)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(CleraColor.textPrimary)

            if report.suggestedActions.isEmpty {
                Text(CleraCopy.ProductIntelligence.keepDoing)
                    .font(.system(size: 14))
                    .foregroundStyle(CleraColor.textSecondary)
            } else {
                ForEach(report.suggestedActions.indices, id: \.self) { index in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(CleraColor.success)
                        Text(report.suggestedActions[index])
                            .font(.system(size: 14))
                            .foregroundStyle(CleraColor.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }
}
