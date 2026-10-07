import XCTest

/// The management page for one of the site's domains, shown in a web view.
final class DomainDetailsScreen: ScreenObject {
    private let dismissButtonGetter: ElementGetter = {
        $0.buttons["Dismiss"]
    }

    var dismissButton: XCUIElement { dismissButtonGetter(app) }

    /// - Parameter domain: The domain name, which the screen shows as its title.
    init(domain: String, app: XCUIApplication) throws {
        try super.init(expectedElementGetters: [{ $0.navigationBars[domain] }, dismissButtonGetter], app: app)
    }

    @discardableResult
    func dismiss() throws -> DomainsScreen {
        dismissButton.tap()
        return try DomainsScreen(app: app)
    }
}
