import XCTest
@testable import WordPress

class UserSettingsTests: XCTestCase {

    override class func setUp() {
        UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
    }

    func testUserHasOptedOutOfCrashLogging() {
        /// Verify that the default is `false` (because we're opt-in by default)
        XCTAssertFalse(UserSettings.userHasOptedOutOfCrashLogging)

        /// Verify that changing it to `true`  works
        UserSettings.userHasOptedOutOfCrashLogging = true
        XCTAssertTrue(UserSettings.userHasOptedOutOfCrashLogging)

        /// Verify that changing it back to `false` works
        UserSettings.userHasOptedOutOfCrashLogging = false
        XCTAssertFalse(UserSettings.userHasOptedOutOfCrashLogging)
    }

    func testUserHasForcedCrashLoggingEnabled() {
        /// Verify that the default is `false` (because forcing is a debugging function, not user-facing)
        XCTAssertFalse(UserSettings.userHasForcedCrashLoggingEnabled)

        /// Verify that changing it to `true`  works
        UserSettings.userHasForcedCrashLoggingEnabled = true
        XCTAssertTrue(UserSettings.userHasForcedCrashLoggingEnabled)

        /// Verify that changing it back to `false` works
        UserSettings.userHasForcedCrashLoggingEnabled = false
        XCTAssertFalse(UserSettings.userHasForcedCrashLoggingEnabled)
    }

    func testDefaultDotComUUID() {
        let testUUID = UUID().uuidString

        /// Verify that the default is `nil` (ie – the user is logged out)
        XCTAssertNil(UserSettings.defaultDotComUUID)

        /// Test that the UUID is set correctly
        UserSettings.defaultDotComUUID = testUUID
        XCTAssertEqual(UserSettings.defaultDotComUUID, testUUID)

        /// Test that the UUID can be removed
        UserSettings.defaultDotComUUID = nil
        XCTAssertNil(UserSettings.defaultDotComUUID)
    }
}
