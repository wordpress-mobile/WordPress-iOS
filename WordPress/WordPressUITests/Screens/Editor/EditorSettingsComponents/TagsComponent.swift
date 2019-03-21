import Foundation
import XCTest

class TagsComponent: BaseScreen {
    let header: XCUIElement
    let backButton: XCUIElement

    init() {
        let app = XCUIApplication()
        header = app.navigationBars["Azctec Editor Navigation Bar"].otherElements["Tags"]
        backButton = app.buttons["Post Settings"]

        super.init(element: header)
    }

    func addTag(name: String) -> TagsComponent {
        app.typeText(name)

        return self
    }

    func goBackToSettings() -> EditorPostSettings {
        backButton.tap()

        return EditorPostSettings()
    }
}
