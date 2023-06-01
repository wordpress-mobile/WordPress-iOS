import XCTest
import XCUITestHelpers

extension XCUIElement {

    /// Scroll an element into view within another element.
    /// scrollView can be a UIScrollView, or anything that subclasses it like UITableView
    ///
    /// TODO: The implementation of this could use work:
    /// - What happens if the element is above the current scroll view position?
    /// - What happens if it's a really long scroll view?
    public func scrollIntoView(within scrollView: XCUIElement, threshold: Int = 1000) {
        var iteration = 0

        while isFullyVisibleOnScreen() == false && iteration < threshold {
            scrollView.scroll(byDeltaX: 0, deltaY: 100)
            iteration += 1
        }

        if isFullyVisibleOnScreen() == false {
            XCTFail("Unable to scroll element into view")
        }
    }

    // Taken from https://stackoverflow.com/a/46943935
    /// Scroll an element to the screen top.
    func scrollToTop() {
        let topCoordinate = XCUIApplication().screenTopCoordinate
        let elementCoordinate = coordinate(withNormalizedOffset: .zero)

        // Adjust coordinate so that the drag is straight up, otherwise
        // an embedded horizontal scrolling element will get scrolled instead
        let delta = topCoordinate.screenPoint.x - elementCoordinate.screenPoint.x
        let deltaVector = CGVector(dx: delta, dy: 0.0)

        elementCoordinate.withOffset(deltaVector).press(forDuration: 0.1, thenDragTo: topCoordinate)
    }
}
