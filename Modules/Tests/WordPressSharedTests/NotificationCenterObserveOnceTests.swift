import Foundation
import Testing
@testable import WordPressShared

private let counterKey = "counter"

@Suite(.serialized)
final class NotificationCenterObserveOnceTests {
    let testNotification = Notification.Name("NotificationCenterObserveOnceTestNotification")
    let notificationCenter = NotificationCenter.default
    var observer: NSObjectProtocol?

    deinit {
        observer = nil
    }

    @Test func testNotificationIsOnlyReceivedOnce() {
        var timesReceived = 0
        observer = notificationCenter.observeOnce(forName: testNotification, object: nil, queue: nil, using: { _ in
            timesReceived += 1
        })
        notificationCenter.post(name: testNotification, object: nil)
        #expect(timesReceived == 1, "Observer should get the notification once")
        notificationCenter.post(name: testNotification, object: nil)
        #expect(timesReceived == 1, "Observer should get the notification only once")
    }

    @Test func testNotificationIsOnlyReceivedWhenMatchesFilter() {
        var timesReceived = 0
        observer = notificationCenter.observeOnce(forName: testNotification, object: nil, queue: nil, using: { _ in
            timesReceived += 1
        }, filter: { notification in
            guard let counter = notification.userInfo?[counterKey] as? Int else {
                return false
            }
            return counter > 2
        })
        notificationCenter.post(notification(counter: 0))
        #expect(timesReceived == 0, "Observer should not receive the notification for counter < 2")
        notificationCenter.post(notification(counter: 1))
        #expect(timesReceived == 0, "Observer should not receive the notification for counter < 2")
        notificationCenter.post(notification(counter: 2))
        #expect(timesReceived == 0, "Observer should not receive the notification for counter < 2")
        notificationCenter.post(notification(counter: 3))
        #expect(timesReceived == 1, "Observer should get the notification once")
        notificationCenter.post(notification(counter: 4))
        #expect(timesReceived == 1, "Observer should get the notification only once")
    }

    private func notification(counter: Int) -> Foundation.Notification {
        return Notification(name: testNotification, object: nil, userInfo: [counterKey: counter])
    }
}
