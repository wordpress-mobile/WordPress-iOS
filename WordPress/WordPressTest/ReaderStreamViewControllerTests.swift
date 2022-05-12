import UIKit
import XCTest
@testable import WordPress

class ReaderStreamViewControllerTests: XCTestCase {
    private var contextManager: ContextManagerMock!

    override func setUp() {
        contextManager = ContextManagerMock()
    }

    // Tests that a ReaderStreamViewController is returned
    func testControllerWithTopic() {
        let context = contextManager.mainContext
        let topic = NSEntityDescription.insertNewObject(forEntityName: "ReaderTagTopic", into: context) as! ReaderTagTopic
        topic.path = "foo"

        let controller = ReaderStreamViewController.controllerWithTopic(topic)
        XCTAssertNotNil(controller, "Controller should not be nil")
    }

    func testControllerWithSiteID() {
        let controller = ReaderStreamViewController.controllerWithSiteID(NSNumber(value: 1), isFeed: false)
        XCTAssertNotNil(controller, "Controller should not be nil")
    }
}
