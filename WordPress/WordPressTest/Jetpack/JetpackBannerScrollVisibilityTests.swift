import XCTest

@testable import WordPress

class JetpackBannerScrollVisibilityTests: XCTestCase {

    /// A scroll view without enough content to scroll, so it "bounces"
    func testBannerIsNotHiddenWhenScrollViewBounces() {
        // When
        let hidden = JetpackBannerScrollVisibility.shouldHide(
            contentHeight: 400,
            frameHeight: 400,
            verticalContentOffset: 200
        )

        // Then
        XCTAssertFalse(hidden)
    }

    /// A scroll view with enough content to scroll and has been scrolled past the minimum height of a Jetpack Banner
    func testBannerIsHiddenWhenScrolledDown() {
        // When
        let hidden = JetpackBannerScrollVisibility.shouldHide(
            contentHeight: 600,
            frameHeight: 400,
            verticalContentOffset: JetpackBannerView.minimumHeight + 1
        )

        // Then
        XCTAssertTrue(hidden)
    }

}
