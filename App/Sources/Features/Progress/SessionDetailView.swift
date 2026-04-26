import SwiftUI

struct SessionDetailView: View {
    let session: ScanSession
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: CleraSpacing.lg) {
                    Text(session.createdAt.formatted(date: .long, time: .shortened))
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(CleraColor.textPrimary)

                    Text("\(CleraCopy.Progress.scanDetail): \(session.kind.rawValue.capitalized)")
                        .font(.system(size: 15))
                        .foregroundStyle(CleraColor.textSecondary)

                    if let note = session.note, !note.isEmpty {
                        CleraCard {
                            Text(note)
                                .font(.system(size: 15))
                                .foregroundStyle(CleraColor.textPrimary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    if !session.photos.isEmpty {
                        Text("Photos")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(CleraColor.textPrimary)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: CleraSpacing.md) {
                                ForEach(session.photos) { photo in
                                    if let uiImage = photo.resolvedImage() {
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 200, height: 260)
                                            .clipShape(RoundedRectangle(cornerRadius: CleraRadius.large, style: .continuous))
                                    } else {
                                        RoundedRectangle(cornerRadius: CleraRadius.large, style: .continuous)
                                            .fill(CleraColor.accentSoft)
                                            .frame(width: 200, height: 260)
                                            .overlay(
                                                Image(systemName: "photo")
                                                    .font(.system(size: 32))
                                                    .foregroundStyle(CleraColor.accent)
                                            )
                                    }
                                }
                            }
                        }
                    }

                    Text(CleraCopy.Progress.skinMap)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(CleraColor.textPrimary)

                    ForEach(session.skinMap.zones) { zone in
                        zoneMiniRow(zone: zone)
                    }

                    Spacer(minLength: CleraSpacing.xl)
                }
                .padding(.horizontal, CleraSpacing.lg)
                .padding(.top, CleraSpacing.lg)
            }
            .scrollIndicators(.hidden)
            .background(CleraColor.background)
            .navigationTitle("Scan Detail")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(CleraColor.accent)
                }
            }
        }
    }

    private func zoneMiniRow(zone: FaceZone) -> some View {
        HStack {
            Text(zone.zoneType.displayName)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(CleraColor.textPrimary)
            Spacer()
            HStack(spacing: 8) {
                Text("B: \(zone.status.breakouts.displayName)")
                    .font(.system(size: 12))
                    .foregroundStyle(zone.status.breakouts.color)
                Text("R: \(zone.status.redness.displayName)")
                    .font(.system(size: 12))
                    .foregroundStyle(zone.status.redness.color)
            }
        }
        .padding(.vertical, 8)
    }
}
