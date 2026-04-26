import SwiftUI

struct PrivacySettingsView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteConfirmation = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Data") {
                    Toggle("Save photos", isOn: Bindable(appModel).privacySettings.savePhotos)
                        .tint(CleraColor.accent)
                    Toggle("Share analytics", isOn: Bindable(appModel).privacySettings.shareAnalytics)
                        .tint(CleraColor.accent)
                }

                Section {
                    // Export action placeholder
                }

                Section {
                    Button("Delete account") {
                        showDeleteConfirmation = true
                    }
                    .foregroundStyle(Color.red.opacity(0.8))
                }
            }
            .navigationTitle("Privacy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(CleraColor.textSecondary)
                }
            }
            .alert("Delete account?", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    appModel.logout()
                }
            } message: {
                Text("This will permanently delete all your data. This action cannot be undone.")
            }
        }
    }
}
