import XCTest
import WordPressData

@testable import WordPress

/// A `XCTestCase` subclass which manages a mock implementation of `ContextManager`. Inherit
/// from this class to use the `ContextManager` mock instance in your test case.
class CoreDataTestCase: XCTestCase {

    private(set) lazy var contextManager: ContextManager = {
        ContextManager.forTesting()
    }()

    var mainContext: NSManagedObjectContext {
        return contextManager.mainContext
    }

}

extension XCTestCase {

    @objc public func coreDataStackForTesting() -> ContextManager {
        ContextManager.forTesting()
    }

}
