import XCTest
@testable import WordPress

final class SiteInfoNeedTests: XCTestCase {
    private struct MockValues {
        static let title = "Basic Information"
        static let subtitle = "Tell us more about the site you are creating"
    }

    private var subject: SiteInfoNeed?

    override func setUp() {
        super.setUp()

        let json = Bundle(for: SiteInfoNeedTests.self).url(forResource: "site-info-need", withExtension: "json")!
        let data = try! Data(contentsOf: json)
        let jsonDecoder = JSONDecoder()

        subject = try! jsonDecoder.decode(SiteInfoNeed.self, from: data)
    }

    override func tearDown() {
        subject = nil
        super.tearDown()
    }

    // Each individual test servers as kind of an integration test in itself. If it does not crash, the parser is at the very least not crashing due to unknown keys
    func testTitleMatchesMock() {
        XCTAssertEqual(subject?.title, MockValues.title)
    }


    func testSubtitleMatchesMock() {
        XCTAssertEqual(subject?.subtitle, MockValues.subtitle)
    }

    func testFirstSectionIsText() {
        let sections = subject?.sections
        guard let firstSection = sections?.first else {
            XCTFail()
            return
        }

        XCTAssertTrue(firstSection is TextInfoNeed)
    }

    func testSecondSectionIsPhoneNumber() {
        let sections = subject?.sections
        guard let secondSection = sections?[1] else {
            XCTFail()
            return
        }

        XCTAssertTrue(secondSection is PhoneInfoNeed)
    }

    func testThirdSectionIsFooter() {
        let sections = subject?.sections
        guard let secondSection = sections?[2] else {
            XCTFail()
            return
        }

        XCTAssertTrue(secondSection is FooterInfoNeed)
    }
}
