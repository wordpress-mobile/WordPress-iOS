
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

        let json = Bundle(for: SiteSegmentTests.self).url(forResource: "site-segment", withExtension: "json")!
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

    func testCellTitleIsTheCorrectFont() {
        XCTAssertEqual(cell?.title.font, WPStyleGuide.fontForTextStyle(.body, fontWeight: .semibold))
    }

    func testCellSubtitleIsTheCorrectFont() {
        // This approach fails both locally and on CI
        //XCTAssertEqual(cell?.subtitle.font, WPStyleGuide.fontForTextStyle(.callout, fontWeight: .regular))

        // This approach passes locally, but fails CI
        //XCTAssertNotNil(cell?.subtitle.font)
        //XCTAssertEqual(cell?.subtitle.font!, WPStyleGuide.fontForTextStyle(.callout, fontWeight: .regular))

        // This approach passes locally
        let expectedFont = WPStyleGuide.fontForTextStyle(.callout, fontWeight: .regular)
        let actualFont = cell?.subtitle.font

        XCTAssertNotNil(actualFont)

        XCTAssertEqual(expectedFont.fontName, actualFont!.fontName)
        XCTAssertEqual(expectedFont.pointSize, actualFont!.pointSize, accuracy: 0.01)
    }
}
