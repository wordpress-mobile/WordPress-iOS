// Notice the import is not @testable.
// Let's test the behavior of the public interface and interact with the library the same a consumer would.
import Foundation
import JetpackStatsWidgetsCore
import Testing

struct WidgetUrlSourceTests {

    @Test func testHomeScreenWidgetSource() throws {
        let url = try #require(URL(string: "https://test"))
        let widgetUrl = url.appendingSource(.homeScreenWidget)
        #expect(widgetUrl.absoluteString == "https://test?source=widget")
    }

    @Test func testLockScreenWidgetSource() throws {
        let url = try #require(URL(string: "https://test"))
        let widgetUrl = url.appendingSource(.lockScreenWidget)
        #expect(widgetUrl.absoluteString == "https://test?source=lockscreen_widget")
    }
}
