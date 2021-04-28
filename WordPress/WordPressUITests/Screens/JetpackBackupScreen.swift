import Foundation
import XCTest

class JetpackBackupScreen: BaseScreen {
    let ellipsisButton: XCUIElement
    let downloadBackupButton: XCUIElement

    init() {
        let app = XCUIApplication()
        ellipsisButton = app.cells.firstMatch.buttons.firstMatch
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
