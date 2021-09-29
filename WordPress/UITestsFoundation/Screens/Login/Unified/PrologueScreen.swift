import XCTest

private struct ElementStringIDs {
    static let continueButton = "Prologue Continue Button"
    static let siteAddressButton = "Prologue Self Hosted Button"
}

public class PrologueScreen: BaseScreen {
    let continueButton: XCUIElement
    let siteAddressButton: XCUIElement

    public init() {
        continueButton = XCUIApplication().buttons[ElementStringIDs.continueButton]
        siteAddressButton = XCUIApplication().buttons[ElementStringIDs.siteAddressButton]

        super.init(element: continueButton)
    }

    public func selectContinue() -> GetStartedScreen {
        continueButton.tap()

        return GetStartedScreen()
    }

    public func selectSiteAddress() -> LoginSiteAddressScreen {
        siteAddressButton.tap()

        return LoginSiteAddressScreen()
    }

    public static func isLoaded() -> Bool {
        return XCUIApplication().buttons[ElementStringIDs.continueButton].exists
    }
}
