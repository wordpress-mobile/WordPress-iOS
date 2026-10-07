import XCTest

/// The app's own settings, which it stores on the device.
final class AppSettingsScreen: ScreenObject {
    /// The rows that push another screen, each with the title of the screen it pushes.
    enum Section: String, CaseIterable {
        case maxVideoUploadSize = "Max Video Upload Size"
        case mediaCache = "Media Cache"
        case privacySettings = "Privacy Settings"
        case appearance = "Appearance"
        case appIcon = "App Icon"
        case experimentalFeatures = "Experimental Features"
        case savedPosts = "Saved Posts"
        case designSystem = "Design System"

        var screenTitle: String {
            switch self {
            case .maxVideoUploadSize: "Resolution"
            default: rawValue
            }
        }
    }

    private let tableGetter: ElementGetter = {
        $0.tables["appSettingsTable"]
    }

    var table: XCUIElement { tableGetter(app) }

    init(app: XCUIApplication) throws {
        try super.init(expectedElementGetters: [tableGetter, Self.navigationBarTitle("App Settings")], app: app)
    }

    func goTo(_ section: Section) throws -> TitledScreen {
        let row = table.staticTexts[section.rawValue]
        try scroll(to: row, in: table)
        row.tap()
        return try TitledScreen(title: section.screenTitle, app: app)
    }
}
