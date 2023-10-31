import XCTest
@testable import WordPress

class ImageDimensionParserTests: XCTestCase {

    // MARK: - Valid Header Tests
    /// Test a file that has a valid JPEG header
    func testValidJPEGHeader() {
        let data = dataForFile(with: "valid-jpeg-header.jpg")
        let parser = ImageDimensionParser(with: data)

        XCTAssertEqual(parser.format, ImageDimensionFormat.jpeg)
    }

    /// Test a file that has a valid JPEG header, but no other data
    func testValidPNGHeader() {
        let data = dataForFile(with: "valid-png-header")
        let parser = ImageDimensionParser(with: data)

        XCTAssertEqual(parser.format, ImageDimensionFormat.png)
    }

    /// Test a file that has a valid GIF header
    func testValidGIFHeader() {
        let data = dataForFile(with: "valid-gif-header.gif")
        let parser = ImageDimensionParser(with: data)

        XCTAssertEqual(parser.format, ImageDimensionFormat.gif)
    }

    // MARK: - Validate Sizes

    /// Test a 100x100 JPEG file
    func testJPEGDimensions() {
        let data = dataForFile(with: "100x100.jpg")
        let parser = ImageDimensionParser(with: data)

        XCTAssertEqual(parser.format, ImageDimensionFormat.jpeg)
        XCTAssertEqual(parser.imageSize, CGSize(width: 100, height: 100))
    }

    /// Test a 100x100 PNG file
    func testPNGDimensions() {
        let data = dataForFile(with: "100x100-png")
        let parser = ImageDimensionParser(with: data)

        XCTAssertEqual(parser.format, ImageDimensionFormat.png)
        XCTAssertEqual(parser.imageSize, CGSize(width: 100, height: 100))
    }

    /// Test a 100x100 GIF file
    func testGIFDimensions() {
        let data = dataForFile(with: "100x100.gif")
        let parser = ImageDimensionParser(with: data)

        XCTAssertEqual(parser.format, ImageDimensionFormat.gif)
        XCTAssertEqual(parser.imageSize, CGSize(width: 100, height: 100))
    }

    // MARK: - Private: Helpers
    private func dataForFile(with name: String) -> Data {
        let url = Bundle(for: ImageDimensionParserTests.self).url(forResource: name, withExtension: nil)!
        return try! Data(contentsOf: url)
    }
}
