import XCTest
@testable import WordPressKit

final class SiteSegmentsResponseDecodingTests: XCTestCase {
    private struct MockValues {
        static let identifier: Int64 = 1
        static let mobile = true
        static let title = "Blog"
        static let subtitle = "Share and discuss ideas, updates, or creations."
        static let iconURL = URL(string: "https://s.wp.com/i/mobile_segmentation_icons/monochrome/ic_blogger.png")
        static let iconColor = "0087be"
    }

    private var segment: SiteSegment?

    override func setUp() {
        super.setUp()

        let mockFileURL = Bundle(for: type(of: self)).url(forResource: "site-segments-single", withExtension: "json")!

        let json = try! Data(contentsOf: mockFileURL)

        segment = try! JSONDecoder().decode(SiteSegment.self, from: json)
    }

    override func tearDown() {
        super.tearDown()
    }

    func testIdentifierIsNotMutated() {
        XCTAssertEqual(segment?.identifier, MockValues.identifier)
    }

    func testTitleIsNotMutated() {
        XCTAssertEqual(segment?.title, MockValues.title)
    }

    func testSubtitleIsNotMutated() {
        XCTAssertEqual(segment?.subtitle, MockValues.subtitle)
    }

    func testMobileIsNotMutated() {
        XCTAssertEqual(segment?.mobile, MockValues.mobile)
    }

    func testIconURLIsNotMutated() {
        XCTAssertEqual(segment?.icon, MockValues.iconURL)
    }

    func testIconColorIsNotMutated() {
        XCTAssertEqual(segment?.iconColor, MockValues.iconColor)
    }
}
