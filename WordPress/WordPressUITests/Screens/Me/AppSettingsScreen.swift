import Foundation
import XCTest

class AppSettingsScreen: BaseScreen {
    enum Toggle {
        case on
        case off
    }
    let settingsTable: XCUIElement
    let blockEditorToggle: XCUIElement
    let tabBar: TabNavComponent

    init() {
        settingsTable = XCUIApplication().tables["appSettingsTable"]
        blockEditorToggle = settingsTable.switches["useBlockEditorSwitch"]
        tabBar = TabNavComponent()

        super.init(element: settingsTable)
    }

    @discardableResult
    func toggleBlockEditor(to state: Toggle) -> AppSettingsScreen {
        switch state {
        case .on:
            if !isBlockEditorEnabled() {
                blockEditorToggle.tap()
            }
        case .off:
            if isBlockEditorEnabled() {
                blockEditorToggle.tap()
            }
        }
        return self
    }

    private func isBlockEditorEnabled() -> Bool {
        return blockEditorToggle.value as! String == "1"
    }

    static func isLoaded() -> Bool {
        return XCUIApplication().navigationBars["App Settings"].exists
    }
}
