import Foundation
import XCTest

class SignupScreen: BaseScreen {
    let navBar: XCUIElement

    init() {
        navBar = XCUIApplication().navigationBars["WordPress.SignupView"]
        super.init(element: navBar)
    }
}
