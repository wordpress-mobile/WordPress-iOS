
import XCTest
@testable import WordPress

final class TitleSubtitleHeaderTests: XCTestCase {
    private var header: TitleSubtitleHeader?

    override func setUp() {
        super.setUp()
        header = TitleSubtitleHeader(frame: .zero)
    }

    override func tearDown() {
        header = nil
        super.tearDown()
    }

    func testHeaderContainsTitleLabel() {
        XCTAssertNotNil(header?.titleLabel)
    }

    func testHeaderContainsSubtitleLabel() {
        XCTAssertNotNil(header?.subtitleLabel)
    }

    func testSetTitleSetsTitleLabel() {
        let title = "Title"
        header?.setTitle(title)

        XCTAssertEqual(header?.titleLabel.text, title)
    }

    func testSetSubtitleSetsSubtitleLabel() {
        let text = "Subtitle"
        header?.setSubtitle(text)

        XCTAssertEqual(header?.subtitleLabel.text, text)
    }

    func testTitleFont() {
        XCTAssertEqual(header?.titleLabel.font, WPStyleGuide.fontForTextStyle(.title1, fontWeight: .bold))
    }

    func testSubtitleFont() {
        XCTAssertEqual(header?.subtitleLabel.font, WPStyleGuide.fontForTextStyle(.body, fontWeight: .regular))
    }
}
