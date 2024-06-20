import XCTest
@testable import WordPressKit

final class SiteCreationRequestEncodingTests: XCTestCase {
    static let expectedSegmentId = Int64(1)
    static let expectedSiteDesign = "Test-Design"
    static let expectedVerticalId = "p2v10"
    static let expectedBlogTitle = "Come on in"
    static let expectedTagline = "This is a site I like"
    static let expectedBlogName = "Cool Restaurant"
    static let expectedPublicValue = true
    static let expectedLanguageId = "TEST-ENGLISH"
    static let expectedValidateValue = true
    static let expectedClientId = "TEST-ID"
    static let expectedClientSecret = "TEST-SECRET"
    static let expectedTimezoneIdentifier = "Pacific/Samoa"
    static let siteCreationFlow: String? = nil
    static let findAvailableUrl = false

    func testSiteCreationRequestEncoding_WithAllParameters_IsSuccessful() {
        // Given
        let request = SiteCreationRequest(
            segmentIdentifier: SiteCreationRequestEncodingTests.expectedSegmentId,
            siteDesign: SiteCreationRequestEncodingTests.expectedSiteDesign,
            verticalIdentifier: SiteCreationRequestEncodingTests.expectedVerticalId,
            title: SiteCreationRequestEncodingTests.expectedBlogTitle,
            tagline: SiteCreationRequestEncodingTests.expectedTagline,
            siteURLString: SiteCreationRequestEncodingTests.expectedBlogName,
            isPublic: SiteCreationRequestEncodingTests.expectedPublicValue,
            languageIdentifier: SiteCreationRequestEncodingTests.expectedLanguageId,
            shouldValidate: SiteCreationRequestEncodingTests.expectedValidateValue,
            clientIdentifier: SiteCreationRequestEncodingTests.expectedClientId,
            clientSecret: SiteCreationRequestEncodingTests.expectedClientSecret,
            timezoneIdentifier: SiteCreationRequestEncodingTests.expectedTimezoneIdentifier,
            siteCreationFlow: SiteCreationRequestEncodingTests.siteCreationFlow,
            findAvailableURL: SiteCreationRequestEncodingTests.findAvailableUrl
        )

        // When
        let jsonDictionary = encodeRequest(request)

        // Then
        validate(jsonDictionary)
    }

    func testSiteCreationRequestEncoding_WorksWithPrivate() {
        // Given
        let request = SiteCreationRequest(
            segmentIdentifier: SiteCreationRequestEncodingTests.expectedSegmentId,
            siteDesign: SiteCreationRequestEncodingTests.expectedSiteDesign,
            verticalIdentifier: SiteCreationRequestEncodingTests.expectedVerticalId,
            title: SiteCreationRequestEncodingTests.expectedBlogTitle,
            tagline: SiteCreationRequestEncodingTests.expectedTagline,
            siteURLString: SiteCreationRequestEncodingTests.expectedBlogName,
            isPublic: false,
            languageIdentifier: SiteCreationRequestEncodingTests.expectedLanguageId,
            shouldValidate: SiteCreationRequestEncodingTests.expectedValidateValue,
            clientIdentifier: SiteCreationRequestEncodingTests.expectedClientId,
            clientSecret: SiteCreationRequestEncodingTests.expectedClientSecret,
            timezoneIdentifier: SiteCreationRequestEncodingTests.expectedTimezoneIdentifier,
            siteCreationFlow: SiteCreationRequestEncodingTests.siteCreationFlow,
            findAvailableURL: SiteCreationRequestEncodingTests.findAvailableUrl
        )

        // When
        let jsonDictionary = encodeRequest(request)

        // Then
        validate(jsonDictionary, expectedPublicValue: false)
    }

    func testSiteCreationRequestEncoding_WorksWithValidate_SetToFalse() {
        // Given
        let request = SiteCreationRequest(
            segmentIdentifier: SiteCreationRequestEncodingTests.expectedSegmentId,
            siteDesign: SiteCreationRequestEncodingTests.expectedSiteDesign,
            verticalIdentifier: SiteCreationRequestEncodingTests.expectedVerticalId,
            title: SiteCreationRequestEncodingTests.expectedBlogTitle,
            tagline: SiteCreationRequestEncodingTests.expectedTagline,
            siteURLString: SiteCreationRequestEncodingTests.expectedBlogName,
            isPublic: SiteCreationRequestEncodingTests.expectedPublicValue,
            languageIdentifier: SiteCreationRequestEncodingTests.expectedLanguageId,
            shouldValidate: false,
            clientIdentifier: SiteCreationRequestEncodingTests.expectedClientId,
            clientSecret: SiteCreationRequestEncodingTests.expectedClientSecret,
            timezoneIdentifier: SiteCreationRequestEncodingTests.expectedTimezoneIdentifier,
            siteCreationFlow: SiteCreationRequestEncodingTests.siteCreationFlow,
            findAvailableURL: SiteCreationRequestEncodingTests.findAvailableUrl
        )

        // When
        let jsonDictionary = encodeRequest(request)

        // Then
        validate(jsonDictionary)
        let actualValidateValue = jsonDictionary["validate"] as? Bool
        XCTAssertNotNil(actualValidateValue)
    }

