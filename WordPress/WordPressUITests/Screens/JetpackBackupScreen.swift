import UITestsFoundation
import XCTest

private struct ElementStringIDs {
    static let actionButton = "activity-cell-action-button"
    static let backupTable = "jetpack-backup-table"
}

class JetpackBackupScreen: BaseScreen {
    let ellipsisButton: XCUIElement
    let downloadBackupButton: XCUIElement

    init() {
        let app = XCUIApplication()
        let backupTable = app.tables[ElementStringIDs.backupTable]
        let firstCell = backupTable.cells.element(boundBy: 0)
        ellipsisButton = firstCell.buttons[ElementStringIDs.actionButton]
        downloadBackupButton = app.sheets.buttons.element(boundBy: 1)
        super.init(element: ellipsisButton)
    }

    func goToBackupOptions() -> JetpackBackupOptionsScreen {
        ellipsisButton.tap()

        XCTAssert(downloadBackupButton.waitForExistence(timeout: 3))
        XCTAssert(downloadBackupButton.waitForHittability(timeout: 3))

        XCTAssert(downloadBackupButton.isHittable)

        downloadBackupButton.tap()

        return JetpackBackupOptionsScreen()
    }
}
