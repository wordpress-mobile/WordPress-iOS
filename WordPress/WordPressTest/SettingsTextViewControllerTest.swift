
import XCTest
@testable import WordPress

class SettingsTextViewControllerTest: XCTestCase {
    var settingsVC: SettingsTextViewController!

    override func setUp() {
        super.setUp()

        settingsVC = SettingsTextViewController(text: nil, placeholder: "placeholder", hint: nil)
    }

    func testWrongEmailValidation() {
        settingsVC.mode = .email
        settingsVC.text = "@email.com"
        XCTAssertFalse(settingsVC.textPassesValidation())
    }

    func testCorrectEmailValidation() {
        settingsVC.mode = .email
        settingsVC.text = "user@email.com"
        XCTAssertTrue(settingsVC.textPassesValidation())
    }

    func testWrongTextValidation() {
        settingsVC.mode = .text
        settingsVC.text = ""
        XCTAssertFalse(settingsVC.textPassesValidation())
    }

    func testTextValidation() {
        settingsVC.mode = .text
        settingsVC.text = "abc"
        XCTAssertTrue(settingsVC.textPassesValidation())
    }

    func testWrongLowerCaseTextValidation() {
        settingsVC.mode = .lowerCaseText
        settingsVC.text = ""
        XCTAssertFalse(settingsVC.textPassesValidation())
    }

    func testLowerCaseTextValidation() {
        settingsVC.mode = .lowerCaseText
        settingsVC.text = "abc"
        XCTAssertTrue(settingsVC.textPassesValidation())
    }

    // and so on..
    override func tearDown() {
        super.tearDown()

        settingsVC = nil
    }
}
