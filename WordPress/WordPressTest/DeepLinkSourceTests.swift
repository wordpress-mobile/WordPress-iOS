@testable import WordPress
import JetpackStatsWidgetsCore
import XCTest

class DeepLinkSourceTests: XCTestCase {

    // MARK: – Test WidgetUrlSource compatibility

    // Notice that WidgetUrlSource is not a type we use in either the WordPress or Jetpack apps.
    // It's a type used in the Jetpack stats widget.
    // It's a bit of a stretch to import it here, given these are the unit tests for the WordPress and Jetpack apps.
    // Still, it's useful to do so to ensure there are no compatibility breaks between the assumptions widgets and apps made.

    func testHomeScreenWidgetSourceType() {
        let source = WidgetUrlSource.homeScreenWidget.rawValue
        let deepLinkSource = DeepLinkSource(sourceName: source)
        XCTAssertEqual(deepLinkSource, .widget)
    }

    func testLockScreenWidgetSourceType() {
        let source = WidgetUrlSource.lockScreenWidget.rawValue
        let deepLinkSource = DeepLinkSource(sourceName: source)
        XCTAssertEqual(deepLinkSource, .lockScreenWidget)
    }
}
