import XCTest
import WordPress

class EmailTypoCheckerTests: XCTestCase {
    func testSuggestions() {
        XCTAssertEqual(EmailTypoChecker.suggestDomainCorrection("hello@mop.com"), "hello@mop.com")
        XCTAssertEqual(EmailTypoChecker.suggestDomainCorrection("hello@gmail.com"), "hello@gmail.com")
        XCTAssertEqual(EmailTypoChecker.suggestDomainCorrection("hello"), "hello")
        XCTAssertEqual(EmailTypoChecker.suggestDomainCorrection("hello@"), "hello@")
        XCTAssertEqual(EmailTypoChecker.suggestDomainCorrection("@"), "@")
        XCTAssertEqual(EmailTypoChecker.suggestDomainCorrection(""), "")
        XCTAssertEqual(EmailTypoChecker.suggestDomainCorrection("@hello"), "@hello")
        XCTAssertEqual(EmailTypoChecker.suggestDomainCorrection("@hello.com"), "@hello.com")
        XCTAssertEqual(EmailTypoChecker.suggestDomainCorrection("kikoo@gmail.com"), "kikoo@gmail.com")
        XCTAssertEqual(EmailTypoChecker.suggestDomainCorrection("kikoo@azdoij.cm"), "kikoo@azdoij.cm")

        XCTAssertEqual(EmailTypoChecker.suggestDomainCorrection("hello@gmial.com"), "hello@gmail.com")
        XCTAssertEqual(EmailTypoChecker.suggestDomainCorrection("hello@gmai.com"), "hello@gmail.com")
        XCTAssertEqual(EmailTypoChecker.suggestDomainCorrection("hello@yohoo.com"), "hello@yahoo.com")
        XCTAssertEqual(EmailTypoChecker.suggestDomainCorrection("hello@yhoo.com"), "hello@yahoo.com")
        XCTAssertEqual(EmailTypoChecker.suggestDomainCorrection("hello@ayhoo.com"), "hello@yahoo.com")
        XCTAssertEqual(EmailTypoChecker.suggestDomainCorrection("hello@yhoo.com"), "hello@yahoo.com")
        XCTAssertEqual(EmailTypoChecker.suggestDomainCorrection("hello@outloo.com"), "hello@outlook.com")
        XCTAssertEqual(EmailTypoChecker.suggestDomainCorrection("hello@comcats.com"), "hello@comcast.com")
    }
}
