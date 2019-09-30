import Foundation
import XCTest

class SiteSettingsScreen: BaseScreen {
    enum Toggle {
        case on
        case off
    }
    let settingsTable: XCUIElement
    let blockEditorToggle: XCUIElement
    let tabBar: TabNavComponent

    init() {
        settingsTable = XCUIApplication().tables["siteSettingsTable"]
        blockEditorToggle = settingsTable.switches["useBlockEditorSwitch"]
        tabBar = TabNavComponent()

        super.init(element: settingsTable)
    }

    @discardableResult
    func toggleBlockEditor(to state: Toggle) -> SiteSettingsScreen {
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

    func goBackToMySite() -> MySiteScreen {
        if isIPhone {
            navBackButton.tap()
        }
        return MySiteScreen()
    }

    private func isBlockEditorEnabled() -> Bool {
        return blockEditorToggle.value as! String == "1"
    }

    static func isLoaded() -> Bool {
        return XCUIApplication().navigationBars["Settings"].exists
    }
}
