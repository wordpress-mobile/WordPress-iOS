import SFHFKeychainUtils

@available(
    *,
    deprecated,
    message:
        "Use AppKeychain for app-private data, or SharedKeychain for the cross-app migration contract. KeychainUtils operates on the default access group, which made every keychain item cross-app by accident."
)
@objcMembers
public class KeychainUtils: NSObject {

    private let keychainUtils: SFHFKeychainUtils.Type

    public init(keychainUtils: SFHFKeychainUtils.Type = SFHFKeychainUtils.self) {
        self.keychainUtils = keychainUtils
    }

    func copyKeychain(from sourceAccessGroup: String?,
                      to destinationAccessGroup: String?,
                      updateExisting: Bool = true) throws {
        let sourceItems = try keychainUtils.getAllPasswords(forAccessGroup: sourceAccessGroup)

        for item in sourceItems {
            guard let username = item["username"],
                  let password = item["password"],
                  let serviceName = item["serviceName"] else {
                continue
            }

            try keychainUtils.storeUsername(username, andPassword: password, forServiceName: serviceName, accessGroup: destinationAccessGroup, updateExisting: updateExisting)
        }
    }
}

@available(*, deprecated)
extension KeychainUtils: KeychainAccessible {
    // @nonobjc: the typed-throws contract is not representable in Objective-C.
    @nonobjc
    public func getPassword(for username: String, serviceName: String) throws(KeychainError) -> String {
        do {
            return try self.keychainUtils.getPasswordForUsername(username, andServiceName: serviceName)
        } catch {
            throw keychainError(from: error)
        }
    }

    // @nonobjc: the typed-throws contract is not representable in Objective-C.
    @nonobjc
    public func setPassword(for username: String, to newValue: String?, serviceName: String) throws(KeychainError) {
        do {
            if let newValue {
                try keychainUtils.storeUsername(username, andPassword: newValue, forServiceName: serviceName, updateExisting: true)
            } else {
                try keychainUtils.deleteItem(forUsername: username, andServiceName: serviceName)
            }
        } catch {
            throw keychainError(from: error)
        }
    }
}
