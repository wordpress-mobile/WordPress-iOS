import ScreenObject
import XCTest

public class PostsScreen: ScreenObject {

    public enum PostStatus {
        case published
        case drafts
    }

    private var currentlyFilteredPostStatus: PostStatus = .published

    init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(expectedElementGetters: [ { $0.tables["PostsTable"] } ], app: app)
        showOnly(.published)
    }

    @discardableResult
    public func showOnly(_ status: PostStatus) -> PostsScreen {
        switch status {
        case .published:
            app.buttons["published"].tap()
        case .drafts:
            app.buttons["drafts"].tap()
        }

        currentlyFilteredPostStatus = status

        return self
    }

    public func selectPost(withSlug slug: String) throws -> EditorScreen {

        // Tap the current tab item to scroll the table to the top
        showOnly(currentlyFilteredPostStatus)

        let cell = expectedElement.cells[slug]
        XCTAssert(cell.waitForExistence(timeout: 5))

        cell.scrollIntoView(within: expectedElement)
        cell.tap()

        dismissAutosaveDialogIfNeeded()

        let editorScreen = EditorScreen()
        try editorScreen.dismissDialogsIfNeeded()

        return EditorScreen()
    }

    /// If there are two versions of a local post, the app will ask which version we want to use when editing.
    /// We always want to use the local version (which is currently the first option)
    private func dismissAutosaveDialogIfNeeded() {
        let autosaveDialog = app.alerts["autosave-options-alert"]
        if autosaveDialog.exists {
            autosaveDialog.buttons.firstMatch.tap()
        }
    }
}

public struct EditorScreen {

    var isAztecEditor: Bool {
        let aztecEditorElement = "Azctec Editor Navigation Bar"
        return XCUIApplication().navigationBars[aztecEditorElement].exists
    }

    func dismissDialogsIfNeeded() throws {
        guard let blockEditor = try? BlockEditorScreen() else { return }

        try blockEditor.dismissNotificationAlertIfNeeded(.accept)
    }

    public func close() {
        if let blockEditor = try? BlockEditorScreen() {
            blockEditor.closeEditor()
        }

        if let aztecEditor = try? AztecEditorScreen(mode: .rich) {
            aztecEditor.closeEditor()
        }
    }
}
