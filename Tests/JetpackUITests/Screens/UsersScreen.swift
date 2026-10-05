import XCTest

/// The site's users list.
final class UsersScreen: ScreenObject {
    private let tableGetter: ElementGetter = {
        $0.tables["users_table_view"]
    }

    init(app: XCUIApplication) throws {
        try super.init(expectedElementGetters: [tableGetter, Self.navigationBarTitle("Users")], app: app)
    }

    func goToFirstUser() throws -> UserDetailsScreen {
        try tapFirst(tableGetter(app).cells.firstMatch, named: "users")
        return try UserDetailsScreen(app: app)
    }
}
