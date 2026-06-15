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

    /// Requires that every keychain access group this app declares
    /// (`WPAppKeychainAccessGroup`, plus `WPSharedKeychainAccessGroup` when
    /// present) is actually granted by the app's `keychain-access-groups`
    /// entitlement. Call once, early, at launch.
    ///
    /// A group declared in `Info.plist`/`BuildSettings` but missing from the
    /// entitlement makes every keychain operation against it fail with
    /// `errSecMissingEntitlement`: the app can neither persist nor read
    /// credentials (login cannot complete) and a logout can leak the token into
    /// the cross-app group. That is a blatant build misconfiguration, so this
    /// crashes hard — in release/beta too, not just debug. A TestFlight build
    /// and the App Store build share the same entitlements, so the crash
    /// surfaces on the first launch of any affected build and blocks it from
    /// ever being promoted to production.
    ///
    /// Crashes only on the precise `errSecMissingEntitlement` signal (not on
    /// lock-state or not-found errors), so a correctly configured build cannot
    /// be falsely bricked. No-op on the Simulator, which does not enforce
    /// access-group entitlements.
    public static func requireDeclaredAccessGroupsAreEntitled() {
        #if !targetEnvironment(simulator)
        let settings = BuildSettings.current
        var groups = [settings.appKeychainAccessGroup]
        if let sharedGroup = settings.sharedKeychainAccessGroup {
            groups.append(sharedGroup)
        }
        for group in groups where !isAccessGroupEntitled(group) {
            fatalError(
                """
                Keychain access group '\(group)' is declared (Info.plist / BuildSettings) but is not \
                granted by the app's keychain-access-groups entitlement. Every keychain operation against \
                it fails with errSecMissingEntitlement — login cannot persist and logout can leak tokens \
                into the cross-app group. Fix the target's .entitlements before release.
                """
            )
        }
        #endif
    }

    /// Whether the signed entitlements grant access to `accessGroup`. Issues a
    /// benign scoped query: the keychain rejects an un-entitled group with
    /// `errSecMissingEntitlement`. Any other status (a hit, `errSecItemNotFound`
    /// on an empty group, or a transient lock-state error) means the
    /// access-group filter was accepted, i.e. the group is entitled.
    private static func isAccessGroupEntitled(_ accessGroup: String) -> Bool {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccessGroup: accessGroup,
            kSecMatchLimit: kSecMatchLimitOne
        ]
        return SecItemCopyMatching(query as CFDictionary, nil) != errSecMissingEntitlement
    }

    public func getPassword(for username: String, serviceName: String) throws -> String {
        do {
            return try keychainUtils.getPasswordForUsername(
                username,
                andServiceName: serviceName,
                accessGroup: privateGroup
            )
        } catch {
            // A real failure (for example errSecInteractionNotAllowed while the
            // device is locked) must surface: the fallback is long-lived now,
            // so masking it as not-found would be permanent. Fall back only on
            // a genuine not-found of the private read, and only when a shared
            // group exists.
            guard !isRealKeychainFailure(error), let sharedGroup else { throw error }
            let value = try keychainUtils.getPasswordForUsername(
                username,
                andServiceName: serviceName,
                accessGroup: sharedGroup
            )
            // Read-repair: migrate the item into the private group so future
            // reads stop depending on the shared-group fallback. Best-effort,
            // the read already succeeded; the next read retries the repair.
            try? keychainUtils.storeUsername(
                username,
                andPassword: value,
                forServiceName: serviceName,
                accessGroup: privateGroup,
                updateExisting: true
            )
            return value
        }
    }

    public func setPassword(for username: String, to newValue: String?, serviceName: String) throws {
        guard let newValue else {
            // A logout must never end with the credential present in the shared
            // group but absent from the private group: the fallback read would
            // resurrect it (and read-repair it back into the private group).
            // Delete the shared group first and let a real failure propagate
            // before the private copy is touched. Deleting shared-first also
            // keeps an interruption between the two deletes safe. Worst case on a
            // real failure is that both copies remain — logout did not complete
            // and the caller retries — never the resurrectable "private empty,
            // shared present" state.
            if let sharedGroup {
                try deleteIgnoringNotFound(username, serviceName: serviceName, accessGroup: sharedGroup)
            }
            try deleteIgnoringNotFound(username, serviceName: serviceName, accessGroup: privateGroup)
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
            guard !isRealKeychainFailure(error) else { throw error }
        }
    }
}
