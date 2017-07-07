import XCTest
@testable import WordPress

class EmailFormatValidatorTests: XCTestCase {

    func testValidEmailAddresses() {
        XCTAssertTrue(EmailFormatValidator.validate(str: "e@example.com"))
        XCTAssertTrue(EmailFormatValidator.validate(str: "example@example.com"))
        XCTAssertTrue(EmailFormatValidator.validate(str: "example@example-example.com"))
        XCTAssertTrue(EmailFormatValidator.validate(str: "example@example.example.example.com"))
        XCTAssertTrue(EmailFormatValidator.validate(str: "example.example+example@example.com"))
    }

    func testInvalidEmailAddresses() {
        XCTAssertFalse(EmailFormatValidator.validate(str: ""))
        XCTAssertFalse(EmailFormatValidator.validate(str: "example"))
        XCTAssertFalse(EmailFormatValidator.validate(str: "example@@example.com"))
        XCTAssertFalse(EmailFormatValidator.validate(str: "example@example@.com"))
        XCTAssertFalse(EmailFormatValidator.validate(str: "@example.com"))
        XCTAssertFalse(EmailFormatValidator.validate(str: "example@example"))
        XCTAssertFalse(EmailFormatValidator.validate(str: "example@.com"))
        XCTAssertFalse(EmailFormatValidator.validate(str: "example@example..com"))
        XCTAssertFalse(EmailFormatValidator.validate(str: "example@.example.com"))
        XCTAssertFalse(EmailFormatValidator.validate(str: "example@example.com."))
        XCTAssertFalse(EmailFormatValidator.validate(str: "example@examp?.com"))
        XCTAssertFalse(EmailFormatValidator.validate(str: "example@exam_ple.com"))
        XCTAssertFalse(EmailFormatValidator.validate(str: "examp***le@exam_ple.com"))
        XCTAssertFalse(EmailFormatValidator.validate(str: "example@exam ple.com"))
    }

}
