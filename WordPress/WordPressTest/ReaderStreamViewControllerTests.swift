import UIKit
import XCTest
import WordPress

class ReaderStreamViewControllerTests: XCTestCase {

    // Tests that a ReaderStreamViewController is returned
    func testControllerWithTopic() {
        let context = TestContextManager.sharedInstance().mainContext
        let topic = NSEntityDescription.insertNewObjectForEntityForName("ReaderTagTopic", inManagedObjectContext: context) as! ReaderTagTopic
        topic.path = "foo"

        let controller = ReaderStreamViewController.controllerWithTopic(topic)
        XCTAssertNotNil(controller, "Controller should not be nil")
    }

    func testControllerWithSiteID() {
        let controller = ReaderStreamViewController.controllerWithSiteID(NSNumber(int: 1), isFeed:false)
        XCTAssertNotNil(controller, "Controller should not be nil")
    }

}


