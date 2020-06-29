import XCTest
import CoreData

@testable import WordPress

/// Mock context that uses the existing Test Core Data Stack and overrides fetch for testing purposes
class MockContext: NSManagedObjectContext {
    // set it to any array of objects you want ot return
    var returnedObjects: [Any]?
    // set it to any error you want to return so simulate fetch error
    var fetchError: Error?
    // set to false to simulate fetch error
    var success = true

    // events expectations
    var fetchExpectation: XCTestExpectation?
    var successExpectation: XCTestExpectation?
    var failureExpectation: XCTestExpectation?

    override func fetch(_ request: NSFetchRequest<NSFetchRequestResult>) throws -> [Any] {
        fetchExpectation?.fulfill()
        guard success else {
            failureExpectation?.fulfill()
            throw fetchError!
        }
        successExpectation?.fulfill()
        return returnedObjects!
    }

    class func getContext() -> MockContext? {
            let managedObjectContext = MockContext(concurrencyType: .privateQueueConcurrencyType)
            managedObjectContext.persistentStoreCoordinator = ContextManager.sharedInstance().persistentStoreCoordinator
            return managedObjectContext
    }
}
