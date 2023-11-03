@testable import WordPress
import JetpackStatsWidgetsCore
import XCTest

class DeepLinkSourceTests: XCTestCase {

    // MARK: – Test WidgetUrlSource compatibility

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
