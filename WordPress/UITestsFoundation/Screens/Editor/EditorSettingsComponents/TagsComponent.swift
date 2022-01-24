import ScreenObject
import XCTest

public class TagsComponent: ScreenObject {

    // expectedElement comes from the superclass and gets the first expectedElementGetters result
    var tagsField: XCUIElement { expectedElement }

    init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [ { $0.textViews["add-tags"] } ],
            app: app,
            waitTimeout: 7
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
