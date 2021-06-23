import UITestsFoundation
import XCTest

private struct ElementStringIDs {
    static let draftsButton = "drafts"
    static let publishedButton = "published"

    static let autosaveVersionsAlert = "autosave-options-alert"
}

class PostsScreen: BaseScreen {

    enum PostStatus {
        case published
        case drafts
    }

    private var currentlyFilteredPostStatus: PostStatus = .published

    init() {
        super.init(element: XCUIApplication().tables["PostsTable"])
        showOnly(.published)
    }

    @discardableResult
    func showOnly(_ status: PostStatus) -> PostsScreen {

        switch status {
            case .published:
                XCUIApplication().buttons[ElementStringIDs.publishedButton].tap()
            case .drafts:
                XCUIApplication().buttons[ElementStringIDs.draftsButton].tap()
        }

        currentlyFilteredPostStatus = status

        return self
    }

    func selectPost(withSlug slug: String) -> EditorScreen {

        // Tap the current tab item to scroll the table to the top
        showOnly(currentlyFilteredPostStatus)

        let cell = expectedElement.cells[slug]
        XCTAssert(cell.waitForExistence(timeout: 5))

        scrollElementIntoView(element: cell, within: expectedElement)
        cell.tap()

        dismissAutosaveDialogIfNeeded()

        let editorScreen = EditorScreen()
        editorScreen.dismissDialogsIfNeeded()

        return EditorScreen()
    }

    /// If there are two versions of a local post, the app will ask which version we want to use when editing.
    /// We always want to use the local version (which is currently the first option)
    private func dismissAutosaveDialogIfNeeded() {
        let autosaveDialog = XCUIApplication().alerts[ElementStringIDs.autosaveVersionsAlert]
        if autosaveDialog.exists {
            autosaveDialog.buttons.firstMatch.tap()
        }
    }
}

struct EditorScreen {

    var isGutenbergEditor: Bool {
        let blockEditorElement = "add-block-button"
        return XCUIApplication().buttons[blockEditorElement].waitForExistence(timeout: 3)
    }

    var isAztecEditor: Bool {
        let aztecEditorElement = "Azctec Editor Navigation Bar"
        return XCUIApplication().navigationBars[aztecEditorElement].exists
    }

    private var blockEditor: BlockEditorScreen {
        return BlockEditorScreen()
    }

    private var aztecEditor: AztecEditorScreen {
        return AztecEditorScreen(mode: .rich)
    }

    func dismissDialogsIfNeeded() {
        if self.isGutenbergEditor {
            blockEditor.dismissNotificationAlertIfNeeded(.accept)
        }
    }

    func close() {
        if isGutenbergEditor {
            self.blockEditor.closeEditor()
        }

        if isAztecEditor {
            self.aztecEditor.closeEditor()
        }
    }
}
