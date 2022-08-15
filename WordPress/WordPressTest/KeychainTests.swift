import XCTest
@testable import WordPress

class KeychainTests: XCTestCase {

    let username = "Username"
    let password = "Password"
    let service = "Service"
    let sharedGroup = WPAppKeychainAccessGroup

    override func setUp() {
        super.setUp()

        SFHFKeychainUtilsMock.configure(with: [:])
    }

    func testNilAppGroupSavesToSharedGroupWhenFeatureEnabled() {
        let subject = Keychain(useSharedKeychain: true, keychainUtils: SFHFKeychainUtilsMock.self)

        try? subject.storeUsername(username, password: password, serviceName: service, updateExisting: true)

        let result = getPassword(username: username, serviceName: service, accessGroup: sharedGroup)
        XCTAssertEqual(result, password)
    }

    func testNilAppGroupDoesNotSaveToSharedGroupWhenFeatureDisabled() {
        let subject = Keychain(useSharedKeychain: false, keychainUtils: SFHFKeychainUtilsMock.self)

        try? subject.storeUsername(username, password: password, serviceName: service, updateExisting: true)

        let result = getPassword(username: username, serviceName: service, accessGroup: sharedGroup)
        XCTAssertNotEqual(result, password)
    }

    func testFeatureFlagChanging() {
        var enabled = false
        let subject = Keychain(useSharedKeychain: enabled, keychainUtils: SFHFKeychainUtilsMock.self)

        enabled = true
        try? subject.storeUsername(username, password: password, serviceName: service, updateExisting: true)

        let result = getPassword(username: username, serviceName: service, accessGroup: sharedGroup)
        XCTAssertEqual(result, password)
    }

    func testNilAppGroupReadsFromSharedGroupWhenFeatureEnabled() {
        let subject = Keychain(useSharedKeychain: true, keychainUtils: SFHFKeychainUtilsMock.self)
        storeUsername(username, password: password, serviceName: service, accessGroup: sharedGroup)

        let result = try? subject.getPasswordForUsername(username, serviceName: service)

        XCTAssertEqual(result, password)
    }

    func testNilAppGroupDoesNotReadFromSharedGroupWhenFeatureDisabled() {
        let subject = Keychain(useSharedKeychain: false, keychainUtils: SFHFKeychainUtilsMock.self)
        storeUsername(username, password: password, serviceName: service, accessGroup: sharedGroup)

        let result = try? subject.getPasswordForUsername(username, serviceName: service)

        XCTAssertNotEqual(result, password)
    }

    func testNilAppGroupDeletesFromSharedGroupWhenEnabled() {
        storeUsername(username, password: password, serviceName: service, accessGroup: sharedGroup)
        storeUsername(username, password: password, serviceName: service, accessGroup: nil)
        let subject = Keychain(useSharedKeychain: true, keychainUtils: SFHFKeychainUtilsMock.self)

        try? subject.deleteItem(username: username, serviceName: service)

        XCTAssertNil(getPassword(username: username, serviceName: service, accessGroup: sharedGroup))
        XCTAssertEqual(getPassword(username: username, serviceName: service, accessGroup: nil), password)
    }

    func testNilAppGroupDeletesFromNilGroupWhenDisabled() {
        storeUsername(username, password: password, serviceName: service, accessGroup: sharedGroup)
        storeUsername(username, password: password, serviceName: service, accessGroup: nil)
        let subject = Keychain(useSharedKeychain: false, keychainUtils: SFHFKeychainUtilsMock.self)

        try? subject.deleteItem(username: username, serviceName: service)

        XCTAssertEqual(getPassword(username: username, serviceName: service, accessGroup: sharedGroup), password)
        XCTAssertNil(getPassword(username: username, serviceName: service, accessGroup: nil))
    }

    func testAppGroupIsAPassthroughWhenSaving() {
        let group = "Test"
        let subject = Keychain(useSharedKeychain: true, keychainUtils: SFHFKeychainUtilsMock.self)

        try? subject.storeUsername(username, password: password, serviceName: service, accessGroup: group, updateExisting: true)

        let result = getPassword(username: username, serviceName: service, accessGroup: group)
        XCTAssertEqual(result, password)
    }

    func testAppGroupIsAPassthroughWhenReading() {
        let group = "Test"
        let subject = Keychain(useSharedKeychain: true, keychainUtils: SFHFKeychainUtilsMock.self)
        storeUsername(username, password: password, serviceName: service, accessGroup: group)

        let result = try? subject.getPasswordForUsername(username, serviceName: service, accessGroup: group)

        XCTAssertEqual(result, password)
    }

    func testAppGroupIsAPassthroughWhenDeleting() {
        let group = "Test"
        storeUsername(username, password: password, serviceName: service, accessGroup: group)
        let subject = Keychain(useSharedKeychain: false, keychainUtils: SFHFKeychainUtilsMock.self)

        try? subject.deleteItem(username: username, serviceName: service, accessGroup: group)

        XCTAssertNil(getPassword(username: username, serviceName: service, accessGroup: group))
    }

}

// MARK: - Helper functions

private extension KeychainTests {

    func getPassword(username: String, serviceName: String, accessGroup: String?) -> String? {
        let result = (try? SFHFKeychainUtilsMock.getPasswordForUsername(username, andServiceName: serviceName, accessGroup: accessGroup)) ?? ""
        return result.count > 0 ? result : nil
    }

    func storeUsername(_ username: String, password: String, serviceName: String, accessGroup: String?) {
        try? SFHFKeychainUtilsMock.storeUsername(username, andPassword: password, forServiceName: serviceName, accessGroup: accessGroup, updateExisting: true)
    }

}

// MARK: - SFHFKeychainUtilsMock

final private class SFHFKeychainUtilsMock: SFHFKeychainUtils {
    typealias MockKeychain = [String: [String: [String: String]]]

    static var keychain: MockKeychain = [:]

    class func configure(with keychain: MockKeychain) {
        self.keychain = keychain
    }

    override class func getPasswordForUsername(_ username: String!, andServiceName serviceName: String!, accessGroup: String!) throws -> String {
        let group = accessGroup ?? "default"
        if let value = keychain[group]?[serviceName]?[username] {
            return value
        }

        return ""
    }

    override class func storeUsername(_ username: String!, andPassword password: String!, forServiceName serviceName: String!, accessGroup: String!, updateExisting: Bool) throws {
        let group = accessGroup ?? "default"
        if keychain[group] == nil {
            keychain[group] = [:]
        }
        if keychain[group]?[serviceName] == nil {
            keychain[group]?[serviceName] = [:]
        }
        keychain[group]?[serviceName]?[username] = password
    }

    override class func deleteItem(forUsername username: String!, andServiceName serviceName: String!, accessGroup: String!) throws {
        let group = accessGroup ?? "default"
        keychain[group]?[serviceName]?.removeValue(forKey: username)
    }
}
