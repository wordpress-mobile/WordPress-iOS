import XCTest
@testable import WordPress

class TenorTests: XCTestCase {

    private func loadStubResponse() -> TenorResponse? {
        let json = Bundle(for: TenorTests.self).url(forResource: "tenor", withExtension: "json")!
        let data = try! Data(contentsOf: json)
        return try? JSONDecoder().decode(TenorResponse.self, from: data)
    }

    func testTenorResponseParsing() {
        guard let response = loadStubResponse() else {
            XCTFail("Tenor response shuold be non-nil")
            return
        }

        XCTAssertEqual(response.results.count, 5, "Tenor response should contain all items")

        let validMediaCount = response.results.filter({$0.isValid}).count

        XCTAssertEqual(validMediaCount, response.results.count, "Parsed media items should all be valid")
    }


    func testParsingBasicFields() {
        let response = loadStubResponse()!
        let media = response.results[1] // First one has an empty title
        XCTAssertTrue(media.id.count > 0, "Media should have an id")
        XCTAssertTrue(media.title.count > 0, "Media should have a title")
    }

    func testParsingGifVariants() {
        let response = loadStubResponse()!
        let media = response.results.first!

        XCTAssertNotNil(media.variants[.nanogif], "Nano gif should exist")
        XCTAssertNotNil(media.variants[.tinygif], "Tiny gif should exist")
        XCTAssertNotNil(media.variants[.mediumgif], "Medium gif should exist")
        XCTAssertNotNil(media.variants[.gif], "Normal gif should exist")
    }

    func testGifContents() {
        let response = loadStubResponse()!
        let media = response.results.first!
        let gif = media.variants[.gif]!

        XCTAssertTrue(gif.dims[0] > 0 && gif.dims[1] > 0, "Gifs should have non-zero dimensions")
        XCTAssertNotNil(gif.url, "Gifs should have a url")
        XCTAssertNotNil(gif.preview, "Gifs should have a preview url")
    }
}
