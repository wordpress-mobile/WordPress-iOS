import UITestsFoundation
import XCTest

private struct ElementStringIDs {
    static let continueButton = "Prologue Continue Button"
    static let siteAddressButton = "Prologue Self Hosted Button"
}

class PrologueScreen: BaseScreen {
    let continueButton: XCUIElement
    let siteAddressButton: XCUIElement

    init() {
        continueButton = XCUIApplication().buttons[ElementStringIDs.continueButton]
        siteAddressButton = XCUIApplication().buttons[ElementStringIDs.siteAddressButton]

        super.init(element: continueButton)
    }

    func selectContinue() -> GetStartedScreen {
        continueButton.tap()

        return GetStartedScreen()
    }

    func selectSiteAddress() -> LoginSiteAddressScreen {
        siteAddressButton.tap()

        return LoginSiteAddressScreen()
    }

    static func isLoaded() -> Bool {
        return XCUIApplication().buttons[ElementStringIDs.continueButton].exists
    }
}
