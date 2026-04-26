import SwiftUI

struct PostScanCheckInView: View {
    var onComplete: (SkinMapCheckIn) -> Void
    var onSkip: () -> Void

    @State private var followedRoutine = true
    @State private var newProducts = false
    @State private var hadIrritation = false
    @State private var hadDryness = false
    @State private var hadBreakouts = false
    @State private var notes = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: CleraSpacing.lg) {
                CleraSectionHeader(
                    eyebrow: CleraCopy.CheckIn.title,
                    title: CleraCopy.CheckIn.subtitle,
                    subtitle: CleraCopy.CheckIn.body
                )
                .padding(.top, CleraSpacing.xl)

                questionCard(title: CleraCopy.CheckIn.followedRoutineQuestion) {
                    Toggle(CleraCopy.CheckIn.followedRoutineLabel, isOn: $followedRoutine)
                        .tint(CleraColor.accent)
                }

                questionCard(title: CleraCopy.CheckIn.changesQuestion) {
                    Toggle(CleraCopy.CheckIn.newProductsLabel, isOn: $newProducts)
                        .tint(CleraColor.accent)

                    Divider()
                        .foregroundStyle(CleraColor.border)
                        .padding(.vertical, 4)

                    VStack(alignment: .leading, spacing: CleraSpacing.sm) {
                        Text(CleraCopy.CheckIn.symptomsQuestion)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(CleraColor.textSecondary)

                        HStack(spacing: CleraSpacing.md) {
                            checkToggle(CleraCopy.CheckIn.irritationLabel, isOn: $hadIrritation, icon: "exclamationmark.triangle.fill")
                            checkToggle(CleraCopy.CheckIn.drynessLabel, isOn: $hadDryness, icon: "drop.triangle.fill")
                            checkToggle(CleraCopy.CheckIn.breakoutsLabel, isOn: $hadBreakouts, icon: "burst.fill")
                        }
                    }
                }

                questionCard(title: CleraCopy.CheckIn.notesQuestion) {
                    TextField(CleraCopy.CheckIn.notesPlaceholder, text: $notes, axis: .vertical)
                        .textFieldStyle(.plain)
                        .padding(CleraSpacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: CleraRadius.medium, style: .continuous)
                                .fill(CleraColor.surface)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: CleraRadius.medium, style: .continuous)
                                .stroke(CleraColor.border, lineWidth: 1)
                        )
                }

                Spacer(minLength: CleraSpacing.xl)
            }
            .padding(.horizontal, CleraSpacing.lg)
        }
        .scrollIndicators(.hidden)
        .background(CleraColor.background)
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: CleraSpacing.sm) {
                Button(CleraCopy.CheckIn.continue) {
                    let checkIn = SkinMapCheckIn(
                        followedRoutine: followedRoutine,
                        newProducts: newProducts,
                        hadIrritation: hadIrritation,
                        hadDryness: hadDryness,
                        hadBreakouts: hadBreakouts,
                        notes: notes.isEmpty ? nil : notes
                    )
                    onComplete(checkIn)
                }
                .buttonStyle(CleraPrimaryButtonStyle())
                .padding(.horizontal, CleraSpacing.lg)

                Button(CleraCopy.CheckIn.skip) {
                    onSkip()
                }
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(CleraColor.textSecondary)
                .padding(.bottom, CleraSpacing.md)
            }
            .padding(.top, CleraSpacing.sm)
            .background(CleraColor.background.opacity(0.9))
        }
    }

    private func questionCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        CleraCard {
            VStack(alignment: .leading, spacing: CleraSpacing.md) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(CleraColor.textPrimary)
                content()
            }
        }
    }

    private func checkToggle(_ label: String, isOn: Binding<Bool>, icon: String) -> some View {
        Button {
            isOn.wrappedValue.toggle()
        } label: {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(isOn.wrappedValue ? CleraColor.accent : CleraColor.textSecondary)
                Text(label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(isOn.wrappedValue ? CleraColor.textPrimary : CleraColor.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, CleraSpacing.sm)
            .background(
                RoundedRectangle(cornerRadius: CleraRadius.medium, style: .continuous)
                    .fill(isOn.wrappedValue ? CleraColor.accentSoft : CleraColor.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: CleraRadius.medium, style: .continuous)
                    .stroke(isOn.wrappedValue ? CleraColor.accent.opacity(0.3) : CleraColor.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
