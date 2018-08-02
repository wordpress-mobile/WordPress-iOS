import XCTest
@testable import WordPress

final class NewsCardTests: XCTestCase {
    private var subject: NewsCard?

    override func setUp() {
        super.setUp()
        subject = NewsCard(nibName: "NewsCard", bundle: nil)
        let _ = subject?.view
    }

    override func tearDown() {
        subject = nil
        super.tearDown()
    }

    func testViewHasTheExpectedBackgroundColor() {
        XCTAssertEqual(subject?.view.backgroundColor, .red)
    }
}
