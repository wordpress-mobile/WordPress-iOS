import UIKit
import XCTest
import WordPress

class ReaderStreamViewControllerTests: XCTestCase {

    // Tests that a ReaderStreamViewController is returned
    func testControllerWithTopic() {
        let context = TestContextManager.sharedInstance().mainContext
        var topic = NSEntityDescription.insertNewObjectForEntityForName("ReaderTopic", inManagedObjectContext: context) as! ReaderTopic
        var controller = ReaderStreamViewController.controllerWithTopic(topic)
        XCTAssertNotNil(controller, "Controller should not be nil")
    }

    func testControllerWithSiteID() {
        var controller = ReaderStreamViewController.controllerWithSiteID(NSNumber(int: 1))
        XCTAssertNotNil(controller, "Controller should not be nil")
    }

}


