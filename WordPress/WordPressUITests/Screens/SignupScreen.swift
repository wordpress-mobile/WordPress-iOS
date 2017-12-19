import Foundation
import XCTest

class SignupScreen: BaseScreen {
    //        app.navigationBars["WordPress.SignupView"].buttons["Back"].tap() sas
    init() {
        let navBar = XCUIApplication().navigationBars["WordPress.SignupView"]
        super.init(element: navBar)
    }
}
