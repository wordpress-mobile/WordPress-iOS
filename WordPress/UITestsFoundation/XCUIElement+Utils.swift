import XCTest

// TODO: This should go XCUITestHelpers if not there already
public extension XCUIElement {

    func scroll(byDeltaX deltaX: CGFloat, deltaY: CGFloat) {
        let startCoordinate = self.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0))
        let destination = startCoordinate.withOffset(CGVector(dx: deltaX, dy: deltaY * -1))

        startCoordinate.press(forDuration: 0.01, thenDragTo: destination)
    }

    // Returns true if the XCUIElement is within a visible area,
    // defined by the vertical space between two other elements
    // and the device screen width.
    func isWithinVisibleArea(_ topElement: XCUIElement = XCUIApplication().navigationBars.firstMatch,
                             _ bottomElement: XCUIElement = XCUIApplication().tabBars.firstMatch,
                             app: XCUIApplication = XCUIApplication()) -> Bool {
        guard exists && frame.isEmpty == false && isHittable else { return false }

        let deviceScreenFrame = app.windows.element(boundBy: 0).frame
        let deviceScreenWidth = deviceScreenFrame.size.width
        let visibleAreaTop: CGFloat

        if topElement.exists {
            visibleAreaTop = topElement.frame.origin.y + topElement.frame.size.height
        } else {
            visibleAreaTop = deviceScreenFrame.origin.y
        }

        let visibleAreaHeight = bottomElement.frame.origin.y - visibleAreaTop
        let visibleAreaFrame = CGRect(x: 0, y: visibleAreaTop, width: deviceScreenWidth, height: visibleAreaHeight)

        return visibleAreaFrame.contains(frame)
    }
}
