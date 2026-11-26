import XCTest

/// The details of one of the site's users.
final class UserDetailsScreen: ScreenObject {
    private let tableGetter: ElementGetter = {
        $0.tables["person_table_view"]
    }

    init(app: XCUIApplication) throws {
        try super.init(expectedElementGetters: [tableGetter], app: app)
    }
}
