import XCTest

/// The settings for one connected social media account.
final class SocialConnectionScreen: ScreenObject {
    private let disconnectButtonGetter: ElementGetter = {
        $0.buttons["Disconnect"]
    }

    init(app: XCUIApplication) throws {
        try super.init(expectedElementGetters: [disconnectButtonGetter], app: app)
    }
}
