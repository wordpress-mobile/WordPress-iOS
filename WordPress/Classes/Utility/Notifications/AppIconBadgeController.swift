import Foundation
import Logging
import UserNotifications

/// Writes the home-screen app icon badge through the supported UserNotifications
/// API (`setBadgeCount`). Replaces the deprecated `applicationIconBadgeNumber`
/// setter.
protocol AppIconBadgeWriting {
    /// Requests the icon badge show `count`, coalescing to the latest requested
    /// value so a slow older write cannot restore an earlier one.
    func setBadgeCount(_ count: Int)
}

/// Callers use this only on the main thread (via the main-actor
/// ``NotificationActivityService``), so its state needs no extra synchronization.
final class AppIconBadgeController: AppIconBadgeWriting {
    private let center: UNUserNotificationCenter
    private var isWriting = false
    private var latestDesired: Int?
    // Set when a request is waiting to be written. Every `setBadgeCount` issues a
    // real write: the controller does not track the OS badge state, because iOS
    // applies `aps.badge` at delivery whether or not the app runs, so an assumed
    // "already 0" would wrongly skip a needed clear.
    private var hasPendingRequest = false
    private var retryCount = 0
    private let maxRetries = 3
    private let retryDelay: TimeInterval = 2

    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    func setBadgeCount(_ count: Int) {
        latestDesired = max(0, count)
        hasPendingRequest = true
        retryCount = 0 // A fresh intent gets a full retry budget.
        pump()
    }

    private func pump() {
        guard !isWriting, hasPendingRequest, let desired = latestDesired else {
            return
        }
        hasPendingRequest = false
        isWriting = true
        center.setBadgeCount(desired) { [weak self] error in
            DispatchQueue.main.async {
                guard let self else { return }
                self.isWriting = false
                if let error {
                    Loggers.app.error("Failed to set app icon badge count: \(error)")
                    // No other driver may follow (e.g. after sign-out), so retry a
                    // bounded number of times rather than strand a stale badge.
                    self.hasPendingRequest = true
                    self.scheduleRetryAfterFailure()
                } else {
                    self.retryCount = 0
                    // Writes again only if a newer request arrived mid-flight.
                    self.pump()
                }
            }
        }
    }

    private func scheduleRetryAfterFailure() {
        guard retryCount < maxRetries else {
            return
        }
        retryCount += 1
        DispatchQueue.main.asyncAfter(deadline: .now() + retryDelay) { [weak self] in
            self?.pump()
        }
    }
}
