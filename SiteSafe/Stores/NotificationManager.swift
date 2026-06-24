//
//  NotificationManager.swift
//  SiteSafe
//
//  Thin wrapper over UNUserNotificationCenter. Schedules real, repeating daily
//  local reminders (run the briefing, close out hazards, check barriers) and
//  cancels them by stable identifier.
//

import Foundation
import UserNotifications
import SwiftUI

final class NotificationManager: ObservableObject {
    static let shared = NotificationManager()

    @Published var isAuthorized = false
    @Published var denied = false

    enum Reminder: String, CaseIterable, Identifiable {
        case briefing = "sitesafe.reminder.briefing"
        case hazards  = "sitesafe.reminder.hazards"
        case barriers = "sitesafe.reminder.barriers"

        var id: String { rawValue }
        var title: String {
            switch self {
            case .briefing: return "Run the toolbox talk"
            case .hazards:  return "Close out open hazards"
            case .barriers: return "Check barriers & edge protection"
            }
        }
        var body: String {
            switch self {
            case .briefing: return "Brief the crew and pass the PPE check before opening the shift."
            case .hazards:  return "Review the hazard log and progress any open items."
            case .barriers: return "Walk the site — guardrails, walkways, lighting and electrics."
            }
        }
        var icon: String {
            switch self {
            case .briefing: return "megaphone.fill"
            case .hazards:  return "exclamationmark.triangle.fill"
            case .barriers: return "checklist"
            }
        }
        var defaultHour: Int {
            switch self {
            case .briefing: return 7
            case .hazards:  return 12
            case .barriers: return 16
            }
        }
        var defaultMinute: Int { 0 }
    }

    private init() { refreshStatus() }

    func refreshStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isAuthorized = settings.authorizationStatus == .authorized
                    || settings.authorizationStatus == .provisional
                self.denied = settings.authorizationStatus == .denied
            }
        }
    }

    /// Requests permission. `completion` returns whether scheduling can proceed.
    func requestAuthorization(_ completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                DispatchQueue.main.async {
                    self.isAuthorized = granted
                    self.denied = !granted
                    completion(granted)
                }
            }
    }

    func schedule(_ reminder: Reminder, hour: Int, minute: Int) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [reminder.rawValue])

        let content = UNMutableNotificationContent()
        content.title = "Site Safe — \(reminder.title)"
        content.body = reminder.body
        content.sound = .default

        var comps = DateComponents()
        comps.hour = hour
        comps.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        let request = UNNotificationRequest(identifier: reminder.rawValue, content: content, trigger: trigger)
        center.add(request, withCompletionHandler: nil)
    }

    func cancel(_ reminder: Reminder) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [reminder.rawValue])
    }

    func cancelAll() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: Reminder.allCases.map { $0.rawValue })
    }
}
