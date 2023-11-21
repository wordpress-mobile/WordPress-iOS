// Notice the import is not @testable.
// Let's test the behavior of the public interface and interact with the library the same a consumer would.
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
