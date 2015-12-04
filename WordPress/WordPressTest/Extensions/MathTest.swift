import XCTest
import Nimble
@testable import WordPress

class MathTest: XCTestCase {

    func testRound() {
        expect((-5).round(5)).to(equal(-5))
        expect((-4).round(5)).to(equal(-5))
        expect((-3).round(5)).to(equal(-5))
        expect((-2).round(5)).to(equal(0))
        expect((-1).round(5)).to(equal(0))
        expect(0.round(5)).to(equal(0))
        expect(1.round(5)).to(equal(0))
        expect(2.round(5)).to(equal(0))
        expect(3.round(5)).to(equal(5))
        expect(4.round(5)).to(equal(5))
        expect(5.round(5)).to(equal(5))
        expect(6.round(5)).to(equal(5))
        expect(7.round(5)).to(equal(5))
        expect(120.round(50)).to(equal(100))
        expect(245.round(50)).to(equal(250))
    }

    func testClamp() {
        expect(5.clamp(min: 10, max: 20)).to(equal(10))
        expect(10.clamp(min: 10, max: 20)).to(equal(10))
        expect(15.clamp(min: 10, max: 20)).to(equal(15))
        expect(20.clamp(min: 10, max: 20)).to(equal(20))
        expect(30.clamp(min: 10, max: 20)).to(equal(20))
    }

}
