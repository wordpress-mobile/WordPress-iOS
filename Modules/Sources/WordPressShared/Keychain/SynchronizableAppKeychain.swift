import Foundation
import Security

/// Keychain access for credentials that should follow the user to a new device, such as
/// application passwords.
///
/// Items are saved with `kSecAttrSynchronizable`, so iCloud Keychain copies them to the user's
/// other devices. When iCloud Keychain is off, they stay on this device like any other item.
/// Device backups can't be relied on for this: an iCloud backup only restores the keychain to the
/// device it was made on.
///
/// Earlier app versions saved these items on this device only: in the app's private access group,
/// or before that, in the group shared with the other app. When the synced store has no item, a
/// read falls back to `AppKeychain` and moves the item into the synced store, so it starts syncing
/// without the user signing in again.
///
/// Moving an item or writing a new value removes this app's private copy, but leaves the shared
/// group alone: the other app may still read its copy from there. Deleting an item removes every
/// copy, the same as `AppKeychain`.
///
/// Deleting an item deletes it on every device that syncs it. A device that still has a copy in
/// the shared group brings that copy back on its next read; if the site rejects it, the app asks
/// the user to sign in again.
public final class SynchronizableAppKeychain: KeychainAccessible {
    private let store: SynchronizableKeychainStore
    private let deviceOnly: AppKeychain

    init(store: SynchronizableKeychainStore, deviceOnly: AppKeychain) {
        self.store = store
        self.deviceOnly = deviceOnly
    }

    public func getPassword(for username: String, serviceName: String) throws -> String {
        // A real failure (for example errSecInteractionNotAllowed while the device is locked)
        // surfaces instead of falling back, same as `AppKeychain`.
        if let password = try store.password(for: username, serviceName: serviceName) {
            return password
        }

        let password = try deviceOnly.getPassword(for: username, serviceName: serviceName)
        var result = password
        do {
            // Add only: a value saved in the meantime, by another write or by iCloud Keychain, is newer.
            if try !store.addPassword(password, for: username, serviceName: serviceName) {
                result = try store.password(for: username, serviceName: serviceName) ?? password
            }
            try deviceOnly.deletePrivateCopy(for: username, serviceName: serviceName)
        } catch {
            // Best-effort: the read already succeeded, and the next read tries again. Failures
            // are reported where they happen.
        }
        return result
    }

    public func setPassword(for username: String, to newValue: String?, serviceName: String) throws {
        guard let newValue else {
            // Attempt both deletes even when the first one fails. Surface the first failure after
            // both attempts.
            var deleteFailure: Error?
            do {
                try store.deletePassword(for: username, serviceName: serviceName)
            } catch {
                deleteFailure = error
            }
            do {
                try deviceOnly.setPassword(for: username, to: nil, serviceName: serviceName)
            } catch {
                deleteFailure = deleteFailure ?? error
            }
            if let deleteFailure {
                throw deleteFailure
            }
            return
        }

        try store.setPassword(newValue, for: username, serviceName: serviceName)
        // Remove this app's older private copy, which the fallback read would otherwise bring back
        // once the synced item is deleted (possibly on another device). Best-effort: the write
        // already succeeded.
        try? deviceOnly.deletePrivateCopy(for: username, serviceName: serviceName)
    }
}

/// The synced half of `SynchronizableAppKeychain`, behind a protocol so tests can replace it.
protocol SynchronizableKeychainStore {
    /// Returns `nil` when there is no item.
    func password(for username: String, serviceName: String) throws -> String?
    /// Adds or updates the item.
    func setPassword(_ password: String, for username: String, serviceName: String) throws
    /// Adds the item only if there is none. Returns `false` when an item already exists.
    func addPassword(_ password: String, for username: String, serviceName: String) throws -> Bool
    /// Succeeds when there is no item.
    func deletePassword(for username: String, serviceName: String) throws
}

/// Generic-password items with `kSecAttrSynchronizable` set, in the app's private access group.
struct SecItemSynchronizableKeychainStore: SynchronizableKeychainStore {
    let accessGroup: String

    func password(for username: String, serviceName: String) throws -> String? {
        var query = baseQuery(username: username, serviceName: serviceName)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound {
            return nil
        }
        try check(status, serviceName: serviceName)

        guard let data = result as? Data, let password = String(data: data, encoding: .utf8) else {
            throw failure(errSecDecode, serviceName: serviceName)
        }
        return password
    }

    func setPassword(_ password: String, for username: String, serviceName: String) throws {
        let query = baseQuery(username: username, serviceName: serviceName)
        let attributes = self.attributes(for: password)

        var status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if status == errSecItemNotFound {
            status = SecItemAdd(query.merging(attributes) { $1 } as CFDictionary, nil)
            // Another write added the item between the two calls.
            if status == errSecDuplicateItem {
                status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
            }
        }
        try check(status, serviceName: serviceName)
    }

    func addPassword(_ password: String, for username: String, serviceName: String) throws -> Bool {
        let query = baseQuery(username: username, serviceName: serviceName)
            .merging(self.attributes(for: password)) { $1 }
        let status = SecItemAdd(query as CFDictionary, nil)
        if status == errSecDuplicateItem {
            return false
        }
        try check(status, serviceName: serviceName)
        return true
    }

    func deletePassword(for username: String, serviceName: String) throws {
        let status = SecItemDelete(baseQuery(username: username, serviceName: serviceName) as CFDictionary)
        if status == errSecItemNotFound {
            return
        }
        try check(status, serviceName: serviceName)
    }

    private func attributes(for password: String) -> [String: Any] {
        [
            kSecValueData as String: Data(password.utf8),
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
    }

    private func baseQuery(username: String, serviceName: String) -> [String: Any] {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: username,
            kSecAttrSynchronizable as String: true
        ]
        // Same as `SFHFKeychainUtils`, which `AppKeychain` uses: on the simulator, items go to the
        // default access group, which is the first one in the entitlements.
        #if !targetEnvironment(simulator)
        query[kSecAttrAccessGroup as String] = accessGroup
        #endif
        return query
    }

    private func check(_ status: OSStatus, serviceName: String) throws {
        guard status != errSecSuccess else {
            return
        }
        throw failure(status, serviceName: serviceName)
    }

    private func failure(_ status: OSStatus, serviceName: String) -> Error {
        let error = NSError(domain: NSOSStatusErrorDomain, code: Int(status))
        reportKeychainFailureIfNeeded(error, serviceName: serviceName, accessGroup: accessGroup)
        return error
    }
}
