
import XCTest

@testable import WordPress

class TenorAPIResponseParserTests: XCTestCase {
    // MARK: Test a valid response from Tenor

    fileprivate var results: [TenorGIF]!
    fileprivate var next: String!
    fileprivate var firstImage: TenorGIF!
    fileprivate var largeGif: TenorMediaObject!
    fileprivate var previewGif: TenorMediaObject!
    fileprivate var thumbnailGif: TenorMediaObject!


    override func setUp() {
        super.setUp()

        let data = TenorReponseData.validSearchResponse
        let parser = TenorResponseParser<TenorGIF>()
        try! parser.parse(data)

        firstImage = parser.results!.first!
        next = parser.next!

        largeGif = firstImage.media.first { $0.gif != nil }?.gif
        previewGif = firstImage.media.first { $0.tinyGIF != nil }?.tinyGIF
        thumbnailGif = firstImage.media.first { $0.nanoGIF != nil }?.nanoGIF
    }

    func testParserReturnsGIFImageWithCorrectIdAndTitleAndCreatedDate() {
        XCTAssertEqual(firstImage.id, "5701246")
        XCTAssertEqual(firstImage.title, "My lovely cat")
        XCTAssertEqual(firstImage.created, Date(timeIntervalSince1970: 1468938984.001052))
    }

    func testParserReturnsCorrectLargeGIFImage() {
        XCTAssertEqual(largeGif?.url, URL(string: "https://media.tenor.com/images/51a86b2115cd75b972f9bc933fec39cc/tenor.gif"))
        XCTAssertEqual(largeGif?.preview, URL(string: "https://media.tenor.com/images/7811876479a3082f9fb56738db117c50/raw"))
        XCTAssertEqual(largeGif?.size, 1928890)
        XCTAssertEqual(largeGif?.dimension, [498, 278])
    }

    func testParserReturnsCorrectPreviewGIFImage() {
        XCTAssertEqual(previewGif?.url, URL(string: "https://media.tenor.com/images/65e9b4eaf8ba48d8f1ad3322b13533af/tenor.gif"))
        XCTAssertEqual(previewGif?.preview, URL(string: "https://media.tenor.com/images/812b2143cb8db39033c5d8ef5e04e6f1/raw"))
        XCTAssertEqual(previewGif?.size, 25743)
        XCTAssertEqual(previewGif?.dimension, [220, 123])
    }

    func testParserReturnsCorrectThumbnailGIFImage() {
        XCTAssertEqual(thumbnailGif?.url, URL(string: "https://media.tenor.com/images/b517c9429616233016d600633477ec25/tenor.gif"))
        XCTAssertEqual(thumbnailGif?.preview, URL(string: "https://media.tenor.com/images/62e0c5de3dcf4740c21a3ce44b316c94/raw"))
        XCTAssertEqual(thumbnailGif?.size, 15256)
        XCTAssertEqual(thumbnailGif?.dimension, [160, 90])
    }


    func testParserReturnsCorrectNextPageToken() {
        XCTAssertEqual(next, "1")
    }

    // MARK: Test an invalid response from Tenor

    func testParserThrowsIfResponseIsUnexpected() {
        let data = TenorReponseData.invalidSearchResponse
        let parser = TenorResponseParser<TenorGIF>()
        XCTAssertThrowsError(try parser.parse(data))
    }

    // MARK: Test a response with empty result (no image)

    func testParserReturnsEmptyResult() throws {
        let data = TenorReponseData.emptyMediaSearchResponse
        let parser = TenorResponseParser<TenorGIF>()
        try parser.parse(data)

        XCTAssertEqual(parser.results?.count, 0)
        XCTAssertNil(parser.next)
    }
}
