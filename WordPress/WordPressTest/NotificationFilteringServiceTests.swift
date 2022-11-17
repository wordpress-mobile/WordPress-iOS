import XCTest
@testable import WordPress

final class JetpackNotificationMigrationServiceTests: XCTestCase {

    private var sut: JetpackNotificationMigrationService!
    private var notificationSettingsLoader: NotificationSettingsLoaderMock!

    override func setUpWithError() throws {
        notificationSettingsLoader = NotificationSettingsLoaderMock()
    }

    override func tearDownWithError() throws {
        sut = nil
        notificationSettingsLoader = nil
    }

    // MARK: - Should show notification control

    func testShouldShowNotificationControlInWordPressWhenFeatureFlagEnabledAndNotificationsEnabled() {
        setup(allowDisablingWPNotifications: true, isWordPress: true, notificationsEnabled: true)

        XCTAssertTrue(sut.shouldShowNotificationControl())
    }

    func testShouldShowNotificationControlInWordPressWhenFeatureFlagEnabledAndNotificationsDisabled() {
        setup(allowDisablingWPNotifications: true, isWordPress: true, notificationsEnabled: false)

        XCTAssertFalse(sut.shouldShowNotificationControl())
    }

    func testShouldShowNotificationControlInWordPressWhenFeatureFlagDisabled() {
        setup(allowDisablingWPNotifications: false, isWordPress: true, notificationsEnabled: true)

        XCTAssertFalse(sut.shouldShowNotificationControl())
    }

    func testShouldShowNotificationControlInJetpackWhenFeatureFlagEnabled() {
        setup(allowDisablingWPNotifications: true, isWordPress: false, notificationsEnabled: true)

        XCTAssertFalse(sut.shouldShowNotificationControl())
    }

    // MARK: - WordPress notifications enabled

    func testWordPressNotificationsEnabled() {
        setup(allowDisablingWPNotifications: true, isWordPress: true)

        XCTAssertTrue(sut.wordPressNotificationsEnabled)
        sut.wordPressNotificationsEnabled = false
        XCTAssertFalse(sut.wordPressNotificationsEnabled)
        sut.wordPressNotificationsEnabled = true
        XCTAssertTrue(sut.wordPressNotificationsEnabled)
    }

    // MARK: - Should disable WordPress notifications

    func testShouldDisableWordPressNotificationsInWordPressWhenFeatureFlagEnabledAndWordPressNotificationsDisabled() {
        setup(allowDisablingWPNotifications: true, isWordPress: true)
        sut.wordPressNotificationsEnabled = false

        XCTAssertTrue(sut.shouldDisableWordPressNotifications())
    }

    func testShouldDisableWordPressNotificationsInWordPressWhenFeatureFlagDisabledAndWordPressNotificationsDisabled() {
        setup(allowDisablingWPNotifications: false, isWordPress: true)
        sut.wordPressNotificationsEnabled = false

        XCTAssertFalse(sut.shouldDisableWordPressNotifications())
    }

    func testShouldDisableWordPressNotificationsInWordPressWhenFeatureFlagEnabledAndWordPressNotificationsEnabled() {
        setup(allowDisablingWPNotifications: true, isWordPress: true)
        sut.wordPressNotificationsEnabled = true

        XCTAssertFalse(sut.shouldDisableWordPressNotifications())
    }

    func testShouldDisableWordPressNotificationsInJetpack() {
        setup(allowDisablingWPNotifications: true, isWordPress: false)

        XCTAssertFalse(sut.shouldDisableWordPressNotifications())
    }
}

// MARK: - Helpers

private extension JetpackNotificationMigrationServiceTests {
    func setup(allowDisablingWPNotifications: Bool,
               isWordPress: Bool,
               notificationsEnabled: Bool = true) {
        notificationSettingsLoader.authorizationStatus = notificationsEnabled ? .authorized : .denied
        sut = JetpackNotificationMigrationService(notificationSettingsLoader: notificationSettingsLoader,
                                           allowDisablingWPNotifications: allowDisablingWPNotifications,
                                           isWordPress: isWordPress)
        sut.wordPressNotificationsEnabled = true
    }
}

private class NotificationSettingsLoaderMock: NotificationSettingsLoader {
    var authorizationStatus: UNAuthorizationStatus = .notDetermined

    func getNotificationAuthorizationStatus(completionHandler: @escaping (UNAuthorizationStatus) -> Void) {
        completionHandler(authorizationStatus)
    }
}
