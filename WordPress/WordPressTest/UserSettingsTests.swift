import XCTest
@testable import WordPress

class UserSettingsTests: XCTestCase {

    override func tearDownWithError() throws {
        UserSettings.reset()
        try super.tearDownWithError()
    }

    func testThatUserOptedOutOfCrashLoggingDefaultsToFalse() {
        XCTAssertFalse(UserSettings.userHasOptedOutOfCrashLogging)
    }

    func testThatChangingUserHasOptedOutOfCrashLoggingWorks() {
        UserSettings.userHasOptedOutOfCrashLogging = true
        XCTAssertTrue(UserSettings.userHasOptedOutOfCrashLogging)
        UserSettings.userHasOptedOutOfCrashLogging = false
        XCTAssertFalse(UserSettings.userHasOptedOutOfCrashLogging)
    }

    /// Force Crash Logging is a setting for use in debug environments to send crash logs. It should never be enabled in production builds
    func testThatUseHasForceCrashLoggingEnabledDefaultsToFalse() {
        XCTAssertFalse(UserSettings.userHasForcedCrashLoggingEnabled)
    }

    func testThatChangingUserHasForceCrashLoggingEnabledWorks() {
        UserSettings.userHasForcedCrashLoggingEnabled = true
        XCTAssertTrue(UserSettings.userHasForcedCrashLoggingEnabled)
        UserSettings.userHasForcedCrashLoggingEnabled = false
        XCTAssertFalse(UserSettings.userHasForcedCrashLoggingEnabled)
    }

    func testThatDefaultDotComUUIDDefaultsToNil() {
        XCTAssertNil(UserSettings.defaultDotComUUID)
    }

    func testThatChangingDefaultDotComUUIDWorks() {
        let uuid = UUID().uuidString
        UserSettings.defaultDotComUUID = uuid
        XCTAssertEqual(UserSettings.defaultDotComUUID, uuid)
    }

    func testThatChangingDefaultDotComUUIDToNilWorks() {
        UserSettings.defaultDotComUUID = UUID().uuidString
        UserSettings.defaultDotComUUID = nil
        XCTAssertNil(UserSettings.defaultDotComUUID)
    }
}
