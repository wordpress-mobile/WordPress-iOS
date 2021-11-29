import ScreenObject
import XCTest

public class SiteSettingsScreen: ScreenObject {

    public enum Toggle {
        case on
        case off
    }

    private let blockEditorToggleGetter: (XCUIApplication) -> XCUIElement = {
        $0.tables["siteSettingsTable"].switches["useBlockEditorSwitch"]
    }
    var blockEditorToggle: XCUIElement { blockEditorToggleGetter(app) }

    public init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(expectedElementGetters: [blockEditorToggleGetter], app: app)
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

    public func goBackToMySite() throws -> MySiteScreen {
        if XCUIDevice.isPhone {
            navBackButton.tap()
        }
        return try MySiteScreen()
    }

    private func isBlockEditorEnabled() -> Bool {
        return blockEditorToggle.value as! String == "1"
    }

    public static func isLoaded() -> Bool {
        (try? SiteSettingsScreen().isLoaded) ?? false
    }
}