    func testSiteCreationRequestEncoding_WorksWithoutVertical() {
        // Given
        let request = SiteCreationRequest(
            segmentIdentifier: SiteCreationRequestEncodingTests.expectedSegmentId,
            siteDesign: SiteCreationRequestEncodingTests.expectedSiteDesign,
            verticalIdentifier: nil,
            title: SiteCreationRequestEncodingTests.expectedBlogTitle,
            tagline: SiteCreationRequestEncodingTests.expectedTagline,
            siteURLString: SiteCreationRequestEncodingTests.expectedBlogName,
            isPublic: SiteCreationRequestEncodingTests.expectedPublicValue,
            languageIdentifier: SiteCreationRequestEncodingTests.expectedLanguageId,
            shouldValidate: SiteCreationRequestEncodingTests.expectedValidateValue,
            clientIdentifier: SiteCreationRequestEncodingTests.expectedClientId,
            clientSecret: SiteCreationRequestEncodingTests.expectedClientSecret,
            timezoneIdentifier: SiteCreationRequestEncodingTests.expectedTimezoneIdentifier,
            siteCreationFlow: SiteCreationRequestEncodingTests.siteCreationFlow,
            findAvailableURL: SiteCreationRequestEncodingTests.findAvailableUrl
        )

        // When
        let jsonDictionary = encodeRequest(request)

        // Then
        validate(jsonDictionary, expectedVerticalId: nil)
    }

    func testSiteCreationRequestEncoding_WorksWithoutTagline() {
        // Given
        let request = SiteCreationRequest(
            segmentIdentifier: SiteCreationRequestEncodingTests.expectedSegmentId,
            siteDesign: SiteCreationRequestEncodingTests.expectedSiteDesign,
            verticalIdentifier: SiteCreationRequestEncodingTests.expectedVerticalId,
            title: SiteCreationRequestEncodingTests.expectedBlogTitle,
            tagline: nil,
            siteURLString: SiteCreationRequestEncodingTests.expectedBlogName,
            isPublic: SiteCreationRequestEncodingTests.expectedPublicValue,
            languageIdentifier: SiteCreationRequestEncodingTests.expectedLanguageId,
            shouldValidate: SiteCreationRequestEncodingTests.expectedValidateValue,
            clientIdentifier: SiteCreationRequestEncodingTests.expectedClientId,
            clientSecret: SiteCreationRequestEncodingTests.expectedClientSecret,
            timezoneIdentifier: SiteCreationRequestEncodingTests.expectedTimezoneIdentifier,
            siteCreationFlow: SiteCreationRequestEncodingTests.siteCreationFlow,
            findAvailableURL: SiteCreationRequestEncodingTests.findAvailableUrl
        )

        // When
        let jsonDictionary = encodeRequest(request)

        // Then
        validate(jsonDictionary, expectedTagline: nil)
    }

    func testSiteCreationRequestEncoding_WorksWithoutSegment() {
        // Given
        let request = SiteCreationRequest(
            segmentIdentifier: nil,
            siteDesign: SiteCreationRequestEncodingTests.expectedSiteDesign,
            verticalIdentifier: SiteCreationRequestEncodingTests.expectedVerticalId,
            title: SiteCreationRequestEncodingTests.expectedBlogTitle,
            tagline: SiteCreationRequestEncodingTests.expectedTagline,
            siteURLString: SiteCreationRequestEncodingTests.expectedBlogName,
            isPublic: SiteCreationRequestEncodingTests.expectedPublicValue,
            languageIdentifier: SiteCreationRequestEncodingTests.expectedLanguageId,
            shouldValidate: SiteCreationRequestEncodingTests.expectedValidateValue,
            clientIdentifier: SiteCreationRequestEncodingTests.expectedClientId,
            clientSecret: SiteCreationRequestEncodingTests.expectedClientSecret,
            timezoneIdentifier: SiteCreationRequestEncodingTests.expectedTimezoneIdentifier,
            siteCreationFlow: SiteCreationRequestEncodingTests.siteCreationFlow,
            findAvailableURL: SiteCreationRequestEncodingTests.findAvailableUrl
        )

        // When
        let jsonDictionary = encodeRequest(request)

        // Then
        validate(jsonDictionary, expectedSegmentId: nil)
    }

