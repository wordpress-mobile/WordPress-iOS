import ScreenObject
import XCTest

public class JetpackBackupScreen: ScreenObject {

    private let ellipsisButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.tables["jetpack-backup-table"].cells.element(boundBy: 0).buttons["activity-cell-action-button"]
    }

    var ellipsisButton: XCUIElement { ellipsisButtonGetter(app) }
    var downloadBackupButton: XCUIElement { app.sheets.buttons.element(boundBy: 1) }

    public init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(expectedElementGetters: [ellipsisButtonGetter], app: app)
    }

    public func goToBackupOptions() throws -> JetpackBackupOptionsScreen {
        ellipsisButton.tap()

        XCTAssert(downloadBackupButton.waitForExistence(timeout: 3))
        XCTAssert(downloadBackupButton.waitForIsHittable(timeout: 3))

        XCTAssert(downloadBackupButton.isHittable)

        downloadBackupButton.tap()

        return try JetpackBackupOptionsScreen()
    }
}
