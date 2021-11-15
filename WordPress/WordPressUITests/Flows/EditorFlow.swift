import UITestsFoundation
import XCTest

class EditorFlow {
    static func returnToMainEditorScreen() {
        while EditorPostSettings.isLoaded() || CategoriesComponent.isLoaded() || TagsComponent.isLoaded() || MediaPickerAlbumListScreen.isLoaded() || MediaPickerAlbumScreen.isLoaded() {
            navBackButton.tap()
        }
    }

    static func goToMySiteScreen() throws -> MySiteScreen {
        return try TabNavComponent().goToMySiteScreen()
    }

    static func toggleBlockEditor(to state: SiteSettingsScreen.Toggle) throws -> SiteSettingsScreen {
        if !SiteSettingsScreen.isLoaded() {
            _ = try TabNavComponent()
                .goToMySiteScreen()
                .goToSettingsScreen()
        }
        return try SiteSettingsScreen().toggleBlockEditor(to: state)
    }
}
