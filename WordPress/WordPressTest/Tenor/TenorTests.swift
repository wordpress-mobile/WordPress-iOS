import XCTest
@testable import WordPress

class TenorTests: XCTestCase {

    func testTonerResponseParsing() {
        let json = Bundle(for: TenorTests.self).url(forResource: "tenor", withExtension: "json")!
        let data = try! Data(contentsOf: json)
        guard let response = try? JSONDecoder().decode(TenorResponse.self, from: data) else {
            XCTFail("Tenor response shuold be properly parsed")
            return
        }

        XCTAssertEqual(response.next, "5", "Next page start offset should be correct")
        XCTAssertEqual(response.results.count, 5, "Result count should be correct")

        let media = response.results.first!

        XCTAssertNotNil(media.variants[.nanogif], "Nano gif should exist")
        XCTAssertNotNil(media.variants[.tinygif], "Tiny gif should exist")
        XCTAssertNotNil(media.variants[.mediumgif], "Medium gif should exist")
        XCTAssertNotNil(media.variants[.gif], "Normal gif should exist")

        let gif = media.variants[.gif]!

        XCTAssertTrue(gif.dims[0] > 0 && gif.dims[1] > 0, "Gifs should have non-zero dimensions")
        XCTAssertNotNil(gif.url, "Gifs should have a url")
        XCTAssertNotNil(gif.preview, "Gifs should have a preview url")
    }

    func testTonerResponsePaging() {
        let firstPage = TenorPageable.first()
        XCTAssertEqual(firstPage.pageIndex, 0, "First page should have 0 offset")

        let lastPage = TenorPageable(nextOffset: 0)
        XCTAssertNil(lastPage?.next, "Should not go beyond the last page")
    }
}
