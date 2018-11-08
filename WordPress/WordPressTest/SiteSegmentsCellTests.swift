
import XCTest
@testable import WordPress

final class SiteSegmentsCellTests: XCTestCase {
    private struct MockValues {
        static let identifier = Identifier(value: "101")
        static let title = "Blogger"
        static let subtitle = "Publish a collection of posts."
        static let icon = URL(string: "https://wordpress.com/icon/blogger.png")!
    }

    private var cell: SiteSegmentsCell?
    private var segment: SiteSegment?

    override func setUp() {
        super.setUp()

        let json = Bundle(for: SiteSegmentTests.self).url(forResource: "site-type", withExtension: "json")!
        let data = try! Data(contentsOf: json)
        let jsonDecoder = JSONDecoder()

        segment = try! jsonDecoder.decode(SiteSegment.self, from: data)

        let nib = Bundle.main.loadNibNamed(SiteSegmentsCell.cellReuseIdentifier(), owner: self, options: nil)
        cell = nib?.first as? SiteSegmentsCell
    }

    override func tearDown() {
        segment = nil
        cell = nil
        super.tearDown()
    }

    func testCellTitleContainsExpectedValue() {
        cell?.model = segment

        XCTAssertEqual(cell?.title.text, MockValues.title)
    }

    func testCellSubtitleContainsExpectedValue() {
        cell?.model = segment

        XCTAssertEqual(cell?.subtitle.text, MockValues.subtitle)
    }
}
