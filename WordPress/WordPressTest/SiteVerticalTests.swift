
import XCTest
@testable import WordPress

final class SiteVerticalTests: XCTestCase {
    private struct Constants {
        static let id = Identifier(value: "Vertical id 1")
        static let title = "Vertical 1 title"
    }

    private var subject: SiteVertical?

    override func setUp() {
        super.setUp()
        subject = SiteVertical(id: Constants.id,
                               title: Constants.title)
    }

    override func tearDown() {
        subject = nil
        super.tearDown()
    }

    func testIdentifierIsNotMutated() {
        XCTAssertEqual(subject?.id, Constants.id)
    }

    func testTitleIsNotMutated() {
        XCTAssertEqual(subject?.title, Constants.title)
    }

    func testSiteVerticalsWithSameIdAreEqual() {
        let secondVertical = SiteVertical(id: Constants.id, title: "Cascadia")

        XCTAssertEqual(subject, secondVertical)
    }
}
