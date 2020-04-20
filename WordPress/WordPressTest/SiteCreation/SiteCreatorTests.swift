
import XCTest
@testable import WordPress
@testable import WordPressKit

// MARK: - SiteCreatorTests

class SiteCreatorTests: XCTestCase {

    private var pendingSiteInput: SiteCreator?

    override func setUp() {
        super.setUp()

        let defaultInput = SiteCreator()

        defaultInput.segment = SiteSegment(identifier: 12345,
            title: "A title",
            subtitle: "A subtitle",
            icon: URL(string: "https://s.w.org/style/images/about/WordPress-logotype-standard.png")!,
            iconColor: "#FF0000",
            mobile: true)

        defaultInput.vertical = SiteVertical(identifier: "678910",
            title: "A title",
            isNew: true)

        defaultInput.information = SiteInformation(title: "A title", tagLine: "A tagline")

        let domainSuggestionPayload: [String: AnyObject] = [
            "domain_name": "domainName.com" as AnyObject,
            "product_id": 42 as AnyObject,
            "supports_privacy": true as AnyObject,
        ]
        defaultInput.address = try! DomainSuggestion(json: domainSuggestionPayload)

        pendingSiteInput = defaultInput
    }

    func testSiteCreator_buildSucceeds_HappyPathInput() {
        // Given
        XCTAssertNotNil(pendingSiteInput)
        let siteInput = pendingSiteInput!

        // When : no changes from default instance

        // Then
        XCTAssertNoThrow(try siteInput.build())
    }

    func testSiteCreator_buildFails_MissingSiteSegment() {
        // Given
        XCTAssertNotNil(pendingSiteInput)
        let siteInput = pendingSiteInput!

        // When
        siteInput.segment = nil

        // Then
        XCTAssertThrowsError(try siteInput.build())
    }

    func testSiteCreator_buildSucceeds_MissingSiteVertical() {
        // Given
        XCTAssertNotNil(pendingSiteInput)
        let siteInput = pendingSiteInput!

        // When
        siteInput.vertical = nil

        // Then
        XCTAssertNoThrow(try siteInput.build())
    }

    func testSiteCreator_buildSucceeds_MissingSiteInfoTagline() {
        // Given
        XCTAssertNotNil(pendingSiteInput)
        let siteInput = pendingSiteInput!

        // When
        siteInput.information = SiteInformation(title: "", tagLine: nil)

        // Then
        XCTAssertNoThrow(try siteInput.build())
    }

    func testSiteCreator_buildFails_MissingDomainSuggestion() {
        // Given
        XCTAssertNotNil(pendingSiteInput)
        let siteInput = pendingSiteInput!

        // When
        siteInput.address = nil

        // Then
        XCTAssertThrowsError(try siteInput.build())
    }
}
