import ScreenObject
import XCTest

public class HTMLEditorScreen: ScreenObject {

    private let moreButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["more_post_options"]
    }

    private let switchToVisualModeButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["Switch to Visual Mode"]
    }

    private let undoButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.navigationBars["Gutenberg Editor Navigation Bar"].buttons["Undo"]
    }

    private let redoButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.navigationBars["Gutenberg Editor Navigation Bar"].buttons["Redo"]
    }

    var moreButton: XCUIElement { moreButtonGetter(app) }
    var switchToVisualModeButton: XCUIElement { switchToVisualModeButtonGetter(app) }
    var undoButton: XCUIElement { undoButtonGetter(app) }
    var redoButton: XCUIElement { redoButtonGetter(app) }

    init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [ moreButtonGetter ],
            app: app
        )
    }

    @discardableResult
    public func switchToVisualMode() throws -> BlockEditorScreen {
        moreButton.tap()
        switchToVisualModeButton.tap()

        return try BlockEditorScreen()
    }

    @discardableResult
    public func verifyUndoIsHidden() -> Self {
        XCTAssertFalse(undoButton.exists)

        return self
    }

    @discardableResult
    public func verifyRedoIsHidden() -> Self {
        XCTAssertFalse(redoButton.exists)

        return self
    }
}
