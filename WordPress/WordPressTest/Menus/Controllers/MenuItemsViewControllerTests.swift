import UIKit
import XCTest

@testable import WordPress

class MenuItemsViewControllerTests: XCTestCase {

    private var context: NSManagedObjectContext!

    override func setUpWithError() throws {
        context = TestContextManager().mainContext
        try super.setUpWithError()
    }

    override func tearDownWithError() throws {
        context = nil
        TestContextManager.overrideSharedInstance(nil)
        try super.tearDownWithError()
    }

    /// Tests that no string is provided when there is nothing to announce.
    func testOrderingChangeVOStringNoChanges() {
        let noChanges = MenuItemsViewController.generateOrderingChangeVOString(nil, parentChanged: false, before: nil, after: nil)
        XCTAssertNil(noChanges)

        let newParent = MenuItem(context: context)
        newParent.name = "New Parent"

        /// This is a programming error. parentChanged should always be set to true if the parent indeed changed.
        let parentChangedFalse = MenuItemsViewController.generateOrderingChangeVOString(newParent, parentChanged: false, before: nil, after: nil)
        XCTAssertNil(parentChangedFalse)
    }

    /// Tests handling of changes to the menu item's parent.
    func testOrderingChangeVOStringParentChanged() {
        let newParent = MenuItem(context: context)
        newParent.name = "New Parent"

        /// test when the parent changed but it was the top level (no parent)
        let topLevelString = MenuItemsViewController.generateOrderingChangeVOString(nil, parentChanged: true, before: nil, after: nil)
        XCTAssertEqual(topLevelString, "Top level")

        /// test when the parent changed and it was a menu item
        let newParentString = MenuItemsViewController.generateOrderingChangeVOString(newParent, parentChanged: true, before: nil, after: nil)
        XCTAssertEqual(newParentString, "Child of New Parent")
    }

    /// Tests handling of changes to the menu item's parent and order.
    func testOrderingChangeVOString() {
        let newParent = MenuItem(context: context)
        newParent.name = "New Parent"

        let afterItem = MenuItem(context: context)
        afterItem.name = "Item A"

        let beforeItem = MenuItem(context: context)
        beforeItem.name = "Item B"

        let beforeString = MenuItemsViewController.generateOrderingChangeVOString(nil, parentChanged: false, before: beforeItem, after: nil)
        XCTAssertEqual(beforeString, "Before Item B")

        let afterString = MenuItemsViewController.generateOrderingChangeVOString(nil, parentChanged: false, before: nil, after: afterItem)
        XCTAssertEqual(afterString, "After Item A")

        let parentAndBeforeString = MenuItemsViewController.generateOrderingChangeVOString(newParent, parentChanged: true, before: beforeItem, after: nil)
        XCTAssertEqual(parentAndBeforeString, "Child of New Parent. Before Item B")

        let parentAndBeforeAndAfterString = MenuItemsViewController.generateOrderingChangeVOString(newParent, parentChanged: true, before: beforeItem, after: afterItem)
        XCTAssertEqual(parentAndBeforeAndAfterString, "Child of New Parent. After Item A. Before Item B")
    }

}
