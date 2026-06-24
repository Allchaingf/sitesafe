//
//  RemindersView.swift
//  SiteSafe — Feature 13
//
//  Daily safety reminders backed by real UNUserNotificationCenter calendar
//  triggers. Toggling one requests permission and schedules/cancels it; the
//  time picker reschedules. Settings persist in UserDefaults.
//

import SwiftUI

final class RemindersViewModel: ObservableObject {
    typealias Reminder = NotificationManager.Reminder

    struct Config: Equatable { var enabled: Bool; var time: Date }

    @Published var configs: [String: Config] = [:]
    private let manager = NotificationManager.shared
    private let defaults = UserDefaults.standard

    init() { load() }

    private func key(_ r: Reminder, _ suffix: String) -> String { "\(r.rawValue).\(suffix)" }

    private func load() {
        for r in Reminder.allCases {
            let enabled = defaults.bool(forKey: key(r, "enabled"))
            let hour = defaults.object(forKey: key(r, "hour")) as? Int ?? r.defaultHour
            let minute = defaults.object(forKey: key(r, "minute")) as? Int ?? r.defaultMinute
            configs[r.rawValue] = Config(enabled: enabled, time: dateFrom(hour: hour, minute: minute))
        }
    }

    private func dateFrom(hour: Int, minute: Int) -> Date {
        var comps = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        comps.hour = hour; comps.minute = minute
        return Calendar.current.date(from: comps) ?? Date()
    }

    func config(_ r: Reminder) -> Config { configs[r.rawValue] ?? Config(enabled: false, time: Date()) }

    private func persist(_ r: Reminder, _ config: Config) {
        let comps = Calendar.current.dateComponents([.hour, .minute], from: config.time)
        defaults.set(config.enabled, forKey: key(r, "enabled"))
        defaults.set(comps.hour ?? r.defaultHour, forKey: key(r, "hour"))
        defaults.set(comps.minute ?? 0, forKey: key(r, "minute"))
        configs[r.rawValue] = config
    }

    func setEnabled(_ r: Reminder, _ on: Bool, onResult: @escaping (Bool) -> Void) {
        var c = config(r)
        if on {
            manager.requestAuthorization { granted in
                if granted {
                    c.enabled = true
                    self.persist(r, c)
                    self.scheduleIfNeeded(r)
                    onResult(true)
                } else {
                    c.enabled = false
                    self.persist(r, c)
                    onResult(false)
                }
            }
        } else {
            c.enabled = false
            persist(r, c)
            manager.cancel(r)
            onResult(true)
        }
    }

    func setTime(_ r: Reminder, _ time: Date) {
        var c = config(r); c.time = time; persist(r, c)
        if c.enabled { scheduleIfNeeded(r) }
    }

    private func scheduleIfNeeded(_ r: Reminder) {
        let c = config(r)
        guard c.enabled else { return }
        let comps = Calendar.current.dateComponents([.hour, .minute], from: c.time)
        manager.schedule(r, hour: comps.hour ?? r.defaultHour, minute: comps.minute ?? 0)
    }
}

struct RemindersView: View {
    @EnvironmentObject var notifications: NotificationManager
    @StateObject private var vm = RemindersViewModel()
    @State private var toastMessage: String?

    var body: some View {
        ScreenScaffold("Reminders", subtitle: "Daily nudges to keep safety on track") {

            if notifications.denied {
                CardView(accent: Theme.incident) {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Notifications are off", systemImage: "bell.slash.fill")
                            .font(Theme.heading(15)).foregroundColor(Theme.textPrimary)
                        Text("Enable notifications for Site Safe in iOS Settings to receive reminders.")
                            .font(Theme.caption(12)).foregroundColor(Theme.textSecondary)
                        Button(action: openSettings) {
                            Text("Open iOS Settings").font(Theme.caption(13)).foregroundColor(Theme.primary)
                        }
                    }
                }
            }

            ForEach(NotificationManager.Reminder.allCases) { reminder in
                let config = vm.config(reminder)
                CardView(accent: config.enabled ? Theme.primary : nil) {
                    VStack(spacing: 12) {
                        ToggleRow(
                            title: reminder.title,
                            subtitle: reminder.body,
                            systemImage: reminder.icon,
                            isOn: Binding(
                                get: { config.enabled },
                                set: { on in toggle(reminder, on) }
                            )
                        )
                        if config.enabled {
                            Divider().background(Theme.stroke)
                            DatePicker("Time", selection: Binding(
                                get: { config.time },
                                set: { vm.setTime(reminder, $0) }
                            ), displayedComponents: .hourAndMinute)
                            .datePickerStyle(CompactDatePickerStyle())
                            .accentColor(Theme.primary)
                            .font(Theme.body()).foregroundColor(Theme.textPrimary)
                        }
                    }
                }
            }

            CardView {
                HStack(spacing: 10) {
                    Image(systemName: "info.circle.fill").foregroundColor(Theme.textSecondary)
                    Text("Reminders repeat every day at the set time, even when the app is closed.")
                        .font(Theme.caption(12)).foregroundColor(Theme.textSecondary)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toast($toastMessage)
        .onAppear { notifications.refreshStatus() }
    }

    private func toggle(_ reminder: NotificationManager.Reminder, _ on: Bool) {
        vm.setEnabled(reminder, on) { ok in
            if on && ok { toastMessage = "Reminder scheduled" }
            else if on && !ok { toastMessage = "Allow notifications to enable" }
            else { toastMessage = "Reminder cancelled" }
        }
    }

    private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString),
              UIApplication.shared.canOpenURL(url) else { return }
        UIApplication.shared.open(url)
    }
}
