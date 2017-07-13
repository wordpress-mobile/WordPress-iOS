import XCTest
@testable import WordPress

class EmailFormatValidatorTests: XCTestCase {

    func testValidEmailAddresses() {
        XCTAssertTrue(EmailFormatValidator.validate(string: "e@example.com"))
        XCTAssertTrue(EmailFormatValidator.validate(string: "example@example.com"))
        XCTAssertTrue(EmailFormatValidator.validate(string: "example@example-example.com"))
        XCTAssertTrue(EmailFormatValidator.validate(string: "example@example.example.example.com"))
        XCTAssertTrue(EmailFormatValidator.validate(string: "example.example+example@example.com"))
    }

    func testInvalidEmailAddresses() {
        XCTAssertFalse(EmailFormatValidator.validate(string: ""))
        XCTAssertFalse(EmailFormatValidator.validate(string: "example"))
        XCTAssertFalse(EmailFormatValidator.validate(string: "example@@example.com"))
        XCTAssertFalse(EmailFormatValidator.validate(string: "example@example@.com"))
        XCTAssertFalse(EmailFormatValidator.validate(string: "@example.com"))
        XCTAssertFalse(EmailFormatValidator.validate(string: "example@example"))
        XCTAssertFalse(EmailFormatValidator.validate(string: "example@.com"))
        XCTAssertFalse(EmailFormatValidator.validate(string: "example@example..com"))
        XCTAssertFalse(EmailFormatValidator.validate(string: "example@.example.com"))
        XCTAssertFalse(EmailFormatValidator.validate(string: "example@example.com."))
        XCTAssertFalse(EmailFormatValidator.validate(string: "example@examp?.com"))
        XCTAssertFalse(EmailFormatValidator.validate(string: "example@exam_ple.com"))
        XCTAssertFalse(EmailFormatValidator.validate(string: "examp***le@exam_ple.com"))
        XCTAssertFalse(EmailFormatValidator.validate(string: "example@exam ple.com"))
    }

}
