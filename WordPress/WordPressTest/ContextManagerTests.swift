import Foundation
import XCTest

class ContextManagerTests: XCTestCase {
    var contextManager:TestContextManager!

    override func setUp() {
        super.setUp()
        
        contextManager = TestContextManager()
    }
    
    override func tearDown() {
        super.tearDown()
    }

    func testExample() {
        XCTAssertNotNil(contextManager.mainContext, "Context should not be nil");
        XCTAssertNil(contextManager.mainContext.parentContext, "There should be no parent context.");
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock() {
            // Put the code you want to measure the time of here.
        }
    }

}
