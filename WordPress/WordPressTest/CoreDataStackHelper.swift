import Combine
import XCTest

@testable import WordPress

extension ContextManagerMock {
    /// Override `ContextManager.shared` with the mock instance, and un-override it when
    /// given `testCase` finishes.
    ///
    /// This method should be called during test run, typically from `XCTestCase` subclass's
    /// `setUp` method or test methods.
    ///
    /// - Parameter testCase: The test case to wait for.
    @objc func useAsSharedInstanceUntilTestFinished(_ testCase: XCTestCase) {
        setUpAsSharedInstance()

        var cancellable: AnyCancellable?
        cancellable = AutomaticTeardownTestObserver.instance.testCaseDidFinishPublisher
            .first {
                $0 === testCase && $0.name == testCase.name
            }
            // Above publisher emits exactly one output and completes with a successful result.
            .sink { [weak self] _ in
                self?.tearDown()

                // This is an unusual pattern. A strong reference to `cancellable`
                // is captured here, so that we can receive output from the publisher.
                cancellable?.cancel()
                cancellable = nil
            }
    }
}

private class AutomaticTeardownTestObserver: NSObject, XCTestObservation {

    static let instance = AutomaticTeardownTestObserver()

    let testCaseDidFinishPublisher = PassthroughSubject<XCTestCase, Never>()

    override init() {
        super.init()
        XCTestObservationCenter.shared.addTestObserver(self)
    }

    func testCaseDidFinish(_ testCase: XCTestCase) {
        testCaseDidFinishPublisher.send(testCase)
    }

}