    func testSiteCreationRequestEncoding_WorksWithoutDesign() {
        // Given
        let request = SiteCreationRequest(
            segmentIdentifier: SiteCreationRequestEncodingTests.expectedSegmentId,
            siteDesign: nil,
            verticalIdentifier: SiteCreationRequestEncodingTests.expectedVerticalId,
            title: SiteCreationRequestEncodingTests.expectedBlogTitle,
            tagline: SiteCreationRequestEncodingTests.expectedTagline,
            siteURLString: SiteCreationRequestEncodingTests.expectedBlogName,
            isPublic: SiteCreationRequestEncodingTests.expectedPublicValue,
            languageIdentifier: SiteCreationRequestEncodingTests.expectedLanguageId,
            shouldValidate: SiteCreationRequestEncodingTests.expectedValidateValue,
            clientIdentifier: SiteCreationRequestEncodingTests.expectedClientId,
            clientSecret: SiteCreationRequestEncodingTests.expectedClientSecret,
            timezoneIdentifier: SiteCreationRequestEncodingTests.expectedTimezoneIdentifier,
            siteCreationFlow: SiteCreationRequestEncodingTests.siteCreationFlow,
            findAvailableURL: SiteCreationRequestEncodingTests.findAvailableUrl
        )

        // When
        let jsonDictionary = encodeRequest(request)

        // Then
        validate(jsonDictionary, expectedSiteDesign: nil)
    }
}

/// Mark - Validations
extension SiteCreationRequestEncodingTests {

    private func encodeRequest(_ request: SiteCreationRequest) -> [String: AnyObject] {
        let encoder = JSONEncoder()

        XCTAssertNoThrow(try encoder.encode(request))
        let encodedJSON = try! encoder.encode(request)

        XCTAssertNoThrow(try JSONSerialization.jsonObject(with: encodedJSON, options: []))
        let serializedJSON = try! JSONSerialization.jsonObject(with: encodedJSON, options: [])

        if let _ = serializedJSON as? [String: AnyObject] {} else {
            XCTFail("Failed to encode a proper JSON dictionary!")
        }
        return serializedJSON as! [String: AnyObject]
    }

    private func validate(_ jsonDictionary: [String: AnyObject],
                          expectedSegmentId: Int64? = SiteCreationRequestEncodingTests.expectedSegmentId,
                          expectedSiteDesign: String? = SiteCreationRequestEncodingTests.expectedSiteDesign,
                          expectedPublicValue: Bool = SiteCreationRequestEncodingTests.expectedPublicValue,
                          expectedVerticalId: String? = SiteCreationRequestEncodingTests.expectedVerticalId,
                          expectedTagline: String? = SiteCreationRequestEncodingTests.expectedTagline) {

        let actualBlogName = jsonDictionary["blog_name"] as? String
        XCTAssertEqual(SiteCreationRequestEncodingTests.expectedBlogName, actualBlogName)

        let actualBlogTitle = jsonDictionary["blog_title"] as? String
        XCTAssertNotNil(actualBlogTitle)
        XCTAssertEqual(SiteCreationRequestEncodingTests.expectedBlogTitle, actualBlogTitle!)

        let actualClientId = jsonDictionary["client_id"] as? String
        XCTAssertNotNil(actualClientId)
        XCTAssertEqual(SiteCreationRequestEncodingTests.expectedClientId, actualClientId!)

        let actualClientSecret = jsonDictionary["client_secret"] as? String
        XCTAssertNotNil(actualClientSecret)
        XCTAssertEqual(SiteCreationRequestEncodingTests.expectedClientSecret, actualClientSecret!)

        let actualPublicValue = jsonDictionary["public"] as? Bool
        XCTAssertNotNil(actualPublicValue)
        XCTAssertEqual(expectedPublicValue, actualPublicValue!)

        let actualLanguageId = jsonDictionary["lang_id"] as? String
        XCTAssertNotNil(actualLanguageId)

        let actualValidateValue = jsonDictionary["validate"] as? Bool
        XCTAssertNotNil(actualValidateValue)

        let actualOptions = jsonDictionary["options"] as? [String: AnyObject]
        XCTAssertNotNil(actualOptions)

        let actualSegmentId = actualOptions!["site_segment"] as? Int64
        XCTAssertEqual(expectedSegmentId, actualSegmentId)

        let actualVerticalId = actualOptions!["site_vertical"] as? String
        XCTAssertEqual(expectedVerticalId, actualVerticalId)

        let actualSiteInfo = actualOptions!["site_information"] as? [String: AnyObject]
        let actualTagline = actualSiteInfo?["site_tagline"] as? String
        XCTAssertEqual(expectedTagline, actualTagline)

        let actualDesign = actualOptions!["template"] as? String
        XCTAssertEqual(expectedSiteDesign, actualDesign)

        let actualTimezoneIdentifier = actualOptions!["timezone_string"] as? String
        XCTAssertNotNil(actualTimezoneIdentifier)
    }
}
