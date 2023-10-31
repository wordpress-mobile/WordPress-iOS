import XCTest
import WordPress

class DelayTests: XCTestCase {
    func testIncrementalDelay() {
        var delay = IncrementalDelay([1, 5, 20, 60])
        XCTAssertEqual(1, delay.current)
        delay.increment()
        XCTAssertEqual(5, delay.current)
        delay.increment()
        XCTAssertEqual(20, delay.current)
        delay.increment()
        XCTAssertEqual(60, delay.current)
        delay.increment()
        XCTAssertEqual(60, delay.current)
        delay.reset()
        XCTAssertEqual(1, delay.current)
        delay.increment()
        XCTAssertEqual(5, delay.current)
        delay.reset()
        XCTAssertEqual(1, delay.current)
    }
}
