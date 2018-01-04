import Foundation
import XCTest

class SignupScreen: BaseScreen {
    let navBar: XCUIElement
    let navBackButton: XCUIElement

    init() {
        navBar = XCUIApplication().navigationBars["WordPress.SignupView"]
        navBackButton = navBar.buttons["Back"]
        super.init(element: navBar)
    }
}
