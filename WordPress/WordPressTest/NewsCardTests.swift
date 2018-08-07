import XCTest
@testable import WordPress

final class NewsCardTests: XCTestCase {
    private struct Constants {
        static let content = "😳"
    }

    private var subject: NewsCard?
    private var manager: NewsManager?

    override func setUp() {
        super.setUp()
        manager = DefaultNewsManager(service: LocalNewsService(content: Constants.content))
        subject = NewsCard(manager: manager!)
        let _ = subject?.view
    }

    override func tearDown() {
        subject = nil
        manager = nil
        super.tearDown()
    }

    func testViewHasTheExpectedBackgroundColor() {
        XCTAssertEqual(subject?.view.backgroundColor, .red)
    }
}
