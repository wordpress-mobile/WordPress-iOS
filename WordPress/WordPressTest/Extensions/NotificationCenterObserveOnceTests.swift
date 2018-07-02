import XCTest
@testable import WordPress

private let counterKey = "counter"

class NotificationCenterObserveOnceTests: XCTestCase {
    let testNotification = Notification.Name("NotificationCenterObserveOnceTestNotification")
    let notificationCenter = NotificationCenter.default
    var observer: NSObjectProtocol?

    override func tearDown() {
        super.tearDown()
        if let observer = observer {
            notificationCenter.removeObserver(observer)
        }
        observer = nil
    }

    func testNotificationIsOnlyReceivedOnce() {
        var timesReceived = 0
        observer = notificationCenter.observeOnce(forName: testNotification, object: nil, queue: nil, using: { (_) in
            timesReceived += 1
        })
        notificationCenter.post(name: testNotification, object: nil)
        XCTAssertEqual(timesReceived, 1, "Observer should get the notification once")
        notificationCenter.post(name: testNotification, object: nil)
        XCTAssertEqual(timesReceived, 1, "Observer should get the notification only once")
    }

    func testNotificationIsOnlyReceivedWhenMatchesFilter() {
        var timesReceived = 0
        observer = notificationCenter.observeOnce(forName: testNotification, object: nil, queue: nil, using: { (_) in
            timesReceived += 1
        }, filter: { (notification) in
            guard let counter = notification.userInfo?[counterKey] as? Int else {
                return false
            }
            return counter > 2
        })
        notificationCenter.post(notification(counter: 0))
        XCTAssertEqual(timesReceived, 0, "Observer should not receive the notification for counter < 2")
        notificationCenter.post(notification(counter: 1))
        XCTAssertEqual(timesReceived, 0, "Observer should not receive the notification for counter < 2")
        notificationCenter.post(notification(counter: 2))
        XCTAssertEqual(timesReceived, 0, "Observer should not receive the notification for counter < 2")
        notificationCenter.post(notification(counter: 3))
        XCTAssertEqual(timesReceived, 1, "Observer should get the notification once")
        notificationCenter.post(notification(counter: 4))
        XCTAssertEqual(timesReceived, 1, "Observer should get the notification only once")
    }

    private func notification(counter: Int) -> Foundation.Notification {
        return Notification(name: testNotification, object: nil, userInfo: [counterKey: counter])
    }

}
