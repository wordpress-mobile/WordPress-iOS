import SFHFKeychainUtils

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

    func password(for username: String, serviceName: String, accessGroup: String? = nil) throws -> String? {
        return try keychainUtils.getPasswordForUsername(username, andServiceName: serviceName, accessGroup: accessGroup)
    }

    // FIXME: Might become internal once all consumers interface with this via `KeychainAccessible`
    public func store(username: String, password: String, serviceName: String, accessGroup: String? = nil, updateExisting: Bool) throws {
        return try keychainUtils.storeUsername(username,
                                               andPassword: password,
                                               forServiceName: serviceName,
                                               accessGroup: accessGroup,
                                               updateExisting: updateExisting)
    }
}

extension KeychainUtils: KeychainAccessible {
    public func getPassword(for username: String, serviceName: String) throws -> String {
        try self.keychainUtils.getPasswordForUsername(username, andServiceName: serviceName)
    }

    public func setPassword(for username: String, to newValue: String?, serviceName: String) throws {
        if let newValue {
            try keychainUtils.storeUsername(username, andPassword: newValue, forServiceName: serviceName, updateExisting: true)
        } else {
            try keychainUtils.deleteItem(forUsername: username, andServiceName: serviceName)
        }
    }
}
