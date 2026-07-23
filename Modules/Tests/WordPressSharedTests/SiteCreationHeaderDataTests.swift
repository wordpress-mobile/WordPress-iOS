import XCTest
@testable import WordPressShared

final class SiteCreationHeaderDataTests: XCTestCase {
    private struct Constants {
        static let title = "🌈"
        static let subtitle = "🦄"
    }

    private var data: SiteCreationHeaderData?

    override func setUp() {
        super.setUp()
        data = SiteCreationHeaderData(title: Constants.title, subtitle: Constants.subtitle)
    }

    override func tearDown() {
        data = nil
        super.tearDown()
    }

    func testTitleRemainsConstant() {
        XCTAssertEqual(data?.title, Constants.title)
    }

    func testSubtitleRemainsConstant() {
        XCTAssertEqual(data?.subtitle, Constants.subtitle)
    }
}
