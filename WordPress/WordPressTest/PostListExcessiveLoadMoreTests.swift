import XCTest
@testable import WordPress

class PostListExcessiveLoadMoreTests: XCTestCase {

    func testCount1() {
        let counter = LoadMoreCounter(startingCount: 0)
        counter.dryRun = true
        XCTAssertTrue(counter.increment(properties: [:]))
    }

    func testCount10() {
        let counter = LoadMoreCounter(startingCount: 9)
        counter.dryRun = true
        XCTAssertFalse(counter.increment(properties: [:]))
    }

    func testCount100() {
        let counter = LoadMoreCounter(startingCount: 99)
        counter.dryRun = true
        XCTAssertTrue(counter.increment(properties: [:]))
    }

    func testCount200() {
        let counter = LoadMoreCounter(startingCount: 199)
        counter.dryRun = true
        XCTAssertFalse(counter.increment(properties: [:]))
    }

    func testCount1000() {
        let counter = LoadMoreCounter(startingCount: 999)
        counter.dryRun = true
        XCTAssertTrue(counter.increment(properties: [:]))
    }

    func testCount10000() {
        let counter = LoadMoreCounter(startingCount: 9999)
        counter.dryRun = true
        XCTAssertTrue(counter.increment(properties: [:]))
    }

    func testCount50() {
        let counter = LoadMoreCounter(startingCount: 40)
        counter.dryRun = true
        XCTAssertFalse(counter.increment(properties: [:]))
    }
}
