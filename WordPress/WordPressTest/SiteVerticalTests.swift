
import XCTest
@testable import WordPress

final class SiteVerticalTests: XCTestCase {
    private struct MockValues {
        static let identifier = Identifier(value: "101")
        static let title = "Landscaper"
    }

    private var subject: SiteVertical?

    override func setUp() {
        super.setUp()
        let json = Bundle(for: SiteVerticalTests.self).url(forResource: "site-vertical", withExtension: "json")!
        let data = try! Data(contentsOf: json)
        let jsonDecoder = JSONDecoder()

        subject = try! jsonDecoder.decode(SiteVertical.self, from: data)
    }

    override func tearDown() {
        subject = nil
        super.tearDown()
    }

    func testIdentifierIsNotMutated() {
        XCTAssertEqual(subject?.identifier, MockValues.identifier)
    }

    func testTitleIsNotMutated() {
        XCTAssertEqual(subject?.title, MockValues.title)
    }

    func testSiteVerticalsWithSameIdAreEqual() {
        let secondVertical = SiteVertical(identifier: MockValues.identifier, title: "Cascadia")

        XCTAssertEqual(subject, secondVertical)
    }
}
