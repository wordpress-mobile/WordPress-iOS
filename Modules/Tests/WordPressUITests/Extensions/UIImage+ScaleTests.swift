import XCTest
import WordPressUI

final class UIImage_ScaleTests: XCTestCase {

    let originalImage = UIImage(color: .blue, size: CGSize(width: 1024, height: 768))

    func testAspectFitIntoSquare() {
        let targetSize = CGSize(width: 1000, height: 1000)
        let size = originalImage.dimensions(forSuggestedSize: targetSize, format: .scaleAspectFit)
        XCTAssertEqual(size, CGSize(width: 1000, height: 750))
    }

    func testAspectFitIntoSmallerSize() {
        let targetSize = CGSize(width: 101, height: 76)
        let size = originalImage.dimensions(forSuggestedSize: targetSize, format: .scaleAspectFit)
        XCTAssertEqual(size, targetSize)
    }

    func testAspectFitIntoLargerSize() {
        let targetSize = CGSize(width: 2000, height: 1000)
        let size = originalImage.dimensions(forSuggestedSize: targetSize, format: .scaleAspectFit)
        XCTAssertEqual(size, CGSize(width: 1333, height: 1000))
    }

    func testAspectFillIntoSquare() {
        let targetSize = CGSize(width: 100, height: 100)
        let size = originalImage.dimensions(forSuggestedSize: targetSize, format: .scaleAspectFill)
        XCTAssertEqual(size, CGSize(width: 133, height: 100))
    }

    func testAspectFillIntoSmallerSize() {
        let targetSize = CGSize(width: 103, height: 77)
        let size = originalImage.dimensions(forSuggestedSize: targetSize, format: .scaleAspectFill)
        XCTAssertEqual(size, targetSize)
    }

    func testAspectFillIntoLargerSize() {
        let targetSize = CGSize(width: 2000, height: 1000)
        let size = originalImage.dimensions(forSuggestedSize: targetSize, format: .scaleAspectFill)
        XCTAssertEqual(size, CGSize(width: 2000, height: 1500))
    }

    func testFoo() {
        let targetSize = CGSize(width: 0, height: 0)
        let originalImage = UIImage(color: .blue, size: CGSize(width: 1024, height: 680))
        let size = originalImage.dimensions(forSuggestedSize: targetSize, format: .scaleAspectFill)
    }
}
