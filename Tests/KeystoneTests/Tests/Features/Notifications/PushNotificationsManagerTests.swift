import Testing
import UIKit

@testable import WordPress

@MainActor
struct PushNotificationsManagerTests {
    @Test(
        arguments: [
            [:],
            ["type": 123],
            ["type": "badge-reset"]
        ] as [[String: any Sendable]]
    )
    func ignoredNotificationCompletesWithNoData(payload: [String: any Sendable]) {
        var results: [UIBackgroundFetchResult] = []

        PushNotificationsManager.shared.handleNotification(payload as NSDictionary) { results.append($0) }

        #expect(results == [.noData])
    }

    @Test(
        arguments: [
            ["type": "unknown"],
            ["type": "unknown", "note_id": "invalid"]
        ] as [[String: any Sendable]]
    )
    func unhandledNotificationCompletesEachDelivery(payload: [String: any Sendable]) {
        for _ in 0..<2 {
            var results: [UIBackgroundFetchResult] = []

            PushNotificationsManager.shared.handleNotification(payload as NSDictionary) { results.append($0) }

            #expect(results == [.noData])
        }
    }

    @Test func authenticationNotificationPreservesHandlerResult() {
        var results: [UIBackgroundFetchResult] = []

        PushNotificationsManager.shared.handleNotification(["type": "push_auth"]) { results.append($0) }

        #expect(results == [.newData])
    }

    @Test func notificationsAllowNilCompletion() {
        let manager = PushNotificationsManager.shared
        manager.handleNotification([:], completionHandler: nil)
        manager.handleNotification(["type": "unknown"], completionHandler: nil)
        manager.handleNotification(["type": "push_auth"], completionHandler: nil)
    }
}
