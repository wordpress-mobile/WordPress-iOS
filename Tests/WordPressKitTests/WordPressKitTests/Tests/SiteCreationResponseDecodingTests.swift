import XCTest
@testable import WordPressKit

final class SiteCreationResponseDecodingTests: XCTestCase {

    func testSiteCreationResponseDecoding_IsSuccessful() {
        // Given
        let testClass: AnyClass = SiteCreationResponseDecodingTests.self
        let bundle = Bundle(for: testClass)
        let url = bundle.url(forResource: "site-creation-success", withExtension: "json")

        XCTAssertNotNil(url)
        let jsonURL = url!

        XCTAssertNoThrow(try Data(contentsOf: jsonURL))
        let jsonData = try! Data(contentsOf: jsonURL)

        // When
        let decoder = JSONDecoder()
        XCTAssertNoThrow(try decoder.decode(SiteCreationResponse.self, from: jsonData))
        let response = try! decoder.decode(SiteCreationResponse.self, from: jsonData)

        // Then
        XCTAssertTrue(response.success)

        let site = response.createdSite
        XCTAssertEqual(site.identifier, "156355635")
        XCTAssertEqual(site.title, "10711c")
        XCTAssertEqual(site.urlString, "https://10711c.wordpress.com/")
        XCTAssertEqual(site.xmlrpcString, "https://10711c.wordpress.com/xmlrpc.php")
    }
}
