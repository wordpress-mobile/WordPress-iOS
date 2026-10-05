import XCTest

/// The site's Blaze campaigns list.
final class BlazeCampaignsScreen: ScreenObject {
    init(app: XCUIApplication) throws {
        try super.init(expectedElementGetters: [Self.navigationBarTitle("Blaze Campaigns")], app: app)
    }
}
