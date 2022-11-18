import XCTest
@testable import WordPress

final class JetpackNotificationMigrationServiceTests: XCTestCase {

    private var sut: JetpackNotificationMigrationService!
    private var notificationSettingsLoader: NotificationSettingsLoaderMock!
    private var remoteNotificationsRegister: RemoteNotificationRegisterMock!

    override func setUpWithError() throws {
        notificationSettingsLoader = NotificationSettingsLoaderMock()
        remoteNotificationsRegister = RemoteNotificationRegisterMock()
    }

    override func tearDownWithError() throws {
        sut = nil
        notificationSettingsLoader = nil
        remoteNotificationsRegister = nil
    }

    // MARK: - Should show notification control

    func testShouldShowNotificationControlInWordPressWhenFeatureFlagEnabledAndNotificationsEnabled() {
        setup(allowDisablingWPNotifications: true, isWordPress: true, notificationsEnabled: true)

        XCTAssertTrue(sut.shouldShowNotificationControl())
    }

    func testShouldHideNotificationControlInWordPressWhenFeatureFlagEnabledAndNotificationsDisabled() {
        setup(allowDisablingWPNotifications: true, isWordPress: true, notificationsEnabled: false)

        XCTAssertFalse(sut.shouldShowNotificationControl())
    }

    func testShouldHideNotificationControlInWordPressWhenFeatureFlagDisabled() {
        setup(allowDisablingWPNotifications: false, isWordPress: true, notificationsEnabled: true)

        XCTAssertFalse(sut.shouldShowNotificationControl())
    }

    func testShouldHideNotificationControlInJetpackWhenFeatureFlagEnabled() {
        setup(allowDisablingWPNotifications: true, isWordPress: false, notificationsEnabled: true)

        XCTAssertFalse(sut.shouldShowNotificationControl())
    }

    // MARK: - WordPress notifications enabled

    func testWordPressNotificationsEnabledWhenRegisteredForRemoteNotications() {
        setup(allowDisablingWPNotifications: true, isWordPress: true)
        remoteNotificationsRegister.isRegisteredForRemoteNotifications = true

        XCTAssertTrue(sut.wordPressNotificationsEnabled)

        sut.wordPressNotificationsEnabled = false
        XCTAssertFalse(sut.wordPressNotificationsEnabled)
        XCTAssertTrue(remoteNotificationsRegister.unregisterForRemoteNotificationsCalled)

        sut.wordPressNotificationsEnabled = true
        XCTAssertTrue(sut.wordPressNotificationsEnabled)
        XCTAssertTrue(remoteNotificationsRegister.registerForRemoteNotificationsCalled)
    }

    func testWordPressNotificationsEnabledWhenUnegisteredForRemoteNotications() {
        setup(allowDisablingWPNotifications: true, isWordPress: true)
        remoteNotificationsRegister.isRegisteredForRemoteNotifications = false

        sut.wordPressNotificationsEnabled = false
        XCTAssertFalse(sut.wordPressNotificationsEnabled)

        sut.wordPressNotificationsEnabled = true
        XCTAssertFalse(sut.wordPressNotificationsEnabled)
    }

    // MARK: - Should disable WordPress notifications

    func testShouldDisableNotificationsInWordPressWhenFeatureFlagEnabledAndWordPressNotificationsDisabled() {
        setup(allowDisablingWPNotifications: true, isWordPress: true)
        sut.wordPressNotificationsEnabled = false

        XCTAssertTrue(sut.shouldDisableNotifications())
    }

    func testShouldAllowNotificationsInWordPressWhenFeatureFlagDisabledAndWordPressNotificationsDisabled() {
        setup(allowDisablingWPNotifications: false, isWordPress: true)
        sut.wordPressNotificationsEnabled = false

        XCTAssertFalse(sut.shouldDisableNotifications())
    }

    func testShouldAllowNotificationsInWordPressWhenFeatureFlagEnabledAndWordPressNotificationsEnabled() {
        setup(allowDisablingWPNotifications: true, isWordPress: true)
        sut.wordPressNotificationsEnabled = true

        XCTAssertFalse(sut.shouldDisableNotifications())
    }

    func testShouldAllowNotificationsInJetpack() {
        setup(allowDisablingWPNotifications: true, isWordPress: false)

        XCTAssertFalse(sut.shouldDisableNotifications())
    }
}

// MARK: - Helpers

private extension JetpackNotificationMigrationServiceTests {
    func setup(allowDisablingWPNotifications: Bool,
               isWordPress: Bool,
               notificationsEnabled: Bool = true) {
        notificationSettingsLoader.authorizationStatus = notificationsEnabled ? .authorized : .denied
        sut = JetpackNotificationMigrationService(
            notificationSettingsLoader: notificationSettingsLoader,
            remoteNotificationRegister: remoteNotificationsRegister,
            allowDisablingWPNotifications: allowDisablingWPNotifications,
            isWordPress: isWordPress
        )
        sut.wordPressNotificationsEnabled = true
        remoteNotificationsRegister.isRegisteredForRemoteNotifications = true
    }
}

private class NotificationSettingsLoaderMock: NotificationSettingsLoader {
    var authorizationStatus: UNAuthorizationStatus = .notDetermined

    func getNotificationAuthorizationStatus(completionHandler: @escaping (UNAuthorizationStatus) -> Void) {
        completionHandler(authorizationStatus)
    }
}

private class RemoteNotificationRegisterMock: RemoteNotificationRegister {
    var registerForRemoteNotificationsCalled = false
    var unregisterForRemoteNotificationsCalled = false
    var isRegisteredForRemoteNotifications = false

    func registerForRemoteNotifications() {
        registerForRemoteNotificationsCalled = true
    }

    func unregisterForRemoteNotifications() {
        unregisterForRemoteNotificationsCalled = true
    }
}
