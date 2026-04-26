import SwiftUI

struct SkinConsultationView: View {
    @Binding var profile: SkinProfile
    var onComplete: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: CleraSpacing.lg) {
                CleraSectionHeader(
                    eyebrow: "\(CleraCopy.Onboarding.stepPrefix) 1 of 4",
                    title: CleraCopy.Onboarding.consultationTitle,
                    subtitle: CleraCopy.Onboarding.consultationBody
                )
                .padding(.top, CleraSpacing.xl)

                pickerSection(title: CleraCopy.Onboarding.skinTypeLabel, selection: $profile.skinType, options: SkinType.allCases) { $0.rawValue.capitalized }
                pickerSection(title: CleraCopy.Onboarding.sensitivityLabel, selection: $profile.sensitivity, options: Sensitivity.allCases) { $0.rawValue.capitalized }
                pickerSection(title: CleraCopy.Onboarding.primaryGoalLabel, selection: $profile.primaryGoal, options: SkinGoal.allCases) { $0.displayName }
                pickerSection(title: CleraCopy.Onboarding.ageRangeLabel, selection: $profile.ageRange, options: AgeRange.allCases) { $0.displayName }

                concernsSection

                Button(CleraCopy.Onboarding.continue) {
                    onComplete()
                }
                .buttonStyle(CleraPrimaryButtonStyle())
                .padding(.top, CleraSpacing.md)

                Spacer(minLength: CleraSpacing.xl)
            }
            .padding(.horizontal, CleraSpacing.lg)
        }
        .scrollIndicators(.hidden)
        .background(CleraColor.background)
    }

    private var concernsSection: some View {
        VStack(alignment: .leading, spacing: CleraSpacing.md) {
            Text(CleraCopy.Onboarding.primaryConcernsLabel)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(CleraColor.textPrimary)

            FlowLayout(spacing: 8) {
                ForEach(Array(SkinConcern.allCases), id: \.self) { concern in
                    let selected = profile.primaryConcerns.contains(concern)
                    Button {
                        if selected {
                            profile.primaryConcerns.removeAll { $0 == concern }
                        } else {
                            profile.primaryConcerns.append(concern)
                        }
                    } label: {
                        CleraTag(title: concern.displayName, isSelected: selected)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func pickerSection<T: CaseIterable & Equatable & Hashable>(
        title: String,
        selection: Binding<T>,
        options: T.AllCases,
        display: @escaping (T) -> String
    ) -> some View {
        VStack(alignment: .leading, spacing: CleraSpacing.sm) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(CleraColor.textPrimary)

            FlowLayout(spacing: 8) {
                ForEach(Array(options), id: \.self) { option in
                    let selected = selection.wrappedValue == option
                    Button {
                        selection.wrappedValue = option
                    } label: {
                        CleraTag(title: display(option), isSelected: selected)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                      y: bounds.minY + result.positions[index].y),
                          proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }
                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
            }

            self.size = CGSize(width: maxWidth, height: y + rowHeight)
        }
    }
}
