import ScreenObject
import XCTest

public class DomainsScreen: ScreenObject {
    public let tabBar: TabNavComponent

    let siteDomainsNavbarHeaderGetter: (XCUIApplication) -> XCUIElement = {
        $0.staticTexts["Site Domains"]
    }

    var siteDomainsNavbarHeader: XCUIElement { siteDomainsNavbarHeaderGetter(app) }

    public init(app: XCUIApplication = XCUIApplication()) throws {
        tabBar = try TabNavComponent()

        try super.init(
            expectedElementGetters: [ siteDomainsNavbarHeaderGetter ],
            app: app
        )
    }

    public static func isLoaded() -> Bool {
        (try? DomainsScreen().isLoaded) ?? false
    }
}
