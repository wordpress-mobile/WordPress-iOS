
import XCTest
@testable import WordPress

final class SiteTypeTests: XCTestCase {
    private struct MockValues {
        static let identifier = Identifier(value: "101")
        static let title = "Blogger"
        static let subtitle = "Publish a collection of posts."
        static let icon = URL(string: "https://wordpress.com/icon/blogger.png")!
    }

    private var subject: SiteType?

    override func setUp() {
        super.setUp()

        let json = Bundle(for: SiteTypeTests.self).url(forResource: "site-type", withExtension: "json")!
        let data = try! Data(contentsOf: json)
        let jsonDecoder = JSONDecoder()

        subject = try! jsonDecoder.decode(SiteType.self, from: data)
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

    func testSubtitleIsNotMutated() {
        XCTAssertEqual(subject?.subtitle, MockValues.subtitle)
    }

    func testIconIsNotMutated() {
        XCTAssertEqual(subject?.icon, MockValues.icon)
    }

    func testSiteTypesWithSameIdAreEqual() {
        let secondSiteType = SiteType(identifier: MockValues.identifier, title: "Another title", subtitle: "It does not matter", icon: MockValues.icon)

        XCTAssertEqual(subject, secondSiteType)
    }
}
