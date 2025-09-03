import XCTest
@testable import WordPressKit

final class SiteVerticalsPromptResponseDecodingTests: XCTestCase {

    func testSiteVerticalsPromptResponseDecoding_IsSuccessful() {
        // Given
        let testClass: AnyClass = SiteVerticalsPromptResponseDecodingTests.self
        let bundle = Bundle(for: testClass)
        let url = bundle.url(forResource: "site-verticals-prompt", withExtension: "json")

        XCTAssertNotNil(url)
        let jsonURL = url!

        XCTAssertNoThrow(try Data(contentsOf: jsonURL))
        let jsonData = try! Data(contentsOf: jsonURL)

        // When
        let decoder = JSONDecoder()
        XCTAssertNoThrow(try decoder.decode(SiteVerticalsPrompt.self, from: jsonData))
        let response = try! decoder.decode(SiteVerticalsPrompt.self, from: jsonData)

        let expectedTitle = "What will your blog be about?"
        let expectedSubtitle = "We'll use your answer to add sections to your website."
        let expectedHint = "e.g., Landscaping, Consulting... etc"

        // Then
        XCTAssertEqual(response.title, expectedTitle)
        XCTAssertEqual(response.subtitle, expectedSubtitle)
        XCTAssertEqual(response.hint, expectedHint)
    }
}
