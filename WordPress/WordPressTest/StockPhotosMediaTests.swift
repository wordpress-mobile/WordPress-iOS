import XCTest
@testable import WordPress

final class StockPhotosMediaTests: XCTestCase {
    private var subject: StockPhotosMedia?

    private struct MockValues {
        static let id = "PEXELS-924676"
        static let url = URL(string: "https://images.pexels.com/photos/924676/pexels-photo-924676.jpeg?auto=compress&cs=tinysrgb&dpr=2&h=650&w=940")!
        static let title = "shallow focus photography of magnifying glass with black frame"
        static let name = "pexels-photo-924676.jpeg"
        static let caption = "Photo by Shane Aldendorff on <a href=\"https://www.pexels.com/\" rel=\"nofollow\">Pexels.com</a>"
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

    func testStockPhotosCaptionMatchesMock() {
        XCTAssertEqual(subject?.caption, MockValues.caption)
    }

    func testStockPhotosSizeMatchesMock() {
        XCTAssertEqual(subject?.size, MockValues.size)
    }
}
