import XCTest
@testable import WordPress

final class StockPhotosMediaGroupTests: XCTestCase {
    private var mediaGroup: StockPhotosMediaGroup?

    private struct Constants {
        static let name = String.freePhotosLibrary
        static let mediaRequestID: WPMediaRequestID = 0
        static let baseGroup = ""
        static let identifier = "group id"
        static let numberOfAssets = 10
    }

    override func setUp() {
        super.setUp()
        mediaGroup = StockPhotosMediaGroup()
    }

    override func tearDown() {
        mediaGroup = nil
        super.tearDown()
    }

    func testGroupNameMatchesExpectation() {
        XCTAssertEqual(mediaGroup!.name(), Constants.name)
    }

    func testGroupMediaRequestIDMatchesExpectation() {
        XCTAssertEqual(mediaGroup!.image(with: .zero, completionHandler: { (image, error) in

        }), Constants.mediaRequestID)
    }

    func testBaseGroupIsEmpty() {
        XCTAssertEqual(mediaGroup!.baseGroup() as! String, Constants.baseGroup)
    }

    func testIdentifierMatchesExpectation() {
        XCTAssertEqual(mediaGroup!.identifier(), Constants.identifier)
    }

    func testNumberOfAssetsMatchExpectation() {
        let numberOfAssets = mediaGroup?.numberOfAssets(of: .image)
        XCTAssertEqual(numberOfAssets, Constants.numberOfAssets)
    }
}
