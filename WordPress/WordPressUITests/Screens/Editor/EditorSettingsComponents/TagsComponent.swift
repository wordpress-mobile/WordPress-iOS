import Foundation
import XCTest

class TagsComponent: BaseScreen {
    let backButton: XCUIElement
    let tagsField: XCUIElement

    init() {
        let app = XCUIApplication()
        backButton = app.navigationBars.element(boundBy: 0).buttons.element(boundBy: 0)
        tagsField = app.textViews["add-tags"]

        super.init(element: tagsField)
    }

    func addTag(name: String) -> TagsComponent {
        tagsField.typeText(name)

        return self
    }

    func goBackToSettings() -> EditorPostSettings {
        backButton.tap()

        return EditorPostSettings()
    }

    static func isLoaded() -> Bool {
        return XCUIApplication().textViews["add-tags"].exists
    }
}
