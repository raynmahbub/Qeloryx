// QELORYX — Platform/Notifications
// NotificationsManager.swift
// UserNotifications adapter. The permission is only requested in context, at
// the moment a reminder-like feature needs it — never at launch.

import Foundation

#if canImport(UserNotifications)
import UserNotifications

@MainActor
public final class AstryxNotificationsManager {

    public static let shared = AstryxNotificationsManager()

    private let center: UNUserNotificationCenter

    public init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }


    /// Requests alert+sound authorization. Returns the granted state.
    public func requestAuthorization() async -> Bool {
        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            #if DEBUG
            debugPrint("[Notifications] Authorization failed: \(error)")
            #endif
            return false
        }
    }

    public func currentStatus() async -> UNAuthorizationStatus {
        await center.notificationSettings().authorizationStatus
    }
}
#endif
