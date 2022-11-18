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
        setup(preventDuplicateNotificationsFlag: true, isWordPress: true, notificationsEnabled: true)

        XCTAssertTrue(sut.shouldShowNotificationControl())
    }

    func testShouldHideNotificationControlInWordPressWhenFeatureFlagEnabledAndNotificationsDisabled() {
        setup(preventDuplicateNotificationsFlag: true, isWordPress: true, notificationsEnabled: false)

        XCTAssertFalse(sut.shouldShowNotificationControl())
    }

    func testShouldHideNotificationControlInWordPressWhenFeatureFlagDisabled() {
        setup(preventDuplicateNotificationsFlag: false, isWordPress: true, notificationsEnabled: true)

        XCTAssertFalse(sut.shouldShowNotificationControl())
    }

    func testShouldHideNotificationControlInJetpackWhenFeatureFlagEnabled() {
        setup(preventDuplicateNotificationsFlag: true, isWordPress: false, notificationsEnabled: true)

        XCTAssertFalse(sut.shouldShowNotificationControl())
    }

    // MARK: - WordPress notifications enabled

    func testWordPressNotificationsEnabledWhenRegisteredForRemoteNotications() {
        setup(preventDuplicateNotificationsFlag: true, isWordPress: true)
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
        setup(preventDuplicateNotificationsFlag: true, isWordPress: true)
        remoteNotificationsRegister.isRegisteredForRemoteNotifications = false

        sut.wordPressNotificationsEnabled = false
        XCTAssertFalse(sut.wordPressNotificationsEnabled)

        sut.wordPressNotificationsEnabled = true
        XCTAssertFalse(sut.wordPressNotificationsEnabled)
    }

    // MARK: - Should present WordPress notifications

    func testShouldHideNotificationsInWordPressWhenFeatureFlagEnabledAndWordPressNotificationsDisabled() {
        setup(preventDuplicateNotificationsFlag: true, isWordPress: true)
        sut.wordPressNotificationsEnabled = false

        XCTAssertFalse(sut.shouldPresentNotifications())
    }

    func testShouldPresentNotificationsInWordPressWhenFeatureFlagDisabledAndWordPressNotificationsDisabled() {
        setup(preventDuplicateNotificationsFlag: false, isWordPress: true)
        sut.wordPressNotificationsEnabled = false

        XCTAssertTrue(sut.shouldPresentNotifications())
    }

    func testShouldPresentNotificationsInWordPressWhenFeatureFlagEnabledAndWordPressNotificationsEnabled() {
        setup(preventDuplicateNotificationsFlag: true, isWordPress: true)
        sut.wordPressNotificationsEnabled = true

        XCTAssertTrue(sut.shouldPresentNotifications())
    }

    func testShouldPresentNotificationsInJetpack() {
        setup(preventDuplicateNotificationsFlag: true, isWordPress: false)

        XCTAssertTrue(sut.shouldPresentNotifications())
    }
}

// MARK: - Helpers

private extension JetpackNotificationMigrationServiceTests {
    func setup(preventDuplicateNotificationsFlag: Bool,
               isWordPress: Bool,
               notificationsEnabled: Bool = true) {
        notificationSettingsLoader.authorizationStatus = notificationsEnabled ? .authorized : .denied

        sut = JetpackNotificationMigrationService(
            notificationSettingsLoader: notificationSettingsLoader,
            remoteNotificationRegister: remoteNotificationsRegister,
            preventDuplicateNotifications: preventDuplicateNotificationsFlag,
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
