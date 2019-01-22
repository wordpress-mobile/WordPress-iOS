
import XCTest
@testable import WordPress

final class SiteSegmentTests: XCTestCase {
    private struct MockValues {
        static let identifier = Int64(1)
        static let title = "Blogger"
        static let subtitle = "Publish a collection of posts."
        static let icon = URL(string: "https://wordpress.com/icon/blogger.png")!
        static let iconColor = UIColor(hexString: "FFFAFA")
    }

    private var subject: SiteSegment?

    override func setUp() {
        super.setUp()

        let json = Bundle(for: SiteSegmentTests.self).url(forResource: "site-segment", withExtension: "json")!
        let data = try! Data(contentsOf: json)
        let jsonDecoder = JSONDecoder()

        subject = try! jsonDecoder.decode(SiteSegment.self, from: data)
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
        let secondSiteType = SiteSegment(identifier: MockValues.identifier, title: "Another title", subtitle: "It does not matter", icon: MockValues.icon, iconColor: "#FF0000", mobile: true)

        XCTAssertEqual(subject, secondSiteType)
    }
}
