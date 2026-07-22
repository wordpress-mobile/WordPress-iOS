import Testing
import WordPressShared

struct EmailFormatValidatorTests {

    @Test func testValidEmailAddresses() {
        #expect(EmailFormatValidator.validate(string: "e@example.com"))
        #expect(EmailFormatValidator.validate(string: "example@example.com"))
        #expect(EmailFormatValidator.validate(string: "example@example-example.com"))
        #expect(EmailFormatValidator.validate(string: "example@example.example.example.com"))
        #expect(EmailFormatValidator.validate(string: "example.example+example@example.com"))
    }

    @Test func testInvalidEmailAddresses() {
        #expect(!(EmailFormatValidator.validate(string: "")))
        #expect(!(EmailFormatValidator.validate(string: "example")))
        #expect(!(EmailFormatValidator.validate(string: "example@@example.com")))
        #expect(!(EmailFormatValidator.validate(string: "example@example@.com")))
        #expect(!(EmailFormatValidator.validate(string: "@example.com")))
        #expect(!(EmailFormatValidator.validate(string: "example@example")))
        #expect(!(EmailFormatValidator.validate(string: "example@.com")))
        #expect(!(EmailFormatValidator.validate(string: "example@example..com")))
        #expect(!(EmailFormatValidator.validate(string: "example@.example.com")))
        #expect(!(EmailFormatValidator.validate(string: "example@example.com.")))
        #expect(!(EmailFormatValidator.validate(string: "example@examp?.com")))
        #expect(!(EmailFormatValidator.validate(string: "example@exam_ple.com")))
        #expect(!(EmailFormatValidator.validate(string: "examp***le@exam_ple.com")))
        #expect(!(EmailFormatValidator.validate(string: "example@exam ple.com")))
    }
}
