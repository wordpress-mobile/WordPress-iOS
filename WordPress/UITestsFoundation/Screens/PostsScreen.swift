import ScreenObject
import XCTest

public class PostsScreen: ScreenObject {

    public enum PostStatus {
        case published
        case drafts
        case scheduled
    }

    private var currentlyFilteredPostStatus: PostStatus = .published

    private let postsTableGetter: (XCUIApplication) -> XCUIElement = {
        $0.tables["PostsTable"]
    }

    private let publishedButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["published"]
    }

    private let draftsButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["drafts"]
    }

    private let scheduledButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["scheduled"]
    }

    private let createPostButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["Create Post Button"]
    }

    private let autosaveAlertGetter: (XCUIApplication) -> XCUIElement = {
        $0.alerts["autosave-options-alert"]
    }

    var postsTable: XCUIElement { postsTableGetter(app) }
    var publishedButton: XCUIElement { publishedButtonGetter(app) }
    var draftsButton: XCUIElement { draftsButtonGetter(app) }
    var scheduledButton: XCUIElement { scheduledButtonGetter(app) }
    var createPostButton: XCUIElement { createPostButtonGetter(app) }
    var autosaveAlert: XCUIElement { autosaveAlertGetter(app) }

    public init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [postsTableGetter],
            app: app
        )
        showOnly(.published)
    }

    @discardableResult
    public func showOnly(_ status: PostStatus) -> PostsScreen {
        switch status {
        case .published:
            publishedButton.tap()
        case .drafts:
            draftsButton.tap()
        case .scheduled:
            scheduledButton.tap()
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
        if autosaveAlert.exists {
            autosaveAlert.buttons.firstMatch.tap()
        }
    }

    public func verifyPostExists(withTitle title: String) {
        let postsTable = app.tables["PostsTable"]
        let predicate = NSPredicate(format: "label BEGINSWITH %@", title)
        let expectedPost = postsTable.cells.element(matching: predicate)

        XCTAssertTrue(expectedPost.exists)
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
