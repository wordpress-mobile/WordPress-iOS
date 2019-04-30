import XCTest

class EditorFlow {
    static func returnToMainEditorScreen() {
        while EditorPostSettings.isLoaded() || CategoriesComponent.isLoaded() || TagsComponent.isLoaded() {
            let backButton = XCUIApplication().navigationBars.element(boundBy: 0).buttons.element(boundBy: 0)

            if backButton.isHittable {
                backButton.tap()
            }
        }
    }
}
