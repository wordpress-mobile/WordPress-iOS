import XCTest

// TODO: This should go XCUITestHelpers if not there already
public extension XCUIElement {

    @discardableResult
    // TODO: When moving to framework, find name that doesn't trigger grammar warning
    func waitForHittability(timeout: TimeInterval) -> Bool {

        let predicate = NSPredicate(format: "isHittable == true")
        let elementPredicate = XCTNSPredicateExpectation(predicate: predicate, object: self)
        let result = XCTWaiter.wait(for: [elementPredicate], timeout: timeout)

        return result == .completed
    }

    var isFullyVisibleOnScreen: Bool {
        guard self.exists && !self.frame.isEmpty && self.isHittable else { return false }
        return XCUIApplication().windows.element(boundBy: 0).frame.contains(self.frame)
    }

    func scroll(byDeltaX deltaX: CGFloat, deltaY: CGFloat) {
        let startCoordinate = self.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0))
        let destination = startCoordinate.withOffset(CGVector(dx: deltaX, dy: deltaY * -1))

        startCoordinate.press(forDuration: 0.01, thenDragTo: destination)
    }
}
