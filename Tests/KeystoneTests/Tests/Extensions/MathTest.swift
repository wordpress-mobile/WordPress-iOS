import XCTest
@testable import WordPress

class MathTest: XCTestCase {

    func testRound() {
        XCTAssertEqual((-5).round(5), -5)
        XCTAssertEqual((-4).round(5), -5)
        XCTAssertEqual((-3).round(5), -5)
        XCTAssertEqual((-2).round(5), 0)
        XCTAssertEqual((-1).round(5), 0)
        XCTAssertEqual(0.round(5), 0)
        XCTAssertEqual(1.round(5), 0)
        XCTAssertEqual(2.round(5), 0)
        XCTAssertEqual(3.round(5), 5)
        XCTAssertEqual(4.round(5), 5)
        XCTAssertEqual(5.round(5), 5)
        XCTAssertEqual(6.round(5), 5)
        XCTAssertEqual(7.round(5), 5)
        XCTAssertEqual(120.round(50), 100)
        XCTAssertEqual(245.round(50), 250)
    }

    func testClamp() {
        XCTAssertEqual(5.clamp(min: 10, max: 20), 10)
        XCTAssertEqual(10.clamp(min: 10, max: 20), 10)
        XCTAssertEqual(15.clamp(min: 10, max: 20), 15)
        XCTAssertEqual(20.clamp(min: 10, max: 20), 20)
        XCTAssertEqual(30.clamp(min: 10, max: 20), 20)
    }

    func testClampCGSizeWithSize() {
        let maxSize = CGSize(width: 4000, height: 3000)
        let minSize = CGSize(width: 400, height: 300)

        do {
            let clamped = CGSize(width: 3000, height: 4000).clamp(min: minSize, max: maxSize)
            let expected = CGSize(width: 3000, height: 3000)
            XCTAssertEqual(clamped, expected)
        }

        do {
            let clamped = CGSize(width: 6000, height: 4000).clamp(min: minSize, max: maxSize)
            let expected = CGSize(width: 4000, height: 3000)
            XCTAssertEqual(clamped, expected)
        }

        do {
            let clamped = CGSize(width: 100, height: 400).clamp(min: minSize, max: maxSize)
            let expected = CGSize(width: 400, height: 400)
            XCTAssertEqual(clamped, expected)
        }

        do {
            let clamped = CGSize(width: 100, height: 100).clamp(min: minSize, max: maxSize)
            let expected = CGSize(width: 400, height: 300)
            XCTAssertEqual(clamped, expected)
        }
    }

}
