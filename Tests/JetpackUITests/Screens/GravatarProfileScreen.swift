import XCTest

/// The sheet for editing the account's Gravatar profile, opened from My Profile.
final class GravatarProfileScreen: ScreenObject {
    private let doneButtonGetter: ElementGetter = {
        $0.buttons["Done"]
    }

    init(app: XCUIApplication) throws {
        try super.init(expectedElementGetters: [{ $0.staticTexts["Gravatar"] }, doneButtonGetter], app: app)
    }

    @discardableResult
    func done() throws -> MeScreen {
        doneButtonGetter(app).tap()
        return try MeScreen(app: app)
    }
}
