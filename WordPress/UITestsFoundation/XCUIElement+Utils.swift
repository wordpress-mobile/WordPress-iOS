import XCTest

// TODO: This should go XCUITestHelpers if not there already
public extension XCUIElement {

    func scroll(byDeltaX deltaX: CGFloat, deltaY: CGFloat) {
        let startCoordinate = self.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0))
        let destination = startCoordinate.withOffset(CGVector(dx: deltaX, dy: deltaY * -1))

        startCoordinate.press(forDuration: 0.01, thenDragTo: destination)
    }
}
