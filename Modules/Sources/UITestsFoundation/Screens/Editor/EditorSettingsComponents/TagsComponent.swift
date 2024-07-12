import ScreenObject
import XCTest

public class TagsComponent: ScreenObject {

    private let tagsFieldGetter: (XCUIApplication) -> XCUIElement = {
        $0.textViews["add-tags"]
    }

    var tagsField: XCUIElement { tagsFieldGetter(app) }

    var backButton: XCUIElement {
        app.navigationBars["Tags"]
            .buttons.element(boundBy: 0)
    }

    init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [ tagsFieldGetter ],
            app: app
        )
    }

    func addTag(name: String) -> TagsComponent {
        tagsField.typeText(name)

        return self
    }

    func goBackToSettings() throws -> EditorPostSettings {
        backButton.tap()

        return try EditorPostSettings()
    }

    public static func isLoaded() -> Bool {
        (try? TagsComponent().isLoaded) ?? false
    }
}
