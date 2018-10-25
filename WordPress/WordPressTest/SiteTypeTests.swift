
import XCTest
@testable import WordPress

final class SiteTypeTests: XCTestCase {
    private struct Constants {
        static let id = Identifier(value: "Id 1")
        static let title = "Title"
        static let subtitle = "Subtitle"
        static let icon = URL(string: "http://wordpress.com")!
    }

    private var subject: SiteType?

    override func setUp() {
        super.setUp()
        subject = SiteType(id: Constants.id,
                           title: Constants.title,
                           subtitle: Constants.subtitle,
                           icon: Constants.icon)
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

    func testSubtitleIsNotMutated() {
        XCTAssertEqual(subject?.subtitle, Constants.subtitle)
    }

    func testIconIsNotMutated() {
        XCTAssertEqual(subject?.icon, Constants.icon)
    }

    func testSiteTypesWithSameIdAreEqual() {
        let secondSiteType = SiteType(id: Constants.id, title: "Another title", subtitle: "It does not matter", icon: Constants.icon)

        XCTAssertEqual(subject, secondSiteType)
    }
}
