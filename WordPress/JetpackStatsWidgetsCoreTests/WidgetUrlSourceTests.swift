import JetpackStatsWidgetsCore
import XCTest

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
}
