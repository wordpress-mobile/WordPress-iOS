import XCTest

extension XCUIApplication {

    // Starting with iOS 16.4, the Simulator might ask to save the password with a modal sheet.
    // This method encapsulates the logic to dimiss the prompt.
    func dismissSavePasswordPrompt() {
        XCTContext.runActivity(named: "Dismiss save password prompt if needed.") { _ in
            guard buttons["Save Password"].waitForExistence(timeout: 20) else { return  }

            // There should be no need to wait for this button to exist since it's part of the same
            // alert where "Save Password" is...
            let notNowButton = XCUIApplication().buttons["Not Now"]
            // ...but we've seen failures in CI where this cannot be found so let's check first
            XCTAssertTrue(notNowButton.waitForExistence(timeout: 5))

            notNowButton.tapUntil(.dismissed, failureMessage: "Save Password Prompt not dismissed!")
        }
    }
}
