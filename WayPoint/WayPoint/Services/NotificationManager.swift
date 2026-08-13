//
//  NotificationManager.swift
//  WayPoint
//

import SwiftUI
import UserNotifications
import Observation

@MainActor
@Observable
class NotificationManager {
    static let shared = NotificationManager()

    var isAuthorized: Bool = false
    var scheduledAlertsCount: Int = 0

    init() {
        Task {
            await checkAuthorizationStatus()
        }
    }

    func checkAuthorizationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        isAuthorized = settings.authorizationStatus == .authorized
    }

    func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
            isAuthorized = granted
            return granted
        } catch {
            isAuthorized = false
            return false
        }
    }

    func scheduleFlightAlert(title: String, body: String, timeInterval: TimeInterval) {
        guard isAuthorized else { return }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, timeInterval), repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { _ in
            Task { @MainActor in
                self.scheduledAlertsCount += 1
            }
        }
    }

    func scheduleActivityReminder(item: ItineraryItem) {
        guard isAuthorized else { return }

        let content = UNMutableNotificationContent()
        content.title = "Upcoming: \(item.title)"
        content.body = "\(item.timeRange) · \(item.location)"
        content.sound = .default

        let timeUntilActivity = item.startTime.timeIntervalSinceNow - 900
        let triggerInterval = max(5, timeUntilActivity > 0 ? timeUntilActivity : 10)

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: triggerInterval, repeats: false)
        let request = UNNotificationRequest(identifier: item.id.uuidString, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { _ in
            Task { @MainActor in
                self.scheduledAlertsCount += 1
            }
        }
    }
}
