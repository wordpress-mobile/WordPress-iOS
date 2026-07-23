import Testing
@testable import WordPressShared

struct SiteCreationHeaderDataTests {
    private struct Constants {
        static let title = "🌈"
        static let subtitle = "🦄"
    }

    private var data: SiteCreationHeaderData?

    init() {
        data = SiteCreationHeaderData(title: Constants.title, subtitle: Constants.subtitle)
    }

    @Test func testTitleRemainsConstant() {
        #expect(data?.title == Constants.title)
    }

    @Test func testSubtitleRemainsConstant() {
        #expect(data?.subtitle == Constants.subtitle)
    }
}
