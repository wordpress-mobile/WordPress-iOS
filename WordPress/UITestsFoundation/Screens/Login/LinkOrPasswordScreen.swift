import XCTest

// TODO: remove when unifiedAuth is permanent.

private struct ElementStringIDs {
    static let passwordOption = "Use Password"
    static let linkButton = "Send Link Button"
}

public class LinkOrPasswordScreen: BaseScreen {
    let passwordOption: XCUIElement
    let linkButton: XCUIElement

    init() {
        passwordOption = XCUIApplication().buttons[ElementStringIDs.passwordOption]
        linkButton = XCUIApplication().buttons[ElementStringIDs.linkButton]

        super.init(element: passwordOption)
    }

    func proceedWithPassword() -> LoginPasswordScreen {
        passwordOption.tap()

        return LoginPasswordScreen()
    }

    public func proceedWithLink() -> LoginCheckMagicLinkScreen {
        linkButton.tap()

        return LoginCheckMagicLinkScreen()
    }

    public static func isLoaded() -> Bool {
        return XCUIApplication().buttons[ElementStringIDs.passwordOption].exists
    }
}
