
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

        let siteDesignPayload = "{\"slug\":\"alves\",\"title\":\"Alves\",\"segment_id\":1,\"categories\":[{\"slug\":\"business\",\"title\":\"Business\",\"description\":\"Business\",\"emoji\":\"💼\"}],\"demo_url\":\"https://public-api.wordpress.com/rest/v1/template/demo/alves/alvesstartermobile.wordpress.com/?language=en\",\"theme\":\"alves\",\"preview\":\"https://s0.wp.com/mshots/v1/public-api.wordpress.com/rest/v1/template/demo/alves/alvesstartermobile.wordpress.com/%3Flanguage%3Den?vpw=1200&vph=1600&w=800&h=1067\",\"preview_tablet\":\"https://s0.wp.com/mshots/v1/public-api.wordpress.com/rest/v1/template/demo/alves/alvesstartermobile.wordpress.com/%3Flanguage%3Den?vpw=800&vph=1066&w=800&h=1067\",\"preview_mobile\":\"https://s0.wp.com/mshots/v1/public-api.wordpress.com/rest/v1/template/demo/alves/alvesstartermobile.wordpress.com/%3Flanguage%3Den?vpw=400&vph=533&w=400&h=534\"}"
        defaultInput.design = try! JSONDecoder().decode(RemoteSiteDesign.self, from: siteDesignPayload.data(using: .utf8)!)

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
