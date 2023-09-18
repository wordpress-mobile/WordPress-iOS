import XCTest
@testable import WordPress

final class WidgetUrlSourceTests: XCTestCase {
    func testHomeScreenWidgetSource() throws {
        let url = try XCTUnwrap(URL(string: "https://test"))
        let widgetUrl = url.appendingSource(.homeScreenWidget)
        XCTAssertEqual(widgetUrl.absoluteString, "https://test?source=widget")
    }

    func testLockScreenWidgetSource() throws {
        let url = try XCTUnwrap(URL(string: "https://test"))
        let widgetUrl = url.appendingSource(.lockScreenWidget)
        XCTAssertEqual(widgetUrl.absoluteString, "https://test?source=lockscreen_widget")
    }

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
