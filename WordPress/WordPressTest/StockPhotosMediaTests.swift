import XCTest
@testable import WordPress

final class StockPhotosMediaTests: XCTestCase {
    private var subject: StockPhotosMedia?

    private struct MockValues {
        static let id = "PEXELS-946630"
        static let url = URL(string: "https://images.pexels.com/photos/946630/pexels-photo-946630.jpeg?auto=compress&cs=tinysrgb&dpr=2&h=650&w=940")!
        static let title = "pexels-photo-946630.jpeg"
        static let name = "pexels-photo-946630.jpeg"
        static let size = CGSize.zero
    }

    override func setUp() {
        super.setUp()

        let json = Bundle(for: StockPhotosMediaTests.self).url(forResource: "stock-photos-media", withExtension: "json")!
        let data = try! Data(contentsOf: json)
        let jsonDecoder = JSONDecoder()

        subject = try! jsonDecoder.decode(StockPhotosMedia.self, from: data)
    }

    override func tearDown() {
        subject = nil
        super.tearDown()
    }

    func testStockPhotosMediaIdMatchesMock() {
        XCTAssertEqual(subject?.id, MockValues.id)
    }

    func testStockPhotosMediaURLMatchesMock() {
        XCTAssertEqual(subject?.URL, MockValues.url)
    }

    func testStockPhotosTitleMatchesMock() {
        XCTAssertEqual(subject?.title, MockValues.title)
    }

    func testStockPhotosNameMatchesMock() {
        XCTAssertEqual(subject?.name, MockValues.name)
    }

    func testStockPhotosSizeMatchesMock() {
        XCTAssertEqual(subject?.size, MockValues.size)
    }
}
