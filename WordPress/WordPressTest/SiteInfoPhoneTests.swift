import XCTest
@testable import WordPress

final class SiteInfoSectionPhoneTests: XCTestCase {
    private struct MockValues {
        static let text = "Phone Number"
        static let hint = "Phone Number"
        static let option = Identifier(value: "phone_number")
    }

    private var subject: PhoneInfoNeed?

    override func setUp() {
        super.setUp()

        let json = Bundle(for: SiteInfoSectionPhoneTests.self).url(forResource: "site-info-section-phone", withExtension: "json")!
        let data = try! Data(contentsOf: json)
        let jsonDecoder = JSONDecoder()

        subject = try! jsonDecoder.decode(PhoneInfoNeed.self, from: data)
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
