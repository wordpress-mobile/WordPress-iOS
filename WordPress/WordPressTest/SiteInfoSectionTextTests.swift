import XCTest
@testable import WordPress

final class SiteInfoSectionTextTests: XCTestCase {
    private struct MockValues {
        static let text = "Business Name"
        static let hint = "eg. Bob's Diner"
        static let option = Identifier(value: "site_title")
    }

    private var subject: TextInfoNeed?

    override func setUp() {
        super.setUp()

        let json = Bundle(for: SiteInfoSectionTextTests.self).url(forResource: "site-info-section-text", withExtension: "json")!
        let data = try! Data(contentsOf: json)
        let jsonDecoder = JSONDecoder()

        subject = try! jsonDecoder.decode(TextInfoNeed.self, from: data)
    }

    override func tearDown() {
        subject = nil
        super.tearDown()
    }

    func testTextMatchesExpectation() {
        XCTAssertEqual(subject?.text, MockValues.text)
    }

    func testHintMatchesExpectation() {
        XCTAssertEqual(subject?.hint, MockValues.hint)
    }

    func testOptionMatchesExpectation() {
        XCTAssertEqual(subject?.siteOption, MockValues.option)
    }
}
