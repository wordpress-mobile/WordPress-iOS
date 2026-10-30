import XCTest
@testable import WordPress

final class JetpackNotificationMigrationServiceTests: XCTestCase {

    private var sut: JetpackNotificationMigrationService!
    private var remoteNotificationsRegister: RemoteNotificationRegisterMock!
    private var userDefaults: UserDefaultsMock!
    private var savedAppUIType: RootViewCoordinator.AppUIType?

    override func setUpWithError() throws {
        // `shouldPresentNotifications()` also hides notifications when Jetpack features are disabled.
        // Pin the UI type so these tests only exercise the migration logic.
        savedAppUIType = JetpackFeaturesRemovalCoordinator.currentAppUIType
        JetpackFeaturesRemovalCoordinator.currentAppUIType = .normal
        remoteNotificationsRegister = RemoteNotificationRegisterMock()
        userDefaults = UserDefaultsMock()
    }

    override func tearDownWithError() throws {
        JetpackFeaturesRemovalCoordinator.currentAppUIType = savedAppUIType
        sut = nil
        remoteNotificationsRegister = nil
        userDefaults = nil
    }

    // MARK: - Should show notification control

    func testShouldShowNotificationControlInWordPress() {
        setup(isWordPress: true)

        XCTAssertTrue(sut.shouldShowNotificationControl())
    }

    func testShouldHideNotificationControlInJetpack() {
        setup(isWordPress: false)

        XCTAssertFalse(sut.shouldShowNotificationControl())
    }

    // MARK: - WordPress notifications enabled

    func testWordPressNotificationsEnabledWhenRegisteredForRemoteNotications() {
        setup(isWordPress: true)

        remoteNotificationsRegister.isRegisteredForRemoteNotifications = false
        XCTAssertFalse(sut.wordPressNotificationsEnabled)

        remoteNotificationsRegister.isRegisteredForRemoteNotifications = true
        XCTAssertTrue(sut.wordPressNotificationsEnabled)
    }

    func testRemoteNotificationsRegisteredWhenWordPressNotificationsEnabled() {
        setup(isWordPress: true)

        sut.wordPressNotificationsEnabled = false
        XCTAssertTrue(remoteNotificationsRegister.unregisterForRemoteNotificationsCalled)

        sut.wordPressNotificationsEnabled = true
        XCTAssertTrue(remoteNotificationsRegister.registerForRemoteNotificationsCalled)
    }

    // MARK: - Should present WordPress notifications

    func testShouldHideNotificationsInWordPressWhenWordPressNotificationsDisabled() {
        setup(isWordPress: true)
        sut.wordPressNotificationsEnabled = false

        XCTAssertFalse(sut.shouldPresentNotifications())
    }

    func testShouldPresentNotificationsBeforeWordPressNotificationsToggledAndNotificationsRegistered() {
        setup(isWordPress: true)
        remoteNotificationsRegister.isRegisteredForRemoteNotifications = false
        userDefaults.wordPressNotificationsToggled = false

        XCTAssertTrue(sut.shouldPresentNotifications())
    }

    func testShouldPresentNotificationsInWordPressWhenWordPressNotificationsEnabled() {
        setup(isWordPress: true)
        sut.wordPressNotificationsEnabled = true

        XCTAssertTrue(sut.shouldPresentNotifications())
    }

    func testShouldPresentNotificationsInJetpack() {
        setup(isWordPress: false)

        XCTAssertTrue(sut.shouldPresentNotifications())
    }
}

// MARK: - Helpers

private extension JetpackNotificationMigrationServiceTests {
    func setup(isWordPress: Bool) {
        sut = JetpackNotificationMigrationService(
            remoteNotificationRegister: remoteNotificationsRegister,
            userDefaults: userDefaults,
            isWordPress: isWordPress
        )
        userDefaults.wordPressNotificationsToggled = true
        sut.wordPressNotificationsEnabled = true
        remoteNotificationsRegister.isRegisteredForRemoteNotifications = true
    }
}

private class RemoteNotificationRegisterMock: RemoteNotificationRegister {
    var registerForRemoteNotificationsCalled = false
    var unregisterForRemoteNotificationsCalled = false
    var isRegisteredForRemoteNotifications = false

    func registerForRemoteNotifications() {
        isRegisteredForRemoteNotifications = true
        registerForRemoteNotificationsCalled = true
    }

    func unregisterForRemoteNotifications() {
        isRegisteredForRemoteNotifications = false
        unregisterForRemoteNotificationsCalled = true
    }
}

private class UserDefaultsMock: UserDefaults {
    var wordPressNotificationsToggled = false

    override func bool(forKey defaultName: String) -> Bool {
        if defaultName == "wordPressNotificationsToggledDefaultsKey" {
            return wordPressNotificationsToggled
        }

        return super.bool(forKey: defaultName)
    }
}
