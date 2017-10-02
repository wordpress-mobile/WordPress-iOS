import Foundation
import XCTest
@testable import WordPress

open class NSStringHelpersTest: XCTestCase {
    func testHostname() {
        let samplePlainURL = "http://www.wordpress.com"
        let sampleStrippedURL = "www.wordpress.com"

        XCTAssertEqual(samplePlainURL.hostname(), sampleStrippedURL)

        let sampleSecureURL = "https://www.wordpress.com"
        XCTAssertEqual(sampleSecureURL.hostname(), sampleStrippedURL)

        let sampleComplexURL = "http://www.wordpress.com?var=http://wordpress.org"
        XCTAssertEqual(sampleComplexURL.hostname(), sampleStrippedURL)

        let samplePlainCapsURL = "http://www.WordPress.com"
        let sampleStrippedCapsURL = "www.WordPress.com"
        XCTAssertEqual(samplePlainCapsURL.hostname(), sampleStrippedCapsURL)
    }

    func testUniqueStringComponentsSeparatedByWhitespaceCorrectlyReturnsASetWithItsWords() {
        let testString = "first\nsecond third\nfourth fifth"
        let testSet = testString.uniqueStringComponentsSeparatedByNewline()

        XCTAssertTrue(testSet.contains("first"), "Missing line")
        XCTAssertTrue(testSet.contains("second third"), "Missing line")
        XCTAssertTrue(testSet.contains("fourth fifth"), "Missing line")
        XCTAssertEqual(testSet.count, 3)
    }

    func testUniqueStringComponentsSeparatedByWhitespaceDoesntAddEmptyStrings() {
        let testString = ""
        let testSet = testString.uniqueStringComponentsSeparatedByNewline()
        XCTAssertEqual(testSet.count, 0)
    }

    func testIsValidEmail() {
        // Although rare, TLDs can have email too
        XCTAssertTrue("koke@com".isValidEmail());

        // Unusual but valid!
        XCTAssertTrue("\"Jorge Bernal\"@example.com".isValidEmail())

        // The hyphen is permitted if it is surrounded by characters, digits or hyphens,
        // although it is not to start or end a label
        XCTAssertTrue("koke@-example.com".isValidEmail())
        XCTAssertTrue("koke@example-.com".isValidEmail())

        // https://en.wikipedia.org/wiki/International_email
        XCTAssertTrue("用户@例子.广告".isValidEmail())
        XCTAssertTrue("उपयोगकर्ता@उदाहरण.कॉम".isValidEmail())

        // Now, the invalid scenario
        XCTAssertFalse("notavalid.email".isValidEmail())
    }
}
