import XCTest
@testable import WordPressKit

final class SiteVerticalDecodingTests: XCTestCase {

    // MARK: Properties

    private struct MockValues {
        static let identifier = "p25v48"
        static let title = "Landscaping"
        static let isNew = false
    }

    private var emptyVerticalSUT: [SiteVertical]!

    private var singleVerticalSUT: SiteVertical!

    private var verticalsSUT: [SiteVertical]!

    // MARK: XCTestCase

    override func setUp() {
        super.setUp()

        let testClass: AnyClass = SiteVerticalDecodingTests.self
        let bundle = Bundle(for: testClass)

        let jsonDecoder = JSONDecoder()

        // Multiple

        let url1 = bundle.url(forResource: "site-verticals-multiple", withExtension: "json")

        XCTAssertNotNil(url1)
        let jsonURL1 = url1!

        XCTAssertNoThrow(try Data(contentsOf: jsonURL1))
        let jsonData1 = try! Data(contentsOf: jsonURL1)

        XCTAssertNoThrow(try jsonDecoder.decode([SiteVertical].self, from: jsonData1))
        verticalsSUT = try! jsonDecoder.decode([SiteVertical].self, from: jsonData1)

        // Single

        let url2 = bundle.url(forResource: "site-verticals-multiple", withExtension: "json")

        XCTAssertNotNil(url2)
        let jsonURL2 = url2!

        XCTAssertNoThrow(try Data(contentsOf: jsonURL2))
        let jsonData2 = try! Data(contentsOf: jsonURL2)

        XCTAssertNoThrow(try jsonDecoder.decode([SiteVertical].self, from: jsonData2))
        let singleVerticalArray = try! jsonDecoder.decode([SiteVertical].self, from: jsonData2)

        XCTAssertTrue(!singleVerticalArray.isEmpty)
        singleVerticalSUT = verticalsSUT.first

        // Empty

        let url3 = bundle.url(forResource: "site-verticals-empty", withExtension: "json")

        XCTAssertNotNil(url3)
        let jsonURL3 = url3!

        XCTAssertNoThrow(try Data(contentsOf: jsonURL3))
        let jsonData3 = try! Data(contentsOf: jsonURL3)

        XCTAssertNoThrow(try jsonDecoder.decode([SiteVertical].self, from: jsonData3))
        emptyVerticalSUT = try! jsonDecoder.decode([SiteVertical].self, from: jsonData3)
    }

    override func tearDown() {
        singleVerticalSUT = nil
        super.tearDown()
    }

    // MARK: Single Vertical

    func testIdentifierIsNotMutated() {
        XCTAssertEqual(singleVerticalSUT.identifier, MockValues.identifier)
    }

    func testTitleIsNotMutated() {
        XCTAssertEqual(singleVerticalSUT.title, MockValues.title)
    }

    func testIsNewIsNotMutated() {
        XCTAssertEqual(singleVerticalSUT.isNew, MockValues.isNew)
    }

    func testSiteVerticalsWithAllMatchingValuesAreEqual() {
        let secondVertical = SiteVertical(identifier: MockValues.identifier, title: MockValues.title, isNew: MockValues.isNew)

        XCTAssertNotNil(singleVerticalSUT)
        XCTAssertEqual(singleVerticalSUT, secondVertical)
    }

    func testSiteVerticalsWithOnlyMatchingIdentifiersAreNotEqual() {
        let secondVertical = SiteVertical(identifier: MockValues.identifier, title: "", isNew: true)

        XCTAssertNotNil(singleVerticalSUT)
        XCTAssertNotEqual(singleVerticalSUT, secondVertical)
    }

    func testSiteVerticalsWithOnlyMatchingTitlesAreNotEqual() {
        let secondVertical = SiteVertical(identifier: "", title: MockValues.title, isNew: true)

        XCTAssertNotNil(singleVerticalSUT)
        XCTAssertNotEqual(singleVerticalSUT, secondVertical)
    }

    func testSiteVerticalsWithOnlyMatchingNewValuesAreNotEqual() {
        let secondVertical = SiteVertical(identifier: "", title: "", isNew: MockValues.isNew)

        XCTAssertNotNil(singleVerticalSUT)
        XCTAssertNotEqual(singleVerticalSUT, secondVertical)
    }

    // MARK: Multiple Verticals

    func testSiteParsingOfMultipleVerticalsWorksAsExpected() {
        XCTAssertEqual(verticalsSUT.count, 5)
    }

    // MARK: Empty Verticals

    func testSiteParsingOfEmptyVerticalsWorksAsExpected() {
        XCTAssertTrue(emptyVerticalSUT.isEmpty)
    }
}
