import XCTest
@testable import WordPress

final class ThumbnailCollectionTests: XCTestCase {
    private var subject: ThumbnailCollection?

    private struct MockValues {
        static let largeURL = URL(string: "https://images.pexels.com/photos/946630/pexels-photo-946630.jpeg?auto=compress&cs=tinysrgb&dpr=2&h=650&w=940")!
        static let mediumURL = URL(string: "https://images.pexels.com/photos/946630/pexels-photo-946630.jpeg?auto=compress&cs=tinysrgb&h=350")!
        static let postThumbnailURL = URL(string: "https://images.pexels.com/photos/946630/pexels-photo-946630.jpeg?auto=compress&cs=tinysrgb&h=130")!
        static let thumbnailURL = URL(string: "https://images.pexels.com/photos/946630/pexels-photo-946630.jpeg?auto=compress&cs=tinysrgb&fit=crop&h=200&w=280")!
    }

    override func setUp() {
        super.setUp()

        let json = Bundle(for: ThumbnailCollectionTests.self).url(forResource: "thumbnail-collection", withExtension: "json")!
        let data = try! Data(contentsOf: json)
        let jsonDecoder = JSONDecoder()

        subject = try! jsonDecoder.decode(ThumbnailCollection.self, from: data)
    }

    override func tearDown() {
        subject = nil
        super.tearDown()
    }

    func testLargeURLMatchesMock() {
        XCTAssertEqual(subject?.largeURL, MockValues.largeURL)
    }

    func testMediumURLMatchesMock() {
        XCTAssertEqual(subject?.mediumURL, MockValues.mediumURL)
    }

    func testPostThumnailURLMatchesMock() {
        XCTAssertEqual(subject?.postThumbnailURL, MockValues.postThumbnailURL)
    }

    func testThumnailURLMatchesMock() {
        XCTAssertEqual(subject?.thumbnailURL, MockValues.thumbnailURL)
    }
}
