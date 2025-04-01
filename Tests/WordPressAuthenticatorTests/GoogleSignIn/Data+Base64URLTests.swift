@testable import WordPressAuthenticator
import XCTest

class DataBase64URLDecoding: XCTestCase {

    // MARK: - Decoding

    func testBase64URLDecoding() {
        XCTAssertEqual(
            Data(base64URLEncoded: "aGVsbG8gd29ybGQ"),
            "hello world".data(using: .utf8)
        )
    }

    func testBase64URLDecodingWithPadding() {
        XCTAssertEqual(
            Data(base64URLEncoded: "dGVzdA="),
            "test".data(using: .utf8)
        )
    }

    func testBase64URLDecodingWithDoublePadding() {
        XCTAssertEqual(
            Data(base64URLEncoded: "dGVzdA=="),
            "test".data(using: .utf8)
        )
    }

    func testBase64URLDecodingWithNonAlphaNumericCharacters() {
        XCTAssertEqual(
            Data(base64URLEncoded: "V2lsbCB0aGlzIHdvcmsgZm9yIGEgc3RyaW5nIHdpdGggbm9uLWFscGhhbnVtZXJpYyBjaGFyYWN0ZXJzPyE/JiU="),
            "Will this work for a string with non-alphanumeric characters?!?&%".data(using: .utf8)
        )
    }

    func testBase64URLDecodingWithEmptyString() {
        XCTAssertEqual(
            Data(base64URLEncoded: ""),
            Data()
        )
    }

    // MARK: - Encoding

    func testBase64URLEncoding() {
        XCTAssertEqual(
            Data("hello world".utf8).base64URLEncodedString(),
            "aGVsbG8gd29ybGQ"
        )
        XCTAssertEqual(
            Data("Hello, /+ World!".utf8).base64URLEncodedString(),
            "SGVsbG8sIC8rIFdvcmxkIQ"
        )
    }

    // Verify against non UTF-8 characters to ensure it's okay to force unwrapping internally,
    // as suggested by the following discussion in the forums
    // https://forums.swift.org/t/can-encoding-string-to-data-with-utf8-fail/22437/4
    func testBase64URLEncodingNonUTF8() {
        // The Chinese character for "world" cannot be represented in the UTF-8 encoding.
        XCTAssertNotNil(
            Data("Hello, 世界".utf8).base64URLEncodedString(),
            "SGVsbG8sIOS4lueVjA"
        )

        // Notice that if you paste the input strings in the following examples
        // in an online encoder, it'll return a different value. I think that
        // has to do with the kind of UTF-8 allowances `Data` makes internally.
        // For the scope in which we expect to use this code, i.e. only UTF-8
        // encodable characters, that doesn't matter.

        // \u{FF}, Unicode scalar 0xFF, is not a valid UTF-8
        XCTAssertEqual(
            Data("Hello, \u{FF}".utf8).base64URLEncodedString(),
            "SGVsbG8sIMO_"
        )
        // \0, null character, is not a valid UTF-8
        XCTAssertEqual(
            Data("Hello, \0 World!".utf8).base64URLEncodedString(),
            "SGVsbG8sIAAgV29ybGQh"
        )
    }
}
