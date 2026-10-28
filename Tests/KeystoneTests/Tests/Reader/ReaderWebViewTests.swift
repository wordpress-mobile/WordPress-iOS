import Testing
import UIKit
import WordPressReader
@testable import WordPress

@MainActor
struct ReaderWebViewTests {
    @Test(arguments: [
        (ReaderDisplaySettings.Color.system, UIUserInterfaceStyle.unspecified),
        (.sepia, .light),
        (.candy, .light),
        (.evening, .dark),
        (.oled, .dark)
    ])
    func interfaceStyleMatchesTheme(color: ReaderDisplaySettings.Color, expected: UIUserInterfaceStyle) {
        var setting = ReaderDisplaySettings.standard
        setting.color = color

        let webView = ReaderWebView()
        webView.displaySetting = setting

        #expect(webView.overrideUserInterfaceStyle == expected)
    }

    @Test
    func remoteStylesheetLayerIsAboveReaderDefaults() throws {
        let html = ReaderWebView().formattedContent("<p>Post</p>")

        // The order must be declared before the import. Otherwise `calypso` is created
        // first, and the `reader-defaults` rules in reader.css beat the remote stylesheet.
        let order = try #require(html.range(of: "@layer reader-defaults, calypso;"))
        let remote = try #require(html.range(of: "layer(calypso);"))
        let defaults = try #require(html.range(of: "@layer reader-defaults {"))
        #expect(order.upperBound <= remote.lowerBound)
        #expect(remote.upperBound <= defaults.lowerBound)
    }
}
