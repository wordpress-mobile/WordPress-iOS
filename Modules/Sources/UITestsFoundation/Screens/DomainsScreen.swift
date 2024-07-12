import ScreenObject
import XCTest

public class DomainsScreen: ScreenObject {

    private let siteDomainsNavbarHeaderGetter: (XCUIApplication) -> XCUIElement = {
        $0.staticTexts["Site Domains"]
    }

    var siteDomainsNavbarHeader: XCUIElement { siteDomainsNavbarHeaderGetter(app) }

    init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [ siteDomainsNavbarHeaderGetter ],
            app: app
        )
    }

    public static func isLoaded() -> Bool {
        (try? DomainsScreen().isLoaded) ?? false
    }
}
