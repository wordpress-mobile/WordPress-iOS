import XCTest

extension XCUIElement {

    /// Scroll an element into view within another element.
    /// scrollView can be a UIScrollView, or anything that subclasses it like UITableView
    ///
    /// TODO: The implementation of this could use work:
    /// - What happens if the element is above the current scroll view position?
    /// - What happens if it's a really long scroll view?
    public func scrollIntoView(within scrollView: XCUIElement, threshold: Int = 1000) {
        var iteration = 0

        while !isFullyVisibleOnScreen && iteration < threshold {
            scrollView.scroll(byDeltaX: 0, deltaY: 100)
            iteration += 1
        }

        if !isFullyVisibleOnScreen {
            XCTFail("Unable to scroll element into view")
        }
    }
}
