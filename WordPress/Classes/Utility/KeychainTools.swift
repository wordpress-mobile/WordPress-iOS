import Foundation
import Security
import CocoaLumberjack

private let keychainDebugWipeArgument = "WipeKeychainItem"

final class KeychainTools: NSObject {
    /// Searches the launch arguments for a WipeKeychainItem and removes the
    /// matching keychain items.
    ///
    /// To simulate keychain issues, you can pass the WipeKeychainItem argument
    /// at launch. Valid options for this argument are:
    ///
    ///   * "*" or "all": removes every keychain entry
    ///   * "wordpress.com": removes any WordPress.com OAuth2 token
    ///   * hostname: removes a self hosted password
    ///
    /// - Note:
    ///     The self hosted case uses a hostname for convenience, but the
    ///     password is stored using the XML-RPC as a key. If the xmlrpc.php
    ///     endpoint is not in the root directory this won't work.
    ///
    /// - Attention: This is only enabled in debug builds.
    ///
    @objc static func processKeychainDebugArguments() {
        guard BuildConfiguration.current == .localDeveloper else {
            return
        }

        guard let item = UserDefaults.standard.value(forKey: keychainDebugWipeArgument) as? String else {
            return
        }

        DDLogWarn("🔑 Attempting to remove keychain entry for \(item)")
        if let service = serviceForItem(item) {
            removeKeychainItem(forService: service)
        } else {
            removeAllKeychainItems()
        }
    }

    static fileprivate func serviceForItem(_ item: String) -> String? {
        switch item {
        case "wordpress.com":
            return "public-api.wordpress.com"
        case "*", "all":
            return nil
        default:
            return "http://\(item)/xmlrpc.php"
        }
    }

    static fileprivate func removeKeychainItem(forService service: String) {
        let query: [NSString: AnyObject] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service as AnyObject
        ]
        let status = SecItemDelete(query as CFDictionary)
        switch status {
        case errSecSuccess:
            DDLogWarn("🔑 Removed keychain entry for service \(service)")
        case errSecItemNotFound:
            DDLogWarn("🔑 Keychain entry not found for service \(service)")
        default:
            DDLogWarn("🔑 Error removing keychain entry for service \(service): \(status)")
        }
    }

    static fileprivate func removeAllKeychainItems() {
        let query: [NSString: AnyObject] = [
            kSecClass: kSecClassGenericPassword
        ]
        let status = SecItemDelete(query as CFDictionary)
        switch status {
        case errSecSuccess:
            DDLogWarn("🔑 Removed all keychain entries")
        default:
            DDLogWarn("🔑 Error removing all keychain entries: \(status)")
        }
    }
}
