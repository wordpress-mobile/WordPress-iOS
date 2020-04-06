
import XCTest
@testable import WordPress

class TenorAPIResponseTests: XCTestCase {

    func testValidAPIResponseParser() throws {
        let data = TenorReponseData.validSearchResponse.data(using: .utf8)
        let parser = TenorResponseParser<TenorGIF>()
        try parser.parse(data!)

        let firstImage = parser.results!.first!

        let largeGif = firstImage.media.first { $0.gif != nil }?.gif
        let previewGif = firstImage.media.first { $0.tinyGIF != nil }?.tinyGIF

        XCTAssertEqual(firstImage.id, "5701246")
        XCTAssertEqual(firstImage.title, "My lovely cat")

        XCTAssertEqual(largeGif?.url, URL(string: "https://media.tenor.com/images/51a86b2115cd75b972f9bc933fec39cc/tenor.gif"))
        XCTAssertEqual(largeGif?.preview, URL(string: "https://media.tenor.com/images/7811876479a3082f9fb56738db117c50/raw"))
        XCTAssertEqual(largeGif?.size, 1928890)
        XCTAssertEqual(largeGif?.dimension, [498, 278])

        XCTAssertEqual(previewGif?.url, URL(string: "https://media.tenor.com/images/65e9b4eaf8ba48d8f1ad3322b13533af/tenor.gif"))
        XCTAssertEqual(previewGif?.preview, URL(string: "https://media.tenor.com/images/812b2143cb8db39033c5d8ef5e04e6f1/raw"))
        XCTAssertEqual(previewGif?.size, 25743)
        XCTAssertEqual(previewGif?.dimension, [220, 123])

        XCTAssertEqual(parser.next, "1")
    }

    func testInvalidResponseThrow() {
        let data = TenorReponseData.invalidSearchResponse.data(using: .utf8)
        let parser = TenorResponseParser<TenorGIF>()
        XCTAssertThrowsError(try parser.parse(data!))
    }
}
