import Foundation
import XCTest

class AppSettingsScreen: BaseScreen {
    let settingsTable: XCUIElement
    let tabBar: TabNavComponent

    init() {
        settingsTable = XCUIApplication().tables["appSettingsTable"]
        tabBar = TabNavComponent()

        super.init(element: settingsTable)
    }

    static func isLoaded() -> Bool {
        return XCUIApplication().navigationBars["App Settings"].exists
    }
}
