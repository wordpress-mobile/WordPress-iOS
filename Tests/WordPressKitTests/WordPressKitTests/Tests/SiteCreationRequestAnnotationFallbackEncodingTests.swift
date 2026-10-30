import Foundation
import Testing
@testable import WordPressKit

struct SiteCreationRequestAnnotationFallbackEncodingTests {
    @Test func blankSiteRequestEncodesFlowAndFallbackWithoutTemplate() throws {
        let request = makeRequest(
            siteDesign: nil,
            siteCreationFlow: "mobile-blank",
            defaultAnnotationAsPrimaryFallback: true
        )

        let options = try encodedOptions(request)

        #expect(options["site_creation_flow"] as? String == "mobile-blank")
        #expect(options["default_annotation_as_primary_fallback"] as? Bool == true)
        #expect(options["template"] == nil)
        #expect(options["site_vertical"] == nil)
    }

    @Test func requestWithoutFallbackOmitsTheOption() throws {
        let request = makeRequest(
            siteDesign: "default",
            siteCreationFlow: nil,
            defaultAnnotationAsPrimaryFallback: false
        )

        let options = try encodedOptions(request)

        #expect(options["default_annotation_as_primary_fallback"] == nil)
        #expect(options["site_creation_flow"] == nil)
        #expect(options["template"] as? String == "default")
    }

    // MARK: - Helpers

    private func makeRequest(
        siteDesign: String?,
        siteCreationFlow: String?,
        defaultAnnotationAsPrimaryFallback: Bool
    ) -> SiteCreationRequest {
        SiteCreationRequest(
            segmentIdentifier: nil,
            siteDesign: siteDesign,
            verticalIdentifier: nil,
            title: "",
            tagline: nil,
            siteURLString: "example",
            isPublic: true,
            languageIdentifier: 1,
            shouldValidate: true,
            clientIdentifier: "id",
            clientSecret: "secret",
            timezoneIdentifier: "Pacific/Samoa",
            siteCreationFlow: siteCreationFlow,
            findAvailableURL: true,
            defaultAnnotationAsPrimaryFallback: defaultAnnotationAsPrimaryFallback
        )
    }

    private func encodedOptions(_ request: SiteCreationRequest) throws -> [String: Any] {
        let data = try JSONEncoder().encode(request)
        let json = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        return try #require(json["options"] as? [String: Any])
    }
}
