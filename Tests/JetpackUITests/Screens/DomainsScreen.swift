import XCTest

/// The site's domains list.
final class DomainsScreen: ScreenObject {
    init(app: XCUIApplication) throws {
        try super.init(expectedElementGetters: [Self.navigationBarTitle("Site Domains")], app: app)
    }

    /// Opens the first domain that has a management page. The site's free WordPress.com domain
    /// doesn't have one.
    func goToFirstDomain() throws -> DomainDetailsScreen {
        let row = app.buttons["site-domain-row"].firstMatch
        try tapFirst(row, named: "domains with a management page")

        // The row's label starts with the domain name: "example.com, Active, Expires on…".
        let domain = String(row.label.prefix { $0 != "," })
        return try DomainDetailsScreen(domain: domain, app: app)
    }
}
