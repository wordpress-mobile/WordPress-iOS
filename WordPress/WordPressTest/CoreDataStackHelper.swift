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
        // Create the test observer singleton to add it to `XCTestObservationCenter`.
        _ = AutomaticTeardownTestObserver.instance

        setUpAsSharedInstance()

        // This closure is going to be called by the test observer below when
        // the test case finishes. The reason a combination of storing a closure in
        // `XCTestCase` instance and a dedicated `XCTestObservation` implementation
        // is used here is, we need to make sure tearing down the `ContextManager`
        // mock instance happens _after_ test finishes execution.
        //
        // XCTest does have an API allowing us to add our own teardown block:
        // `XCTestCase.addTeardownBlock`, but the added block is called _before_
        // the test case's `tearDown` override method. Which means if this official
        // API is used here instead, `ContextManager.shared` references two different
        // objects during test execution: the mock instance before `tearDown`, or the
        // real singleton during `tearDown`, which isn't ideal.
        testCase.additionalTeardown = { [weak self] in
            self?.tearDown()
        }
    }
}

private class AutomaticTeardownTestObserver: NSObject, XCTestObservation {

    static let instance = AutomaticTeardownTestObserver()

    private override init() {
        super.init()
        XCTestObservationCenter.shared.addTestObserver(self)
    }

    func testCaseDidFinish(_ testCase: XCTestCase) {
        testCase.additionalTeardown?()
    }

}

private var additionalTeardownKey: Int = 0
private extension XCTestCase {

    var additionalTeardown: (() -> Void)? {
        set {
            objc_setAssociatedObject(self, &additionalTeardownKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
        }
        get {
            objc_getAssociatedObject(self, &additionalTeardownKey) as? (() -> Void)
        }
    }

}
