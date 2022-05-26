import XCTest

@testable import WordPress

class ContextManagerMock: ContextManager {

    /// Create an in memory database using the current version of the data model.
    convenience init() {
        self.init(modelName: ContextManagerModelNameCurrent)
    }

    /// Create an in memory database using given `modelName`.
    ///
    /// - SeeAlso `ContextManager`
    init(modelName: String) {
        super.init(modelName: modelName, store: ContextManager.inMemoryStoreURL)
    }

    override func saveContextAndWait(_ context: NSManagedObjectContext) {
        super.saveContextAndWait(context)
        // FIXME: Remove this method to use superclass one instead
        //
        // This log resolves a deadlock in
        // `DashboardCardTests.testShouldNotShowQuickStartIfDefaultSectionIsSiteMenu`
        //
        // Unfortunately, we're not sure why.
        NSLog("Context save completed")
    }

    /// Override `ContextManager.shared` with the mock instance, and un-override it when
    /// given `testCase` finishes.
    ///
    /// This method should be called during test set up, typically from `XCTestCase` subclass's
    /// `setUp` method.
    ///
    /// - Parameter testCase: The test case to wait for.
    @objc func useAsSharedInstance(untilTestFinished testCase: XCTestCase) {
        // Create the test observer singleton to add it to `XCTestObservationCenter`.
        _ = AutomaticTeardownTestObserver.instance

        let original = ContextManager.overrideInstance
        ContextManager.overrideSharedInstance(self)

        // This closure is going to be called by the test observer below when
        // the test case finishes. The reason a combination of storing a closure in
        // `XCTestCase` instance and a dedicated `XCTestObservation` implementation
        // is used here is, we need to make sure tearing down the `ContextManager`
        // mock instance happens _after_ test finishes execution.
        //
        // XCTest does have an API allowing us to add our own teardown block:
        // `XCTestCase.addTeardownBlock`, but the added block is called _before_
        // the test case's `tearDown` override method. Which means if this official
        // API is used here instead, then calling `ContextManager.shared` (explicitly
        // or indirectly) during the test's `tearDown` would call the real singleton
        // instead of the mock, which isn't ideal and could have unintended side effect.
        testCase.additionalTeardown = { [weak self] in
            guard let self = self else {
                return
            }
            self.mainContext.reset()
            if ContextManager.overrideInstance === self {
                ContextManager.overrideSharedInstance(original)
            }
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
        testCase.additionalTeardown = nil
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
