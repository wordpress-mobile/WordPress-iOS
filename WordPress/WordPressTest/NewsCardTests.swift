import XCTest
@testable import WordPress
@testable import WordPressShared.WPStyleGuide

final class NewsCardTests: XCTestCase {
    private struct Constants {
        static let title = "😳"
        static let content = "😳😳"
        static let url = URL(string: "http://wordpress.com")!
    }

    private class MockNewsManager: NewsManager {
        var dismissed: Bool = false
        var readMoreTapped: Bool = false
        var cardIsVisible: Bool = true

        func dismiss() {
            dismissed = true
        }

        func readMore() {
            readMoreTapped = true
        }

        func shouldPresentCard() -> Bool {
            return cardIsVisible
        }

        func load(then completion: @escaping (Result<NewsItem>) -> Void) {
            let newsItem = NewsItem(title: Constants.title, content: Constants.content, extendedInfoURL: Constants.url)
            let result: Result<NewsItem> = .success(newsItem)

            completion(result)
        }
    }


    private var subject: NewsCard?
    private var manager: MockNewsManager?

    override func setUp() {
        super.setUp()
        manager = MockNewsManager()
        subject = NewsCard(manager: manager!)
        let _ = subject?.view
    }

    override func tearDown() {
        subject = nil
        manager = nil
        super.tearDown()
    }

    func testViewHasTheExpectedBackgroundColor() {
        XCTAssertEqual(subject?.view.backgroundColor, WPStyleGuide.greyLighten30())
    }

    func testNewsTitleContainsTheExpectedText() {
        XCTAssertEqual(subject?.newsTitle.text, Constants.title)
    }

    func testNewsSubtitleContainsTheExpectedText() {
        XCTAssertEqual(subject?.newsSubtitle.text, Constants.content)
    }

    func testTappingDismissButtonCallsDismissInManager() {
        subject?.dismiss.sendActions(for: .touchUpInside)

        XCTAssertTrue(manager!.dismissed)
    }

    func testTappingReadMoreButtonCallsReadMoreInManager() {
        subject?.readMore.sendActions(for: .touchUpInside)

        XCTAssertTrue(manager!.readMoreTapped)
    }
}
