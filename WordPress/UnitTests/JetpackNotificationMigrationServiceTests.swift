import XCTest
@testable import WordPress

final class JetpackNotificationMigrationServiceTests: XCTestCase {

    private var sut: JetpackNotificationMigrationService!
    private var remoteNotificationsRegister: RemoteNotificationRegisterMock!
    private var remoteFeatureFlagStore: RemoteFeatureFlagStoreMock!
    private var userDefaults: UserDefaultsMock!

    override func setUpWithError() throws {
        remoteNotificationsRegister = RemoteNotificationRegisterMock()
        remoteFeatureFlagStore = RemoteFeatureFlagStoreMock()
        userDefaults = UserDefaultsMock()
    }

    override func tearDownWithError() throws {
        sut = nil
        remoteNotificationsRegister = nil
        remoteFeatureFlagStore = nil
        userDefaults = nil
    }

    // MARK: - Should show notification control

    func testShouldShowNotificationControlInWordPressWhenFeatureFlagEnabled() {
        setup(preventDuplicateNotificationsFlag: true, isWordPress: true)

        XCTAssertTrue(sut.shouldShowNotificationControl())
    }

    func testShouldHideNotificationControlInWordPressWhenFeatureFlagDisabled() {
        setup(preventDuplicateNotificationsFlag: false, isWordPress: true)

        XCTAssertFalse(sut.shouldShowNotificationControl())
    }

    func testShouldHideNotificationControlInJetpackWhenFeatureFlagEnabled() {
        setup(preventDuplicateNotificationsFlag: true, isWordPress: false)

        XCTAssertFalse(sut.shouldShowNotificationControl())
    }

    // MARK: - WordPress notifications enabled

    func testWordPressNotificationsEnabledWhenRegisteredForRemoteNotications() {
        setup(preventDuplicateNotificationsFlag: true, isWordPress: true)

        remoteNotificationsRegister.isRegisteredForRemoteNotifications = false
        XCTAssertFalse(sut.wordPressNotificationsEnabled)

        remoteNotificationsRegister.isRegisteredForRemoteNotifications = true
        XCTAssertTrue(sut.wordPressNotificationsEnabled)
    }

    func testRemoteNotificationsRegisteredWhenWordPressNotificationsEnabled() {
        setup(preventDuplicateNotificationsFlag: true, isWordPress: true)

        sut.wordPressNotificationsEnabled = false
        XCTAssertTrue(remoteNotificationsRegister.unregisterForRemoteNotificationsCalled)

        sut.wordPressNotificationsEnabled = true
        XCTAssertTrue(remoteNotificationsRegister.registerForRemoteNotificationsCalled)
    }

    // MARK: - Should present WordPress notifications

    func testShouldHideNotificationsInWordPressWhenFeatureFlagEnabledAndWordPressNotificationsDisabled() {
        setup(preventDuplicateNotificationsFlag: true, isWordPress: true)
        sut.wordPressNotificationsEnabled = false

        XCTAssertFalse(sut.shouldPresentNotifications())
    }

    func testShouldPresentNotificationsBeforeWordPressNotificationsToggledAndNotificationsRegistered() {
        setup(preventDuplicateNotificationsFlag: true, isWordPress: true)
        remoteNotificationsRegister.isRegisteredForRemoteNotifications = false
        userDefaults.wordPressNotificationsToggled = false

        XCTAssertTrue(sut.shouldPresentNotifications())
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
               isWordPress: Bool) {

        remoteFeatureFlagStore.isPreventDuplicateNotifications = preventDuplicateNotificationsFlag

        sut = JetpackNotificationMigrationService(
            remoteNotificationRegister: remoteNotificationsRegister,
            featureFlagStore: remoteFeatureFlagStore,
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

private extension JetpackNotificationMigrationServiceTests {
    class RemoteFeatureFlagStoreMock: RemoteFeatureFlagStore {
        var isPreventDuplicateNotifications = false

        override func value(for flagKey: String) -> Bool? {
            if flagKey == RemoteFeatureFlag.jetpackMigrationPreventDuplicateNotifications.remoteKey {
                return isPreventDuplicateNotifications
            }

            return false
        }
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
