import Foundation
import XCTest
import CoreData

@testable import WordPress


class CoreDataHelperTests: XCTestCase
{
    var contextManager: TestContextManager!

    override func setUp() {
        super.setUp()
        contextManager = TestContextManager()
    }

    override func tearDown() {
        super.tearDown()
        contextManager.mainContext.reset()
        ContextManager.overrideSharedInstance(nil)
    }

    func testSomething() {


        NSLog("HERE")
    }
}
