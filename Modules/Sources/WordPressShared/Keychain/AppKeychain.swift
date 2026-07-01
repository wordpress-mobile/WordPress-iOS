import BuildSettingsKit
import Foundation
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
            reportKeychainFailureIfNeeded(error, serviceName: serviceName, accessGroup: privateGroup)
            // A real failure (for example errSecInteractionNotAllowed while the
            // device is locked) must surface: the fallback is long-lived now,
            // so masking it as not-found would be permanent. Fall back only on
            // a genuine not-found of the private read, and only when a shared
            // group exists.
            guard !isRealKeychainFailure(error), let sharedGroup else { throw error }
            let value: String
            do {
                value = try keychainUtils.getPasswordForUsername(
                    username,
                    andServiceName: serviceName,
                    accessGroup: sharedGroup
                )
            } catch {
                reportKeychainFailureIfNeeded(error, serviceName: serviceName, accessGroup: sharedGroup)
                throw error
            }
            // Read-repair: migrate the item into the private group so future
            // reads stop depending on the shared-group fallback. Best-effort,
            // the read already succeeded; the next read retries the repair.
            do {
                try keychainUtils.storeUsername(
                    username,
                    andPassword: value,
                    forServiceName: serviceName,
                    accessGroup: privateGroup,
                    updateExisting: true
                )
            } catch {
                reportKeychainFailureIfNeeded(error, serviceName: serviceName, accessGroup: privateGroup)
            }
            return value
        }
    }

    public func setPassword(for username: String, to newValue: String?, serviceName: String) throws {
        guard let newValue else {
            // Delete from both groups, attempting the private-group delete even
            // when the shared-group delete fails. A logout must not leave a
            // credential in the shared group, where the fallback read (and
            // read-repair) could otherwise resurrect it. Delete the shared group
            // first: it is the only group the fallback reads, so an interruption
            // between the two deletes can never leave the resurrectable
            // "private empty, shared present" state. Surface the first real
            // failure only after both deletes have been attempted.
            var deleteFailure: Error?
            if let sharedGroup {
                do {
                    try deleteIgnoringNotFound(username, serviceName: serviceName, accessGroup: sharedGroup)
                } catch {
                    deleteFailure = error
                }
            }
            do {
                try deleteIgnoringNotFound(username, serviceName: serviceName, accessGroup: privateGroup)
            } catch {
                deleteFailure = deleteFailure ?? error
            }
            if let deleteFailure {
                throw deleteFailure
            }
            return
        }
        do {
            try keychainUtils.storeUsername(
                username,
                andPassword: newValue,
                forServiceName: serviceName,
                accessGroup: privateGroup,
                updateExisting: true
            )
        } catch {
            reportKeychainFailureIfNeeded(error, serviceName: serviceName, accessGroup: privateGroup)
            throw error
        }
    }

    private func deleteIgnoringNotFound(_ username: String, serviceName: String, accessGroup: String) throws {
        do {
            try keychainUtils.deleteItem(
                forUsername: username,
                andServiceName: serviceName,
                accessGroup: accessGroup
            )
        } catch {
            reportKeychainFailureIfNeeded(error, serviceName: serviceName, accessGroup: accessGroup)
            // Deleting a missing item is expected: the item usually exists
            // in only one of the two groups. Anything else (for example
            // errSecInteractionNotAllowed while the device is locked) must
            // surface, or a logout could silently leave a credential behind.
            guard !isRealKeychainFailure(error) else { throw error }
        }
    }
}
