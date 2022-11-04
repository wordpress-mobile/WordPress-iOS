import XCTest
@testable import WordPress

class KeychainUtilsTests: XCTestCase {

    override func setUp() {
        super.setUp()

        SFHFKeychainUtilsMock.configure(with: [:])
    }

    func testCopyingPasswordsBetweenKeychains() {
        let service = "service"
        let username = "username"
        let password = "password"
        let sharedGroup = WPAppKeychainAccessGroup
        let subject = KeychainUtils(keychainUtils: SFHFKeychainUtilsMock.self)
        SFHFKeychainUtilsMock.configure(with: ["default": [service: [username: password]]])

        try? subject.copyKeychain(from: nil, to: sharedGroup, updateExisting: true)

        let sharedPassword = try? SFHFKeychainUtilsMock.getPasswordForUsername(username, andServiceName: service, accessGroup: sharedGroup)
        XCTAssertEqual(sharedPassword, password)
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

    override class func getAllPasswords(forAccessGroup accessGroup: String!) throws -> [[String: String]] {
        let group = accessGroup ?? "default"
        var passwords = [[String: String]]()
        guard let items = keychain[group] else {
            return passwords
        }

        for serviceName in items.keys {
            guard let serviceItems = items[serviceName] else {
                continue
            }

            for username in serviceItems.keys {
                guard let password = serviceItems[username] else {
                    continue
                }
                passwords.append(["username": username, "password": password, "serviceName": serviceName])
            }
        }

        return passwords
    }
}
