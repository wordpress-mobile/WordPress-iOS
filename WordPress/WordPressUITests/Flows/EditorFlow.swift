import XCTest

class EditorFlow {
    static func returnToMainEditorScreen() {
        while EditorPostSettings.isLoaded() || CategoriesComponent.isLoaded() || TagsComponent.isLoaded() || MediaPickerAlbumListScreen.isLoaded() || MediaPickerAlbumScreen.isLoaded() {
            navBackButton.tap()
        }
    }

    static func toggleBlockEditor(to state: AppSettingsScreen.Toggle) -> AppSettingsScreen {
        if !AppSettingsScreen.isLoaded() {
            _ = TabNavComponent()
                .gotoMeScreen()
                .gotoAppSettings()
        }
        return AppSettingsScreen().toggleBlockEditor(to: state)
    }
}
