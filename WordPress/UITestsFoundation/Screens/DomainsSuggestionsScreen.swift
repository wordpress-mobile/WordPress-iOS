import ScreenObject
import XCTest

public class DomainsSuggestionsScreen: ScreenObject {
    public let tabBar: TabNavComponent

    let siteDomainsNavbarHeaderGetter: (XCUIApplication) -> XCUIElement = {
        $0.staticTexts["Search domains"]
    }

    var siteDomainsNavbarHeader: XCUIElement { siteDomainsNavbarHeaderGetter(app) }

    public init(app: XCUIApplication = XCUIApplication()) throws {
        tabBar = try TabNavComponent()

        try super.init(
            expectedElementGetters: [ siteDomainsNavbarHeaderGetter ],
            app: app,
            waitTimeout: 7
        )
    }

    public static func isLoaded() -> Bool {
        (try? DomainsSuggestionsScreen().isLoaded) ?? false
    }

    @discardableResult
    public func verifyDomainsSuggestionsScreenLoaded() -> Self {
        XCTAssertTrue(DomainsSuggestionsScreen.isLoaded(), "\"Domains suggestions\" screen isn't loaded.")
        return self
    }
}
