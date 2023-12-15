import XCTest

extension XCUIApplication {

    // Starting with iOS 16.4, the Simulator might ask to save the password with a modal sheet.
    // This method encapsulates the logic to dimiss the prompt.
    func dismissSavePasswordPrompt() {
        XCTContext.runActivity(named: "Dismiss save password prompt if needed.") { _ in
            guard buttons["Save Password"].waitForExistence(timeout: 30) else { return  }

            // There should be no need to wait for this button to exist since it's part of the same
            // alert where "Save Password" is.
            buttons["Not Now"].tap()
        }
    }
}
