import XCTest
@testable import WordPress

final class SiteCreationWizardTitleTests: XCTestCase {
    private struct Constants {
        static let title = "🌈"
        static let subtitle = "🦄"
    }

    private var header: SiteCreationWizardTitle?

    override func setUp() {
        super.setUp()
        let data = SiteCreationHeaderData(title: Constants.title, subtitle: Constants.subtitle)
        header = SiteCreationWizardTitle(data: data)
        // Force loading the xib
        let _ = header?.view
    }

    override func tearDown() {
        header = nil
        super.tearDown()
    }

    func testTitleContainsTextPassedInConstructor() {
        let titleRendered = header?.titleLabel.text

        XCTAssertEqual(titleRendered, Constants.title)
    }

    func testSubtitleContainsTextPassedInConstructor() {
        let subtitleRendered = header?.subtitleLabel.text

        XCTAssertEqual(subtitleRendered, Constants.subtitle)
    }
}
