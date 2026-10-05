import XCTest

/// Covers the app signed in to the fixture account.
///
/// The account's data never changes, so these tests assert on what the screens show, which the
/// tests that run against a real account can't. They only read, so they share one sign-in.
final class FixtureAccountTests: JetpackUITestCase {
    override class var backend: Backend { .fixtures }
    override class var resetsAppBeforeEachTest: Bool { false }

    func testMySiteShowsThePrimarySite() throws {
        let mySite = try MySiteScreen(app: app)

        XCTAssertEqual(mySite.siteTitle.label, "Tri-County Real Estate")
        XCTAssertEqual(mySite.siteURL.label, "tricountyrealestate.wordpress.com")
    }

    func testSitePickerListsTheAccountsSites() throws {
        let sitePicker = try MySiteScreen(app: app)
            .goToSitePicker()

        for name in ["Tri-County Real Estate", "Four Paws Dog Grooming", "Weekend Bakes"] {
            XCTAssertTrue(sitePicker.site(named: name).waitForExistence(timeout: 5), "\(name) isn't listed")
        }
    }
}
