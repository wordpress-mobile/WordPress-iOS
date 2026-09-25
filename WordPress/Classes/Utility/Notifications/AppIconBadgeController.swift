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

    /// Retries a retained request whose automatic retries ran out, with a fresh
    /// retry budget. Does nothing when no request is waiting.
    func retryPendingWrite()
}

/// Callers use this only on the main thread (via the main-actor
/// ``NotificationActivityService``), so its state needs no extra synchronization.
final class AppIconBadgeController: AppIconBadgeWriting {
    /// Writes `count` to the icon and reports the outcome. Injected so tests can
    /// control completion order and failures.
    typealias BadgeCountSetter = (_ count: Int, _ completion: @escaping (Error?) -> Void) -> Void

    private let setSystemBadgeCount: BadgeCountSetter
    private var isWriting = false
    // The count waiting to be written, if any. Every `setBadgeCount` issues a
    // real write: the controller does not track the OS badge state, because iOS
    // applies `aps.badge` at delivery whether or not the app runs, so an assumed
    // "already 0" would wrongly skip a needed clear.
    private var pendingCount: Int?
    private var retryCount = 0
    private let maxRetries = 3
    private let retryDelay: TimeInterval

    init(
        retryDelay: TimeInterval = 2,
        setSystemBadgeCount: @escaping BadgeCountSetter = { count, completion in
            UNUserNotificationCenter.current().setBadgeCount(count) { completion($0) }
        }
    ) {
        self.retryDelay = retryDelay
        self.setSystemBadgeCount = setSystemBadgeCount
    }

    func setBadgeCount(_ count: Int) {
        pendingCount = max(0, count)
        retryCount = 0 // A fresh intent gets a full retry budget.
        pump()
    }

    func retryPendingWrite() {
        guard pendingCount != nil else {
            return
        }
        retryCount = 0
        pump()
    }

    private func pump() {
        guard !isWriting, let desired = pendingCount else {
            return
        }
        pendingCount = nil
        isWriting = true
        setSystemBadgeCount(desired) { [weak self] error in
            DispatchQueue.main.async {
                guard let self else { return }
                self.isWriting = false
                if let error {
                    Loggers.app.error("Failed to set app icon badge count: \(error)")
                    // No other driver may follow (e.g. after sign-out), so retry a
                    // bounded number of times rather than strand a stale badge. A
                    // newer request that arrived mid-flight takes precedence.
                    self.pendingCount = self.pendingCount ?? desired
                    self.scheduleRetryAfterFailure()
                } else {
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
