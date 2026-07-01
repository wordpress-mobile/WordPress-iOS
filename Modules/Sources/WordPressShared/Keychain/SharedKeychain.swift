import BuildSettingsKit
import Foundation
import SFHFKeychainUtils

/// Keychain access scoped to the legacy cross-app shared access group
/// ("3TMU3BH3NK.org.wordpress").
///
/// The ONLY permitted users are the WordPress-to-Jetpack migration contract:
///   1. DataMigrator.exportData          (WordPress: publish the WP.com token)
///   2. DataMigrator.deleteExportedData  (WordPress: remove it on logout)
///   3. SharedDataIssueSolver.migrateAuthKey (Jetpack: read the token)
///
/// Anything else belongs in `AppKeychain`. A new SharedKeychain call site
/// means a new cross-app data flow; treat it as a design change.
public final class SharedKeychain: KeychainAccessible {
    private let group: String
    private let keychainUtils: SFHFKeychainUtils.Type

    /// Fails where the app has no shared-group entitlement (Reader).
    public convenience init?() {
        self.init(group: BuildSettings.current.sharedKeychainAccessGroup)
    }

    init?(group: String?, keychainUtils: SFHFKeychainUtils.Type = SFHFKeychainUtils.self) {
        guard let group else { return nil }
        self.group = group
        self.keychainUtils = keychainUtils
    }

    public func getPassword(for username: String, serviceName: String) throws -> String {
        do {
            return try keychainUtils.getPasswordForUsername(
                username,
                andServiceName: serviceName,
                accessGroup: group
            )
        } catch {
            reportKeychainFailureIfNeeded(error, serviceName: serviceName, accessGroup: group)
            throw error
        }
    }

    public func setPassword(for username: String, to newValue: String?, serviceName: String) throws {
        if let newValue {
            do {
                try keychainUtils.storeUsername(
                    username,
                    andPassword: newValue,
                    forServiceName: serviceName,
                    accessGroup: group,
                    updateExisting: true
                )
            } catch {
                reportKeychainFailureIfNeeded(error, serviceName: serviceName, accessGroup: group)
                throw error
            }
        } else {
            do {
                try keychainUtils.deleteItem(
                    forUsername: username,
                    andServiceName: serviceName,
                    accessGroup: group
                )
            } catch {
                reportKeychainFailureIfNeeded(error, serviceName: serviceName, accessGroup: group)
                // Deleting an already-absent item is success: the migration
                // cleanup path removes a token that may legitimately be gone.
                // Real failures must surface, same as AppKeychain.
                guard !isRealKeychainFailure(error) else { throw error }
            }
        }
    }
}
