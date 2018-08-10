import XCTest
@testable import WordPress
@testable import WordPressShared.WPStyleGuide
@testable import Gridicons

final class NewsCardTests: XCTestCase {
    private struct Constants {
        static let title = "😳"
        static let content = "😳😳"
        static let url = URL(string: "http://wordpress.com")!
        static let version = Decimal(floatLiteral: 10.7)
        static let readMore = "Read More"
        static let dismiss = "Dismiss"
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

        func shouldPresentCard(contextId: Identifier) -> Bool {
            return cardIsVisible
        }

        func load(then completion: @escaping (Result<NewsItem>) -> Void) {
            let newsItem = NewsItem(title: Constants.title, content: Constants.content, extendedInfoURL: Constants.url, version: Constants.version)
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

    func testTitleHasTheExpectedColor() {
        XCTAssertEqual(subject?.newsTitle.textColor, WPStyleGuide.darkGrey())
    }

    func testSubtitleHasTheExpectedColor() {
        XCTAssertEqual(subject?.newsSubtitle.textColor, WPStyleGuide.greyDarken10())
    }

    func testDismissButtonContainsTheExpectedIcon() {
        let icon = subject?.dismiss.image(for: .normal)
        let expectedIcon = Gridicon.iconOfType(.crossCircle, withSize: CGSize(width: 40, height: 40))

        XCTAssertEqual(icon, expectedIcon)
    }

    func testDismissIconIsImageOnly() {
        let title = subject?.dismiss.title(for: .normal)

        XCTAssertNil(title)
    }

    func testReadMoreButtonIsTextOnly() {
        let icon = subject?.readMore.image(for: .normal)

        XCTAssertNil(icon)
    }

    func testReadMoreButtonContainsTheExpectedText() {
        let title = subject?.readMore.title(for: .normal)

        XCTAssertEqual(title, Constants.readMore)
    }

    func testNewsTitleContainsTheExpectedText() {
        XCTAssertEqual(subject?.newsTitle.text, Constants.title)
    }

    func testNewsTitleContainsTheExpectedAccessibilityTraits() {
        XCTAssertEqual(subject?.newsTitle.accessibilityTraits, UIAccessibilityTraitStaticText)
    }

    func testNewsTitleContainsTheExpectedAccessibilityLabel() {
        XCTAssertEqual(subject?.newsTitle.accessibilityLabel, Constants.title)
    }

    func testNewsSubtitleContainsTheExpectedText() {
        XCTAssertEqual(subject?.newsSubtitle.text, Constants.content)
    }

    func testNewsSubtitleContainsTheExpectedAccessibilityLabel() {
        XCTAssertEqual(subject?.newsSubtitle.accessibilityLabel, Constants.content)
    }

    func testNewsSubtitleContainsTheExpectedAccessibilityTraits() {
        XCTAssertEqual(subject?.newsSubtitle.accessibilityTraits, UIAccessibilityTraitStaticText)
    }

    func testTappingDismissButtonCallsDismissInManager() {
        subject?.dismiss.sendActions(for: .touchUpInside)

        XCTAssertTrue(manager!.dismissed)
    }

    func testDismissButtonProvidesAccessibilityLabel() {
        XCTAssertEqual(subject?.dismiss.accessibilityLabel, Constants.dismiss)
    }

    func testTappingReadMoreButtonCallsReadMoreInManager() {
        subject?.readMore.sendActions(for: .touchUpInside)

        XCTAssertTrue(manager!.readMoreTapped)
    }

    func testReadMoreButtonProvidesAccessibilityLabel() {
        XCTAssertEqual(subject?.readMore.accessibilityLabel, Constants.readMore)
    }
}
