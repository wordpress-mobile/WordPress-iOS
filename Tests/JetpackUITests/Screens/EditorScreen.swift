import XCTest

/// The editor for a post or page.
///
/// New posts and posts with block content open in the block editor, and older posts in the classic
/// editor. Both have the close button this screen is identified by.
final class EditorScreen: ScreenObject {
    private let closeButtonGetter: ElementGetter = {
        $0.buttons["editor-close-button"]
    }

    var closeButton: XCUIElement { closeButtonGetter(app) }

    init(app: XCUIApplication) throws {
        Self.declineAutosave(in: app, coveringEditorWith: closeButtonGetter(app))
        try super.init(expectedElementGetters: [closeButtonGetter], app: app)
    }

    /// Closes the editor. If the post has changes, discards them from the confirmation sheet.
    func close() {
        closeButton.tap()

        let confirmation = app.sheets["post-has-changes-alert"]
        if confirmation.pollForExistence(timeout: 3) {
            // "Discard Draft" for a new post, "Discard Changes" for an existing one.
            confirmation.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Discard'")).firstMatch.tap()
        }
    }

    /// Closes an editor opened from My Site, discarding any changes.
    @discardableResult
    func closeAndDiscardChanges() throws -> MySiteScreen {
        close()
        return try MySiteScreen(app: app)
    }

    /// A post with a newer autosave on the server opens with an alert offering to load it, which
    /// covers the editor. Declining leaves the post as it is.
    private static func declineAutosave(in app: XCUIApplication, coveringEditorWith closeButton: XCUIElement) {
        let alert = app.alerts["Autosave Available"]
        let deadline = Date(timeIntervalSinceNow: defaultWaitTimeout)

        while !closeButton.isHittable, Date() < deadline {
            if alert.exists {
                alert.buttons["Cancel"].tap()
            }
        }
    }
}
