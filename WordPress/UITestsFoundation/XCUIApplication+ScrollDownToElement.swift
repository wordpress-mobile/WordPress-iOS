import XCTest

// Taken from https://stackoverflow.com/a/46943935
extension XCUIApplication {
    private struct Constants {
        // Half way accross the screen and 40% from top
        static let topOffset = CGVector(dx: 0.5, dy: 0.4)

        // Half way accross the screen and 70% from top
        static let bottomOffset = CGVector(dx: 0.5, dy: 0.7)
    }

    var screenTopCoordinate: XCUICoordinate {
        return windows.firstMatch.coordinate(withNormalizedOffset: Constants.topOffset)
    }

    var screenBottomCoordinate: XCUICoordinate {
        return windows.firstMatch.coordinate(withNormalizedOffset: Constants.bottomOffset)
    }

    /// Scrolls down to element until it becomes hittable.
    /// After that attempts to scroll it to the screen top.
    func scrollDownToElement(element: XCUIElement, maxScrolls: Int = 10) {
        for _ in 0..<maxScrolls {
            if !element.isFullyVisibleOnScreen() {
                scrollDown()
            }
        }
    }

    func scrollDown() {
        screenBottomCoordinate.press(
            forDuration: 0.1,
            thenDragTo: screenTopCoordinate,
            withVelocity: XCUIGestureVelocity.slow,
            thenHoldForDuration: 0.1
        )
    }
}
