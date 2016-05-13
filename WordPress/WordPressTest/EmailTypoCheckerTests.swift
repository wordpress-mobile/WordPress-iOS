import XCTest
import WordPress

class EmailTypoCheckerTests: XCTestCase {
    func testSuggestions() {
        XCTAssertEqual(EmailTypoChecker.guessCorrection(email: "hello@mop.com"), "hello@mop.com")
        XCTAssertEqual(EmailTypoChecker.guessCorrection(email: "hello@gmail.com"), "hello@gmail.com")
        XCTAssertEqual(EmailTypoChecker.guessCorrection(email: "hello"), "hello")
        XCTAssertEqual(EmailTypoChecker.guessCorrection(email: "hello@"), "hello@")
        XCTAssertEqual(EmailTypoChecker.guessCorrection(email: "@"), "@")
        XCTAssertEqual(EmailTypoChecker.guessCorrection(email: ""), "")
        XCTAssertEqual(EmailTypoChecker.guessCorrection(email: "@hello"), "@hello")
        XCTAssertEqual(EmailTypoChecker.guessCorrection(email: "@hello.com"), "@hello.com")
        XCTAssertEqual(EmailTypoChecker.guessCorrection(email: "kikoo@gmail.com"), "kikoo@gmail.com")
        XCTAssertEqual(EmailTypoChecker.guessCorrection(email: "kikoo@azdoij.cm"), "kikoo@azdoij.cm")

        XCTAssertEqual(EmailTypoChecker.guessCorrection(email: "hello@gmial.com"), "hello@gmail.com")
        XCTAssertEqual(EmailTypoChecker.guessCorrection(email: "hello@gmai.com"), "hello@gmail.com")
        XCTAssertEqual(EmailTypoChecker.guessCorrection(email: "hello@yohoo.com"), "hello@yahoo.com")
        XCTAssertEqual(EmailTypoChecker.guessCorrection(email: "hello@yhoo.com"), "hello@yahoo.com")
        XCTAssertEqual(EmailTypoChecker.guessCorrection(email: "hello@ayhoo.com"), "hello@yahoo.com")
        XCTAssertEqual(EmailTypoChecker.guessCorrection(email: "hello@yhoo.com"), "hello@yahoo.com")
        XCTAssertEqual(EmailTypoChecker.guessCorrection(email: "hello@outloo.com"), "hello@outlook.com")
        XCTAssertEqual(EmailTypoChecker.guessCorrection(email: "hello@comcats.com"), "hello@comcast.com")
    }
}
