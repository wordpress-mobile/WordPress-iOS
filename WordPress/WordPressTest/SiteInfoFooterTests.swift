import XCTest
@testable import WordPress

final class SiteInfoFooterTests: XCTestCase {
    private struct MockValues {
        static let text = "Display your business number on your site for people to contact you"
    }

    private var subject: FooterInfoNeed?

    override func setUp() {
        super.setUp()

        let json = Bundle(for: SiteInfoFooterTests.self).url(forResource: "site-info-section-footer", withExtension: "json")!
        let data = try! Data(contentsOf: json)
        let jsonDecoder = JSONDecoder()

        subject = try! jsonDecoder.decode(FooterInfoNeed.self, from: data)
    }

    override func tearDown() {
        subject = nil
        super.tearDown()
    }

    func testTextMatchesExpectation() {
        XCTAssertEqual(subject?.text, MockValues.text)
    }
}
