import XCTest
@testable import WordPress

final class SiteInfoNeedTests: XCTestCase {
    private struct MockValues {
        static let title = "Basic Information"
        static let subtitle = "Tell us more about the site you are creating"
    }

    private var subject: SiteInformation?

    override func setUp() {
        super.setUp()

        let json = Bundle(for: SiteInfoNeedTests.self).url(forResource: "site-info-need", withExtension: "json")!
        let data = try! Data(contentsOf: json)
        let jsonDecoder = JSONDecoder()

        subject = try! jsonDecoder.decode(SiteInformation.self, from: data)
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
        guard let firstGroup = subject?.sections.first else {
            XCTFail()
            return
        }
        guard let firstSection = firstGroup.sections.first else {
            XCTFail()
            return
        }

        XCTAssertTrue(firstSection is TextInfoNeed)
    }

    func testSecondSectionIsPhoneNumber() {
        guard let firstGroup = subject?.sections.first else {
            XCTFail()
            return
        }
        let secondSection = firstGroup.sections[1]

        XCTAssertTrue(secondSection is PhoneInfoNeed)
    }

    func testThirdSectionIsFooter() {
        guard let firstGroup = subject?.sections.first else {
            XCTFail()
            return
        }
        let thirdSection = firstGroup.sections[2]

        XCTAssertTrue(thirdSection is FooterInfoNeed)
    }
}
