import XCTest

extension XCTestCase {
    func expectNotification(name: String, timeout: NSTimeInterval = 5, block: () -> Void) {
        let notificationCenter = NSNotificationCenter.defaultCenter()
        let expectation = expectationWithDescription("NSNotification \(name)")
        let observer = notificationCenter.addObserverForName(name, object: nil, queue: nil) { note in
            expectation.fulfill()
        }
        block()
        waitForExpectationsWithTimeout(timeout, handler: nil)
        notificationCenter.removeObserver(observer)
    }
}
