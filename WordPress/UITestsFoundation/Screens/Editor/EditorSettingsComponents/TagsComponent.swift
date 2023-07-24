import ScreenObject
import XCTest

public class TagsComponent: ScreenObject {

    private let tagsFieldGetter: (XCUIApplication) -> XCUIElement = {
        $0.textViews["add-tags"]
    }

    var tagsField: XCUIElement { tagsFieldGetter(app) }

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
        navigateBack()

        return try EditorPostSettings()
    }

    public static func isLoaded() -> Bool {
        (try? TagsComponent().isLoaded) ?? false
    }
}
