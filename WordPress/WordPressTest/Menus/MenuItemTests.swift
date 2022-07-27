import XCTest
import Foundation

class MenuItemTests: CoreDataTestCase {

    /// Tests detection of descendants.
    func testIsDescendantOfItem() {
        let itemA = newMenuItem(named: "Item A")
        let itemB = newMenuItem(named: "Item B")
        let itemC = newMenuItem(named: "Item C")
        let itemD = newMenuItem(named: "Item D")
        let itemE = newMenuItem(named: "Item E")
        let itemF = newMenuItem(named: "Item F")

        /*
         Item A
         -- Item B
         ---- Item C
         Item D
         -- Item E
         -- Item F
         */

        itemB.parent = itemA
        itemC.parent = itemB
        itemE.parent = itemD
        itemF.parent = itemD

        let bIsDescendantOfA = itemB.isDescendant(of: itemA)
        XCTAssertTrue(bIsDescendantOfA)

        let cIsDescendantOfA = itemC.isDescendant(of: itemA)
        XCTAssertTrue(cIsDescendantOfA)

        let fIsDescendantOfD = itemF.isDescendant(of: itemD)
        XCTAssertTrue(fIsDescendantOfD)

        let fIsDescendantOfA = itemF.isDescendant(of: itemA)
        XCTAssertFalse(fIsDescendantOfA)
    }

    /// Tests that the last descendant of an item is found.
    func testLastDescendantInOrderedItems() {
        let itemA = newMenuItem(named: "Item A")
        let itemB = newMenuItem(named: "Item B")
        let itemC = newMenuItem(named: "Item C")
        let itemD = newMenuItem(named: "Item D")
        let itemE = newMenuItem(named: "Item E")
        let itemF = newMenuItem(named: "Item F")

        let orderedItems = NSOrderedSet(array: [
            itemA,
            itemB,
            itemC,
            itemD,
            itemE,
            itemF
        ])

        /*
         Item A
         -- Item B
         ---- Item C
         Item D
         -- Item E
         -- Item F
         */

        itemB.parent = itemA
        itemC.parent = itemB
        itemE.parent = itemD
        itemF.parent = itemD

        let lastDescendant = itemA.lastDescendant(inOrderedItems: orderedItems)
        XCTAssertEqual(lastDescendant, itemB)

        let descendantOfItemC = itemC.lastDescendant(inOrderedItems: orderedItems)
        XCTAssertEqual(descendantOfItemC, nil)

        let descendantOfItemD = itemD.lastDescendant(inOrderedItems: orderedItems)
        XCTAssertEqual(descendantOfItemD, itemF)
    }

    /// Tests that preceding siblings are found.
    func testPrecedingSiblingInOrderedItems() {
        let itemA = newMenuItem(named: "Item A")
        let itemB = newMenuItem(named: "Item B")
        let itemC = newMenuItem(named: "Item C")
        let itemD = newMenuItem(named: "Item D")
        let itemE = newMenuItem(named: "Item E")
        let itemF = newMenuItem(named: "Item F")

        let orderedItems = NSOrderedSet(array: [
            itemA,
            itemB,
            itemC,
            itemD,
            itemE,
            itemF
        ])

        /*
         Item A
         -- Item B
         ---- Item C
         Item D
         -- Item E
         -- Item F
         */

        itemB.parent = itemA
        itemC.parent = itemB
        itemE.parent = itemD
        itemF.parent = itemD

        let precedingSiblingForItemA = itemA.precedingSibling(inOrderedItems: orderedItems)
        XCTAssertNil(precedingSiblingForItemA)

        let precedingSiblingForItemD = itemD.precedingSibling(inOrderedItems: orderedItems)
        XCTAssertEqual(precedingSiblingForItemD, itemA)

        let precedingSiblingForItemF = itemF.precedingSibling(inOrderedItems: orderedItems)
        XCTAssertEqual(precedingSiblingForItemF, itemE)
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
