import XCTest

class EditorFlow {
    static func returnToMainEditorScreen() {
        while EditorPostSettings.isLoaded() || CategoriesComponent.isLoaded() || TagsComponent.isLoaded() || MediaPickerAlbumListScreen.isLoaded() || MediaPickerAlbumScreen.isLoaded() {
            navBackButton.tap()
        }
    }
}
