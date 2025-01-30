import XCTest
import WordPressUI

class UIColorHelpersTests: XCTestCase {

    func testThatHexLiteralsCanBeUsed() {
        let components = UIColor(fromHex: 0xffffff).cgColor.components
        XCTAssertEqual(components?[0], 1.0)
        XCTAssertEqual(components?[1], 1.0)
        XCTAssertEqual(components?[2], 1.0)
        XCTAssertEqual(components?[3], 1.0)
    }

    func testThatHexStringsCanBeParsed() {
        let components = UIColor(hexString: "#ffffff")?.cgColor.components
        XCTAssertEqual(components?[0], 1.0)
        XCTAssertEqual(components?[1], 1.0)
        XCTAssertEqual(components?[2], 1.0)
        XCTAssertEqual(components?[3], 1.0)
    }

    func testThatHexStringsReturnExpectedValues() {
        XCTAssertEqual(UIColor(hexString: "#ffffff")?.hexString, "FFFFFF")
        XCTAssertEqual(UIColor(hexString: "#FF0000")?.hexString, "FF0000")
        XCTAssertEqual(UIColor(hexString: "#00FF00")?.hexString, "00FF00")
        XCTAssertEqual(UIColor(hexString: "#0000FF")?.hexString, "0000FF")
        XCTAssertEqual(UIColor(hexString: "#000000")?.hexString, "000000")
    }

    func testHexString() {
        XCTAssertEqual(UIColor.white.hexString, "FFFFFF")
        XCTAssertEqual(UIColor.red.hexString, "FF0000")
        XCTAssertEqual(UIColor.green.hexString, "00FF00")
        XCTAssertEqual(UIColor.blue.hexString, "0000FF")
        XCTAssertEqual(UIColor.black.hexString, "000000")
    }

    func testHexStringWithAlpha() {
        XCTAssertEqual(UIColor.white.withAlphaComponent(0.0).hexStringWithAlpha, "FFFFFF00")
        XCTAssertEqual(UIColor.white.withAlphaComponent(0.5).hexStringWithAlpha, "FFFFFF80")
        XCTAssertEqual(UIColor.white.withAlphaComponent(1.0).hexStringWithAlpha, "FFFFFFFF")

        XCTAssertEqual(UIColor.red.withAlphaComponent(0.0).hexStringWithAlpha, "FF000000")
        XCTAssertEqual(UIColor.red.withAlphaComponent(0.5).hexStringWithAlpha, "FF000080")
        XCTAssertEqual(UIColor.red.withAlphaComponent(1.0).hexStringWithAlpha, "FF0000FF")

        XCTAssertEqual(UIColor.green.withAlphaComponent(0.0).hexStringWithAlpha, "00FF0000")
        XCTAssertEqual(UIColor.green.withAlphaComponent(0.5).hexStringWithAlpha, "00FF0080")
        XCTAssertEqual(UIColor.green.withAlphaComponent(1.0).hexStringWithAlpha, "00FF00FF")

        XCTAssertEqual(UIColor.blue.withAlphaComponent(0.0).hexStringWithAlpha, "0000FF00")
        XCTAssertEqual(UIColor.blue.withAlphaComponent(0.5).hexStringWithAlpha, "0000FF80")
        XCTAssertEqual(UIColor.blue.withAlphaComponent(1.0).hexStringWithAlpha, "0000FFFF")

        XCTAssertEqual(UIColor.black.withAlphaComponent(0.0).hexStringWithAlpha, "00000000")
        XCTAssertEqual(UIColor.black.withAlphaComponent(0.5).hexStringWithAlpha, "00000080")
        XCTAssertEqual(UIColor.black.withAlphaComponent(1.0).hexStringWithAlpha, "000000FF")
    }
}
