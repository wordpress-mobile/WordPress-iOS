import XCTest

extension XCUIElement {
    /**
     Removes any current text in the field before typing in the new value
     - Parameter text: the text to enter into the field
     */
    func clearAndEnterText(text: String) -> Void {
        let app = XCUIApplication()
        let content = self.value as! String

        if content.count > 0 && content != self.placeholderValue {
            self.press(forDuration: 1.2)
            app.menuItems["Select All"].tap()
        } else {
            self.tap()
        }

        self.typeText(text)
    }
}

extension XCTest {

    func isIPhone() -> Bool {
        let app = XCUIApplication()
        return app.windows.element(boundBy: 0).horizontalSizeClass == .compact || app.windows.element(boundBy: 0).verticalSizeClass == .compact
    }
}

func isIpad() -> Bool {
    return UIDevice.current.userInterfaceIdiom == .pad
}
