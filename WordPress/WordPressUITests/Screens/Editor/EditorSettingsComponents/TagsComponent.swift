import Foundation
import XCTest

class TagsComponent: BaseScreen {
    let tagsField: XCUIElement

    init() {
        let app = XCUIApplication()
        tagsField = app.textViews["add-tags"]

        super.init(element: tagsField)
    }

    func addTag(name: String) -> TagsComponent {
        tagsField.typeText(name)

        return self
    }

    func goBackToSettings() -> EditorPostSettings {
        navBackButton.tap()

        return EditorPostSettings()
    }

    static func isLoaded() -> Bool {
        return XCUIApplication().textViews["add-tags"].exists
    }
}
