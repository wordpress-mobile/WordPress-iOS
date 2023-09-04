import ScreenObject
import XCTest

public class DomainsSuggestionsScreen: ScreenObject {

    private let domainSuggestionsTableGetter: (XCUIApplication) -> XCUIElement = {
        $0.tables["DomainSuggestionsTable"]
    }

    private let selectDomainButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["Select domain"]
    }

    private let siteDomainsNavbarHeaderGetter: (XCUIApplication) -> XCUIElement = {
        $0.staticTexts["Search domains"]
    }

    var domainSuggestionsTable: XCUIElement { domainSuggestionsTableGetter(app) }
    var selectDomainButton: XCUIElement { selectDomainButtonGetter(app) }
    var siteDomainsNavbarHeader: XCUIElement { siteDomainsNavbarHeaderGetter(app) }

    init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [ siteDomainsNavbarHeaderGetter ],
            app: app
        )
    }

    public static func isLoaded() -> Bool {
        (try? DomainsSuggestionsScreen().isLoaded) ?? false
    }

    @discardableResult
    public func selectDomain() throws -> Self {
        domainSuggestionsTable.cells.lastMatch?.tap()
        return self
    }

    @discardableResult
    public func goToPlanSelection() throws -> PlanSelectionScreen {
        selectDomainButton.tap()
        return try PlanSelectionScreen()
    }
}
