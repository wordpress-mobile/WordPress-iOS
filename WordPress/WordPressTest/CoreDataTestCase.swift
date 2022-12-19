import XCTest
import WordPress

/// A `XCTestCase` subclass which manages a mock implementation of `CoreDataStack`. Inherit
/// from this class to use the `CoreDataStack` mock instance in your test case.
class CoreDataTestCase: XCTestCase {

    private(set) lazy var contextManager: ContextManager = {
        ContextManager.forTesting()
    }()

    var mainContext: NSManagedObjectContext {
        return contextManager.mainContext
    }

}

extension XCTestCase {

    @objc func coreDataStackForTesting() -> CoreDataStack {
        ContextManager.forTesting()
    }

}
