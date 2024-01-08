import ScreenObject
import XCTest

public class DomainsSelectionScreen: ScreenObject {

    private let domainSuggestionsTableGetter: (XCUIApplication) -> XCUIElement = {
        $0.tables["DomainSelectionTable"]
    }

    private let selectDomainButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["Select domain"]
    }

    private let siteDomainsNavbarHeaderGetter: (XCUIApplication) -> XCUIElement = {
        $0.staticTexts["Search domains"]
    }

    private let searchTextFieldGetter: (XCUIApplication) -> XCUIElement = {
        $0.searchFields.firstMatch
    }

    var searchTextField: XCUIElement { searchTextFieldGetter(app) }
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
        (try? DomainsSelectionScreen().isLoaded) ?? false
    }

    public func searchDomain() throws -> Self {
        searchTextField.tap()
        searchTextField.typeText("domainexample.blog")
        return self
    }

    @discardableResult
    public func selectDomain() throws -> Self {
        domainSuggestionsTable.cells.firstMatch.tap()
        return self
    }

    @discardableResult
    public func goToPlanSelection() throws -> PlanSelectionScreen {
        selectDomainButton.tap()
        return try PlanSelectionScreen()
    }
}
