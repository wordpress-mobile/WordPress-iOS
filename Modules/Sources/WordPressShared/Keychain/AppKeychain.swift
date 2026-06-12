import BuildSettingsKit
import Foundation
import Security
import SFHFKeychainUtils

/// Keychain access scoped to this app family's private access group (the
/// app and its extensions, e.g. "3TMU3BH3NK.org.wordpress.jetpack").
///
/// Routing rules:
///   - reads:   private group first, then a read-only fallback to the legacy
///              shared group (transition only; removed once pre-change app
///              versions are negligible)
///   - writes:  private group, always
///   - deletes: both groups, so a logout cannot resurrect a credential
///              through the fallback read
///
/// Use `SharedKeychain` instead for the WordPress-to-Jetpack migration
/// contract, the only data deliberately shared across apps.
public final class AppKeychain: KeychainAccessible {
    private let privateGroup: String
    private let sharedGroup: String?
    private let keychainUtils: SFHFKeychainUtils.Type

    public convenience init() {
        let settings = BuildSettings.current
        self.init(
            privateGroup: settings.appKeychainAccessGroup,
            sharedGroup: settings.sharedKeychainAccessGroup
        )
    }

    init(
        privateGroup: String,
        sharedGroup: String?,
        keychainUtils: SFHFKeychainUtils.Type = SFHFKeychainUtils.self
    ) {
        self.privateGroup = privateGroup
        self.sharedGroup = sharedGroup
        self.keychainUtils = keychainUtils
    }

    public func getPassword(for username: String, serviceName: String) throws -> String {
        do {
            return try keychainUtils.getPasswordForUsername(
                username,
                andServiceName: serviceName,
                accessGroup: privateGroup
            )
        } catch {
            // The item may predate the one-time copy into the private group,
            // including in extensions that wake before the host app copied.
            // SFHFKeychainUtils cannot distinguish not-found from other
            // failures in Swift, so any error falls through; a missing
            // shared-group entitlement also lands here and is rethrown.
            guard let sharedGroup else { throw error }
            return try keychainUtils.getPasswordForUsername(
                username,
                andServiceName: serviceName,
                accessGroup: sharedGroup
            )
        }
    }

    public func setPassword(for username: String, to newValue: String?, serviceName: String) throws {
        guard let newValue else {
            try deleteIgnoringNotFound(username, serviceName: serviceName, accessGroup: privateGroup)
            if let sharedGroup {
                try deleteIgnoringNotFound(username, serviceName: serviceName, accessGroup: sharedGroup)
            }
            return
        }
        try keychainUtils.storeUsername(
            username,
            andPassword: newValue,
            forServiceName: serviceName,
            accessGroup: privateGroup,
            updateExisting: true
        )
    }

    private func deleteIgnoringNotFound(_ username: String, serviceName: String, accessGroup: String) throws {
        do {
            try keychainUtils.deleteItem(
                forUsername: username,
                andServiceName: serviceName,
                accessGroup: accessGroup
            )
        } catch {
            // Deleting a missing item is expected: the item usually exists
            // in only one of the two groups. Anything else (for example
            // errSecInteractionNotAllowed while the device is locked) must
            // surface, or a logout could silently leave a credential behind.
            guard (error as NSError).code == Int(errSecItemNotFound) else { throw error }
        }
    }
}
