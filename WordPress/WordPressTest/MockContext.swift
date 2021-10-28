import XCTest
import CoreData

@testable import WordPress

class MockFetchResult: NSAsynchronousFetchResult<NSFetchRequestResult> {
    let results: [NSFetchRequestResult]?

    init(results: [NSFetchRequestResult]?) {
        self.results = results
    }

    override open var finalResult: [NSFetchRequestResult]? {
        results
    }
}

/// Mock context that uses the existing Test Core Data Stack and overrides fetch for testing purposes
class MockContext: NSManagedObjectContext {
    // set it to any array of objects you want ot return
    var returnedObjects: [NSFetchRequestResult]?

    // set it to any error you want to return so simulate fetch error
    var fetchError: Error?
    // set to false to simulate fetch error
    var success = true

    // events expectations
    var fetchExpectation: XCTestExpectation?
    var successExpectation: XCTestExpectation?
    var failureExpectation: XCTestExpectation?

#if compiler(>=5.5)
    override open func execute(_ request: NSPersistentStoreRequest) throws -> NSPersistentStoreResult {
        fetchExpectation?.fulfill()
        guard success else {
            failureExpectation?.fulfill()
            throw fetchError!
        }
        successExpectation?.fulfill()

        return MockFetchResult(results: returnedObjects)
    }
#else
    override func fetch(_ request: NSFetchRequest<NSFetchRequestResult>) throws -> [Any] {
         override
         open func execute(_ request: NSPersistentStoreRequest) throws -> NSPersistentStoreResult {
             fetchExpectation?.fulfill()
             guard success else {
                 failureExpectation?.fulfill()
                 throw fetchError!
             }
             successExpectation?.fulfill()
             return returnedObjects!

             return MockFetchResult(results: returnedObjects)
         }
    }
#endif
}
