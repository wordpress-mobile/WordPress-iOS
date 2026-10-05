import XCTest

/// The site's subscribers list.
final class SubscribersScreen: ScreenObject {
    init(app: XCUIApplication) throws {
        try super.init(expectedElementGetters: [Self.navigationBarTitle("Subscribers")], app: app)
    }

    func goToFirstSubscriber() throws -> SubscriberDetailsScreen {
        try tapFirst(firstRow(in: app.collectionViews.firstMatch), named: "subscribers")
        return try SubscriberDetailsScreen(app: app)
    }
}
