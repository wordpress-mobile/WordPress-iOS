import BuildSettingsKit
import Foundation
import Security
import SFHFKeychainUtils

/// Minimal key-value needs of the keychain group migration.
/// UserDefaults satisfies it natively.
public protocol KeychainMigrationFlagStore: AnyObject {
    func bool(forKey defaultName: String) -> Bool
    func integer(forKey defaultName: String) -> Int
    func set(_ value: Bool, forKey defaultName: String)
    func set(_ value: Int, forKey defaultName: String)
}

extension UserDefaults: KeychainMigrationFlagStore {}

/// One-time blanket copy of the legacy shared-group keychain items into this
/// app's private group, plus a coordinated sweep that deletes the shared
/// group's leftovers once every installed app has copied.
///
/// Runs at launch in the WordPress and Jetpack apps. Reader never runs this
/// (no shared group; the initializer fails).
/// The protocol assumes exactly two group members, WordPress and Jetpack.
public final class KeychainGroupMigrator {

    /// Bump to re-run the copy in a future release.
    public static let migrationVersion = 1

    static let localMarkerKey = "keychain_access_group_migration_version"
    static let copyDoneKeyPrefix = "keychain_private_copy_done."
    /// Deliberately unversioned, unlike the copy flags: a `migrationVersion`
    /// bump re-runs the copy but not the sweep. If a future bump needs a
    /// re-sweep (e.g. items landed in the shared group after the first
    /// sweep), version this key at that point.
    static let sweepDoneKey = "keychain_shared_sweep_done"

    /// The migration handoff item is owned by the export/import flow
    /// (DataMigrator), not by this sweep. Deleting it here would break a
    /// pending export whose Jetpack import has not run yet.
    static let preservedServices: Set<String> = [AuthTokenServiceNames.wordPress]

    private let brand: AppBrand
    private let privateGroup: String
    private let sharedGroup: String
    private let localDefaults: KeychainMigrationFlagStore
    private let sharedDefaults: KeychainMigrationFlagStore
    private let keychainUtils: SFHFKeychainUtils.Type
    private let excludedFromCopy: Set<String>

    public init?(
        brand: AppBrand,
        privateGroup: String,
        sharedGroup: String?,
        localDefaults: KeychainMigrationFlagStore,
        sharedDefaults: KeychainMigrationFlagStore?,
        keychainUtils: SFHFKeychainUtils.Type = SFHFKeychainUtils.self
    ) {
        guard brand == .wordpress || brand == .jetpack,
            let sharedGroup,
            let sharedDefaults
        else {
            return nil
        }
        self.brand = brand
        self.privateGroup = privateGroup
        self.sharedGroup = sharedGroup
        self.localDefaults = localDefaults
        self.sharedDefaults = sharedDefaults
        self.keychainUtils = keychainUtils
        // Never import the counterpart's WP.com token into this app's
        // private group: it would outlive the counterpart's logout there,
        // unreachable by either app's delete path.
        self.excludedFromCopy =
            brand == .wordpress
            ? [AuthTokenServiceNames.jetpack]
            : [AuthTokenServiceNames.wordPress]
    }

    public func migrateIfNeeded() {
        #if targetEnvironment(simulator)
        // The simulator keychain has no access groups: getAllPasswords would
        // return every item regardless of group and the sweep would delete
        // the app's only copies. There is nothing to migrate there.
        return
        #else
        copyIfNeeded()
        sweepIfSafe()
        #endif
    }

    func copyIfNeeded() {
        guard localDefaults.integer(forKey: Self.localMarkerKey) < Self.migrationVersion else {
            return
        }
        // Snapshot first, then store. getAllPasswords fails while the device
        // is locked before first unlock (errSecInteractionNotAllowed); the
        // marker stays unset and the copy retries on the next launch.
        // updateExisting makes retries idempotent.
        let items: [[String: String]]
        do {
            items = try keychainUtils.getAllPasswords(forAccessGroup: sharedGroup)
        } catch {
            // An empty group surfaces as errSecItemNotFound: that is a
            // successful zero-item copy (fresh installs, or a re-run after
            // the sweep emptied the group). Anything else (for example
            // errSecInteractionNotAllowed before first unlock) retries on
            // the next launch.
            guard (error as NSError).code == Int(errSecItemNotFound) else { return }
            items = []
        }
        for item in items {
            guard let username = item["username"],
                let password = item["password"],
                let serviceName = item["serviceName"],
                excludedFromCopy.contains(serviceName) == false
            else {
                continue
            }
            // Insert-only: never overwrite an item that already exists in
            // the private group. A retried copy (after a partial failure)
            // must not revert credentials the app wrote after the update;
            // the shared-group snapshot is older by definition.
            if let _ = try? keychainUtils.getPasswordForUsername(
                username,
                andServiceName: serviceName,
                accessGroup: privateGroup
            ) {
                continue
            }
            do {
                try keychainUtils.storeUsername(
                    username,
                    andPassword: password,
                    forServiceName: serviceName,
                    accessGroup: privateGroup,
                    updateExisting: true
                )
            } catch {
                // Partial copy: leave the marker unset and retry next launch.
                return
            }
        }
        localDefaults.set(Self.migrationVersion, forKey: Self.localMarkerKey)
        sharedDefaults.set(Self.migrationVersion, forKey: Self.copyDoneKeyPrefix + brand.rawValue)
    }

    /// Deletes the shared group's contents once it is safe: both apps have
    /// copied at the current migration version. There is deliberately no
    /// "counterpart not installed" shortcut: keychain items survive app
    /// uninstalls and iCloud restores re-download apps lazily, and scheme
    /// probing is unreliable outside production builds, so absence cannot
    /// be distinguished from "not yet copied". If the counterpart is never
    /// installed or never updates, the leftovers simply remain for a later
    /// cleanup.
    ///
    /// Safety property: a pre-change app version never sets its copy flag,
    /// so an installed old version always blocks the sweep.
    func sweepIfSafe() {
        guard sharedDefaults.bool(forKey: Self.sweepDoneKey) == false,
            sharedDefaults.integer(forKey: Self.copyDoneKeyPrefix + brand.rawValue) >= Self.migrationVersion
        else {
            return
        }
        let counterpart: AppBrand = brand == .wordpress ? .jetpack : .wordpress
        guard sharedDefaults.integer(forKey: Self.copyDoneKeyPrefix + counterpart.rawValue) >= Self.migrationVersion
        else {
            return
        }
        let items: [[String: String]]
        do {
            items = try keychainUtils.getAllPasswords(forAccessGroup: sharedGroup)
        } catch {
            // Empty group: nothing left to sweep, mark it done. Any other
            // error retries on the next launch.
            guard (error as NSError).code == Int(errSecItemNotFound) else { return }
            items = []
        }
        var allDeletesSucceeded = true
        for item in items {
            guard let username = item["username"],
                let serviceName = item["serviceName"],
                Self.preservedServices.contains(serviceName) == false
            else {
                continue
            }
            do {
                try keychainUtils.deleteItem(
                    forUsername: username,
                    andServiceName: serviceName,
                    accessGroup: sharedGroup
                )
            } catch {
                if (error as NSError).code != Int(errSecItemNotFound) {
                    allDeletesSucceeded = false
                }
            }
        }
        // A failed delete means leftovers remain; keep the done flag unset
        // so the next launch retries instead of abandoning them silently.
        guard allDeletesSucceeded else { return }
        sharedDefaults.set(true, forKey: Self.sweepDoneKey)
    }
}
