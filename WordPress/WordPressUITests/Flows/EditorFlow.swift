import XCTest

class EditorFlow {
    static func returnToMainEditorScreen() {
        while EditorPostSettings.isLoaded() || CategoriesComponent.isLoaded() || TagsComponent.isLoaded() || MediaPickerAlbumListScreen.isLoaded() || MediaPickerAlbumScreen.isLoaded() {
            navBackButton.tap()
        }
    }

    static func toggleBlockEditor(to state: SiteSettingsScreen.Toggle) -> SiteSettingsScreen {
        if !SiteSettingsScreen.isLoaded() {
            _ = TabNavComponent()
                .gotoMySiteScreen()
                .gotoSettingsScreen()
        }
        return SiteSettingsScreen().toggleBlockEditor(to: state)
    }
}
