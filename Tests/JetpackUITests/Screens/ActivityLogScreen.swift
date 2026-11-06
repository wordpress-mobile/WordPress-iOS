import XCTest

/// The site's activity log.
final class ActivityLogScreen: ScreenObject {
    private let listGetter: ElementGetter = {
        $0.collectionViews["activity_logs_list"]
    }

    init(app: XCUIApplication) throws {
        try super.init(expectedElementGetters: [listGetter, Self.navigationBarTitle("Activity")], app: app)
    }

    func goToFirstActivity() throws -> ActivityDetailsScreen {
        try tapFirst(firstRow(in: listGetter(app)), named: "activity")
        return try ActivityDetailsScreen(app: app)
    }
}
