
import XCTest

@testable import WordPress

class TenorAPIResponseTests: XCTestCase {
    // MARK: Test a valid response from Tenor

    fileprivate var results: [TenorGIF]!
    fileprivate var next: String!
    fileprivate var firstImage: TenorGIF!
    fileprivate var largeGif: TenorMediaObject!
    fileprivate var previewGif: TenorMediaObject!

    override func setUp() {
        super.setUp()

        let data = TenorReponseData.validSearchResponse.data(using: .utf8)
        let parser = TenorResponseParser<TenorGIF>()
        try! parser.parse(data!)

        firstImage = parser.results!.first!
        next = parser.next!

        largeGif = firstImage.media.first { $0.gif != nil }?.gif
        previewGif = firstImage.media.first { $0.tinyGIF != nil }?.tinyGIF
    }

    func testResponseTenorGIFImage() {
        XCTAssertEqual(firstImage.id, "5701246")
        XCTAssertEqual(firstImage.title, "My lovely cat")
    }

    func testResponseLargeGIFImage() {
        XCTAssertEqual(largeGif?.url, URL(string: "https://media.tenor.com/images/51a86b2115cd75b972f9bc933fec39cc/tenor.gif"))
        XCTAssertEqual(largeGif?.preview, URL(string: "https://media.tenor.com/images/7811876479a3082f9fb56738db117c50/raw"))
        XCTAssertEqual(largeGif?.size, 1928890)
        XCTAssertEqual(largeGif?.dimension, [498, 278])
    }

    func testResponsePrevieweGIFImage() {
        XCTAssertEqual(previewGif?.url, URL(string: "https://media.tenor.com/images/65e9b4eaf8ba48d8f1ad3322b13533af/tenor.gif"))
        XCTAssertEqual(previewGif?.preview, URL(string: "https://media.tenor.com/images/812b2143cb8db39033c5d8ef5e04e6f1/raw"))
        XCTAssertEqual(previewGif?.size, 25743)
        XCTAssertEqual(previewGif?.dimension, [220, 123])
    }

    func testReponseNextPageToken() {
        XCTAssertEqual(next, "1")
    }

    // MARK: Test an invalid response from Tenor

    func testInvalidResponseThrow() {
        let data = TenorReponseData.invalidSearchResponse.data(using: .utf8)
        let parser = TenorResponseParser<TenorGIF>()
        XCTAssertThrowsError(try parser.parse(data!))
    }

    // MARK: Test a response with empty result (no image)

    func testEmptyResponse() throws {
        let data = TenorReponseData.emptyMediaSearchResponse.data(using: .utf8)
        let parser = TenorResponseParser<TenorGIF>()
        try parser.parse(data!)

        XCTAssertEqual(parser.results?.count, 0)
        XCTAssertNil(parser.next)
    }
}
