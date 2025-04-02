import XCTest
import WordPressData

/// A `XCTestCase` subclass which manages a mock implementation of `CoreDataStack`. Inherit
/// from this class to use the `CoreDataStack` mock instance in your test case.
// FIXME: Currently duplicated from WordPressTests for ease of working. Eventually, should be extracted in a WordPressDataTestsHelper framework to share here and with the consumers.
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
