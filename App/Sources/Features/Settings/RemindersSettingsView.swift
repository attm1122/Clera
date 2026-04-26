import SwiftUI

struct RemindersSettingsView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.dismiss) private var dismiss
    @State private var isAuthorized = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Enable reminders", isOn: Bindable(appModel).reminderSettings.enabled)
                        .tint(CleraColor.accent)
                        .onChange(of: appModel.reminderSettings.enabled) { _, newValue in
                            if newValue {
                                Task {
                                    let granted = await NotificationManager.shared.requestAuthorization()
                                    isAuthorized = granted
                                    if granted {
                                        NotificationManager.shared.scheduleReminders(settings: appModel.reminderSettings)
                                    } else {
                                        appModel.reminderSettings.enabled = false
                                    }
                                }
                            } else {
                                NotificationManager.shared.cancelAllReminders()
                            }
                        }

                    if !isAuthorized && appModel.reminderSettings.enabled {
                        Text("Notification permission required. Enable in Settings.")
                            .font(.system(size: 13))
                            .foregroundStyle(.red)
                    }
                }

                if appModel.reminderSettings.enabled {
                    Section("Time") {
                        DatePicker("Reminder time", selection: Bindable(appModel).reminderSettings.preferredTime, displayedComponents: .hourAndMinute)
                            .datePickerStyle(.compact)
                            .tint(CleraColor.accent)
                            .onChange(of: appModel.reminderSettings.preferredTime) { _, _ in
                                NotificationManager.shared.scheduleReminders(settings: appModel.reminderSettings)
                            }
                    }

                    Section("Cadence") {
                        Picker("How often", selection: Bindable(appModel).reminderSettings.cadence) {
                            ForEach(Array(ReminderCadence.allCases), id: \.self) { cadence in
                                Text(cadence.displayName).tag(cadence)
                            }
                        }
                        .onChange(of: appModel.reminderSettings.cadence) { _, _ in
                            NotificationManager.shared.scheduleReminders(settings: appModel.reminderSettings)
                        }
                    }
                }
            }
            .navigationTitle("Reminders")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(CleraColor.textSecondary)
                }
            }
            .task {
                let settings = await UNUserNotificationCenter.current().notificationSettings()
                isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
}
