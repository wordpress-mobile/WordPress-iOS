import Nimble
@testable import WordPress
import XCTest

class SignupEpilogueTableViewControllerTests: XCTestCase {

    typealias SUT = SignupEpilogueTableViewController

    // Keeps everything before the "@" and capitalizes it
    func testGenerateDisplayName() {
        expect(SUT.self.generateDisplayName(from: "test@ema.il")) == "Test"
        expect(SUT.self.generateDisplayName(from: "foo@email.com")) == "Foo"
    }

    func testGenerateDisplayNameSplitsEmailComponents() {
        expect(SUT.self.generateDisplayName(from: "test.name@ema.il")) == "Test Name"
        expect(SUT.self.generateDisplayName(from: "test.name.foo@ema.il")) == "Test Name Foo"
    }

    // See discussion in method definition for the rationale behind this behavior.
    func testGenerateDisplayNameHandlesNonEmails() {
        expect(SUT.self.generateDisplayName(from: "string")) == "String"
        expect(SUT.self.generateDisplayName(from: "not.an.email")) == "Not An Email"
        expect(SUT.self.generateDisplayName(from: "not an email")) == "Notanemail"
    }
}
