import XCTest

class MenuItemsViewControllerTests: CoreDataTestCase {

    /// Tests that no string is provided when there is nothing to announce.
    func testOrderingChangeVOStringNoChanges() {
        let noChanges = MenuItemsViewController.generateOrderingChangeVOString(
            nil,
            parentChanged: false,
            before: nil,
            after: nil
        )
        XCTAssertNil(noChanges)

        let newParent = newMenuItem(named: "New Parent")

        /// This is a programming error. parentChanged should always be set to true if the parent indeed changed.
        let parentChangedFalse = MenuItemsViewController.generateOrderingChangeVOString(
            newParent,
            parentChanged: false,
            before: nil,
            after: nil
        )
        XCTAssertNil(parentChangedFalse)
    }

    /// Tests handling of changes to the menu item's parent.
    func testOrderingChangeVOStringParentChanged() {
        let newParent = newMenuItem(named: "New Parent")

        let topLevelString = MenuItemsViewController.generateOrderingChangeVOString(
            nil,
            parentChanged: true,
            before: nil,
            after: nil
        )
        XCTAssertEqual(topLevelString, "Top level")

        let newParentString = MenuItemsViewController.generateOrderingChangeVOString(
            newParent,
            parentChanged: true,
            before: nil,
            after: nil
        )
        XCTAssertEqual(newParentString, "Child of New Parent")
    }

    /// Tests handling of changes to the menu item's parent and order.
    func testOrderingChangeVOString() {
        let newParent = newMenuItem(named: "New Parent")
        let afterItem = newMenuItem(named: "Item A")
        let beforeItem = newMenuItem(named: "Item B")

        let beforeString = MenuItemsViewController.generateOrderingChangeVOString(
            nil,
            parentChanged: false,
            before: beforeItem,
            after: nil
        )
        XCTAssertEqual(beforeString, "Before Item B")

        let afterString = MenuItemsViewController.generateOrderingChangeVOString(
            nil,
            parentChanged: false,
            before: nil,
            after: afterItem
        )
        XCTAssertEqual(afterString, "After Item A")

        let parentAndBeforeString = MenuItemsViewController.generateOrderingChangeVOString(
            newParent,
            parentChanged: true,
            before: beforeItem,
            after: nil
        )
        XCTAssertEqual(parentAndBeforeString, "Child of New Parent. Before Item B")

        let parentAndBeforeAndAfterString = MenuItemsViewController.generateOrderingChangeVOString(
            newParent,
            parentChanged: true,
            before: beforeItem,
            after: afterItem
        )
        XCTAssertEqual(parentAndBeforeAndAfterString, "Child of New Parent. After Item A. Before Item B")
    }

    // MARK: - Private Helpers

    fileprivate func newMenuItem(named name: String) -> MenuItem {
        let entityName = MenuItem.classNameWithoutNamespaces()
        let entity = NSEntityDescription.insertNewObject(forEntityName: entityName, into: mainContext)

        let menuItem = entity as! MenuItem
        // set a name to make debugging easier
        menuItem.name = name

        return menuItem
    }
}
