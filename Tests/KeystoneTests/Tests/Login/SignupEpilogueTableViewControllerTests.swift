@testable import WordPress
import XCTest

class SignupEpilogueTableViewControllerTests: XCTestCase {

    typealias SUT = SignupEpilogueTableViewController

    // Keeps everything before the "@" and capitalizes it
    func testGenerateDisplayName() {
        XCTAssertEqual(SUT.self.generateDisplayName(from: "test@ema.il"), "Test")
        XCTAssertEqual(SUT.self.generateDisplayName(from: "foo@email.com"), "Foo")
    }

    func testGenerateDisplayNameSplitsEmailComponents() {
        XCTAssertEqual(SUT.self.generateDisplayName(from: "test.name@ema.il"), "Test Name")
        XCTAssertEqual(SUT.self.generateDisplayName(from: "test.name.foo@ema.il"), "Test Name Foo")
    }

    // See discussion in method definition for the rationale behind this behavior.
    func testGenerateDisplayNameHandlesNonEmails() {
        XCTAssertEqual(SUT.self.generateDisplayName(from: "string"), "String")
        XCTAssertEqual(SUT.self.generateDisplayName(from: "not.an.email"), "Not An Email")
        XCTAssertEqual(SUT.self.generateDisplayName(from: "not an email"), "Notanemail")
    }
}
