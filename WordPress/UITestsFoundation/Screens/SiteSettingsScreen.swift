import XCTest

public class SiteSettingsScreen: BaseScreen {

    public enum Toggle {
        case on
        case off
    }

    let settingsTable: XCUIElement
    let blockEditorToggle: XCUIElement
    let tabBar: TabNavComponent

    public init() {
        settingsTable = XCUIApplication().tables["siteSettingsTable"]
        blockEditorToggle = settingsTable.switches["useBlockEditorSwitch"]
        tabBar = TabNavComponent()

        super.init(element: settingsTable)
    }

    @discardableResult
    public func toggleBlockEditor(to state: Toggle) -> SiteSettingsScreen {
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

    public func goBackToMySite() -> MySiteScreen {
        if XCUIDevice.isPhone {
            navBackButton.tap()
        }
        return MySiteScreen()
    }

    private func isBlockEditorEnabled() -> Bool {
        return blockEditorToggle.value as! String == "1"
    }

    public static func isLoaded() -> Bool {
        return XCUIApplication().navigationBars["Settings"].exists
    }
}
