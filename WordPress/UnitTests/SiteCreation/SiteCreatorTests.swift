
import XCTest
@testable import WordPress
@testable import WordPressKit

// MARK: - SiteCreatorTests

class SiteCreatorTests: XCTestCase {

    private var siteCreator: SiteCreator!

    override func setUp() {
        super.setUp()

        let creator = SiteCreator()

        creator.segment = SiteSegment(identifier: 12345,
            title: "A title",
            subtitle: "A subtitle",
            icon: URL(string: "https://s.w.org/style/images/about/WordPress-logotype-standard.png")!,
            iconColor: "#FF0000",
            mobile: true)

        let siteDesignPayload = "{\"slug\":\"alves\",\"title\":\"Alves\",\"segment_id\":1,\"categories\":[{\"slug\":\"business\",\"title\":\"Business\",\"description\":\"Business\",\"emoji\":\"💼\"}],\"demo_url\":\"https://public-api.wordpress.com/rest/v1/template/demo/alves/alvesstartermobile.wordpress.com/?language=en\",\"theme\":\"alves\",\"preview\":\"https://s0.wp.com/mshots/v1/public-api.wordpress.com/rest/v1/template/demo/alves/alvesstartermobile.wordpress.com/%3Flanguage%3Den?vpw=1200&vph=1600&w=800&h=1067\",\"preview_tablet\":\"https://s0.wp.com/mshots/v1/public-api.wordpress.com/rest/v1/template/demo/alves/alvesstartermobile.wordpress.com/%3Flanguage%3Den?vpw=800&vph=1066&w=800&h=1067\",\"preview_mobile\":\"https://s0.wp.com/mshots/v1/public-api.wordpress.com/rest/v1/template/demo/alves/alvesstartermobile.wordpress.com/%3Flanguage%3Den?vpw=400&vph=533&w=400&h=534\"}"
        creator.design = try! JSONDecoder().decode(RemoteSiteDesign.self, from: siteDesignPayload.data(using: .utf8)!)

        creator.vertical = SiteIntentVertical(
            slug: "slug",
            localizedTitle: "A title",
            emoji: "😎",
            isDefault: true,
            isCustom: false
        )

        creator.information = SiteInformation(title: "A title", tagLine: "A tagline")

        let domainSuggestionPayload: [String: AnyObject] = [
            "domain_name": "domainName.com" as AnyObject,
            "product_id": 42 as AnyObject,
            "supports_privacy": true as AnyObject,
            "is_free": true as AnyObject
        ]
        creator.address = try! DomainSuggestion(json: domainSuggestionPayload)

        siteCreator = creator
    }

    // If a domain suggestion is present, it should be used as site address
    // siteCreationFlow should be nil, and findAvailableUrl should be false.
    func testRequestUsesDomainSuggestionIfAvailable() {
        // Given
        XCTAssertNotNil(siteCreator)
        // When
        let request = siteCreator.build()
        // Then
        XCTAssertNil(request.siteCreationFlow)
        XCTAssertFalse(request.findAvailableURL)
    }

    // If a domain suggestion is NOT present, the site name should be used to find a valid URL.
    // siteCreationFlow should be NOT nil, and findAvailableUrl should be true.
    func testRequestUsesSiteNameWithNoDomainSuggestion() {
        // Given
        XCTAssertNotNil(siteCreator)
        // When
        siteCreator.address = nil
        let request = siteCreator.build()
        // Then
        XCTAssertNotNil(request.siteCreationFlow)
        XCTAssertTrue(request.findAvailableURL)
        XCTAssertEqual("A title", request.siteURLString)
    }

    // if neither a domain suggestion nor a site name are available, the request
    // will fallback to an empty string.
    // siteCreationFlow should be NOT nil, and findAvailableUrl should be true.
    func testRequesFallsbackWithNoDomainSuggestionAndNoSiteName() {
        // Given
        XCTAssertNotNil(siteCreator)
        // When
        siteCreator.address = nil
        siteCreator.information = nil
        let request = siteCreator!.build()
        // Then
        XCTAssertNotNil(request.siteCreationFlow)
        XCTAssertTrue(request.findAvailableURL)
        XCTAssertEqual("", request.siteURLString)
    }
}
