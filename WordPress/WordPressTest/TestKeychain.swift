import Foundation
@testable import WordPress

class TestKeychain: KeychainAccessible {
    private var keychain = [String: KeychainItem]()

    struct KeychainItem {
        let username: String
        let password: String
    }

    enum TestKeychainErrors: Error {
        case keychainItemNotFound
    }

    func getPassword(for username: String, serviceName: String) throws -> String {
        guard let keychainItem = keychain[serviceName], keychainItem.username == username else {
            throw TestKeychainErrors.keychainItemNotFound
        }

        return keychainItem.password
    }

    func setPassword(for username: String, to newValue: String?, serviceName: String) throws {
        if let newValue {
            keychain[serviceName] = KeychainItem(username: username, password: newValue)
        } else {
            keychain[serviceName] = nil
        }
    }
}
