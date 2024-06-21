import XCTest
@testable import WordPressKit

final class SiteVerticalsRequestEncodingTests: XCTestCase {

    func testSiteVerticalsRequestEncoding_WithAllParameters_IsSuccessful() {
        // Given
        let expectedSearch = "Landscap"
        let expectedLimit = 5

        let request = SiteVerticalsRequest(search: expectedSearch, limit: expectedLimit)

        // When
        let encoder = JSONEncoder()

        XCTAssertNoThrow(try encoder.encode(request))
        let encodedJSON = try! encoder.encode(request)

        XCTAssertNoThrow(try JSONSerialization.jsonObject(with: encodedJSON, options: []))
        let serializedJSON = try! JSONSerialization.jsonObject(with: encodedJSON, options: [])

        guard let jsonDictionary = serializedJSON as? [String: AnyObject] else {
            XCTFail("Failed to encode a proper JSON dictionary!")
            return
        }

        // Then
        let actualSearch = jsonDictionary["search"] as? String
        XCTAssertNotNil(actualSearch)
        XCTAssertEqual(expectedSearch, actualSearch!)

        let actualLimit = jsonDictionary["limit"] as? Int
        XCTAssertNotNil(actualLimit)
        XCTAssertEqual(expectedLimit, actualLimit!)
    }

    func testSiteVerticalsRequestEncoding_WithNoLimitSpecified_IsSuccessful() {
        // Given
        let expectedSearch = "Landscap"
        let expectedLimit = 5

        let request = SiteVerticalsRequest(search: expectedSearch)

        // When
        let encoder = JSONEncoder()

        XCTAssertNoThrow(try encoder.encode(request))
        let encodedJSON = try! encoder.encode(request)

        XCTAssertNoThrow(try JSONSerialization.jsonObject(with: encodedJSON, options: []))
        let serializedJSON = try! JSONSerialization.jsonObject(with: encodedJSON, options: [])

        guard let jsonDictionary = serializedJSON as? [String: AnyObject] else {
            XCTFail("Failed to encode a proper JSON dictionary!")
            return
        }

        // Then
        let actualSearch = jsonDictionary["search"] as? String
        XCTAssertNotNil(actualSearch)
        XCTAssertEqual(expectedSearch, actualSearch!)

        let actualLimit = jsonDictionary["limit"] as? Int
        XCTAssertNotNil(actualLimit)
        XCTAssertEqual(expectedLimit, actualLimit!)
    }

    func testSiteVerticalsRequestEncoding_WithEmptySearch_IsSuccessful() {
        // Given
        let expectedSearch = ""
        let expectedLimit = 5

        let request = SiteVerticalsRequest(search: expectedSearch)

        // When
        let encoder = JSONEncoder()

        XCTAssertNoThrow(try encoder.encode(request))
        let encodedJSON = try! encoder.encode(request)

        XCTAssertNoThrow(try JSONSerialization.jsonObject(with: encodedJSON, options: []))
        let serializedJSON = try! JSONSerialization.jsonObject(with: encodedJSON, options: [])

        guard let jsonDictionary = serializedJSON as? [String: AnyObject] else {
            XCTFail("Failed to encode a proper JSON dictionary!")
            return
        }

        // Then
        let actualSearch = jsonDictionary["search"] as? String
        XCTAssertNotNil(actualSearch)
        XCTAssertEqual(expectedSearch, actualSearch!)

        let actualLimit = jsonDictionary["limit"] as? Int
        XCTAssertNotNil(actualLimit)
        XCTAssertEqual(expectedLimit, actualLimit!)
    }
}
