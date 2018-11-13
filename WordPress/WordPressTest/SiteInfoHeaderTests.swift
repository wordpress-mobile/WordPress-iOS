import XCTest
@testable import WordPress

final class SiteInfoHeaderTests: XCTestCase {
    private struct MockValues {
        static let text = "Hello I am a section header"
    }

    private var subject: HeaderInfoNeed?

    override func setUp() {
        super.setUp()

        let json = Bundle(for: SiteInfoHeaderTests.self).url(forResource: "site-info-section-header", withExtension: "json")!
        let data = try! Data(contentsOf: json)
        let jsonDecoder = JSONDecoder()

        subject = try! jsonDecoder.decode(HeaderInfoNeed.self, from: data)
    }

    override func tearDown() {
        subject = nil
        super.tearDown()
    }

    func testTextMatchesExpectation() {
        XCTAssertEqual(subject?.text, MockValues.text)
    }
}
