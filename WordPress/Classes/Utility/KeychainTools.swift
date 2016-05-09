import Foundation
import Security

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
    static func processKeychainDebugArguments() {
        guard build(.Debug) else {
            return
        }

        guard let item = NSUserDefaults.standardUserDefaults().valueForKey(keychainDebugWipeArgument) as? String else {
            return
        }

        DDLogSwift.logWarn("🔑 Attempting to remove keychain entry for \(item)")
        if let service = serviceForItem(item) {
            removeKeychainItem(forService: service)
        } else {
            removeAllKeychainItems()
        }
    }

    static private func serviceForItem(item: String) -> String? {
        switch item {
        case "wordpress.com":
            return "public-api.wordpress.com"
        case "*", "all":
            return nil
        default:
            return "http://\(item)/xmlrpc.php"
        }
    }

    static private func removeKeychainItem(forService service: String) {
        let query: [NSString: AnyObject] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service
        ]
        let status = SecItemDelete(query)
        switch status {
        case errSecSuccess:
            DDLogSwift.logWarn("🔑 Removed keychain entry for service \(service)")
        case errSecItemNotFound:
            DDLogSwift.logWarn("🔑 Keychain entry not found for service \(service)")
        default:
            DDLogSwift.logWarn("🔑 Error removing keychain entry for service \(service): \(status)")
        }
    }

    static private func removeAllKeychainItems() {
        let query: [NSString: AnyObject] = [
            kSecClass: kSecClassGenericPassword
        ]
        let status = SecItemDelete(query)
        switch status {
        case errSecSuccess:
            DDLogSwift.logWarn("🔑 Removed all keychain entries")
        default:
            DDLogSwift.logWarn("🔑 Error removing all keychain entries: \(status)")
        }
    }
}
