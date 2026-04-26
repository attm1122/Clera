import SwiftUI

struct PermissionsView: View {
    @Environment(AppModel.self) private var appModel
    var onComplete: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: CleraSpacing.lg) {
                CleraSectionHeader(
                    eyebrow: CleraCopy.Permissions.title,
                    title: CleraCopy.Permissions.subtitle,
                    subtitle: CleraCopy.Permissions.body
                )
                .padding(.top, CleraSpacing.xl)

                permissionRow(
                    icon: "camera.fill",
                    title: CleraCopy.Permissions.cameraTitle,
                    description: CleraCopy.Permissions.cameraBody,
                    granted: appModel.permissionState.cameraGranted
                ) {
                    appModel.updatePermissions(
                        PermissionState(
                            cameraGranted: true,
                            photoLibraryGranted: appModel.permissionState.photoLibraryGranted,
                            notificationsGranted: appModel.permissionState.notificationsGranted
                        )
                    )
                }

                permissionRow(
                    icon: "photo.on.rectangle",
                    title: CleraCopy.Permissions.photoLibraryTitle,
                    description: CleraCopy.Permissions.photoLibraryBody,
                    granted: appModel.permissionState.photoLibraryGranted
                ) {
                    appModel.updatePermissions(
                        PermissionState(
                            cameraGranted: appModel.permissionState.cameraGranted,
                            photoLibraryGranted: true,
                            notificationsGranted: appModel.permissionState.notificationsGranted
                        )
                    )
                }

                permissionRow(
                    icon: "bell.fill",
                    title: CleraCopy.Permissions.notificationsTitle,
                    description: CleraCopy.Permissions.notificationsBody,
                    granted: appModel.permissionState.notificationsGranted
                ) {
                    appModel.updatePermissions(
                        PermissionState(
                            cameraGranted: appModel.permissionState.cameraGranted,
                            photoLibraryGranted: appModel.permissionState.photoLibraryGranted,
                            notificationsGranted: true
                        )
                    )
                }

                Button(CleraCopy.Permissions.continue) {
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

    private func permissionRow(icon: String, title: String, description: String, granted: Bool, action: @escaping () -> Void) -> some View {
        CleraCard {
            HStack(spacing: CleraSpacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundStyle(granted ? CleraColor.success : CleraColor.accent)
                    .frame(width: 40, height: 40)
                    .background(
                        RoundedRectangle(cornerRadius: CleraRadius.medium, style: .continuous)
                            .fill(granted ? CleraColor.success.opacity(0.1) : CleraColor.accentSoft)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(CleraColor.textPrimary)
                    Text(description)
                        .font(.system(size: 13))
                        .foregroundStyle(CleraColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                if granted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(CleraColor.success)
                        .font(.system(size: 24))
                } else {
                    Button(action: action) {
                        Text(CleraCopy.Permissions.allow)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(CleraColor.accent)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: CleraRadius.pill, style: .continuous)
                                    .fill(CleraColor.accentSoft)
                            )
                    }
                }
            }
        }
    }
}
