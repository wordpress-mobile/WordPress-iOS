@objcMembers
class KeychainUtils {

    static let shared = KeychainUtils()

    private let shouldUseSharedKeychain: () -> Bool
    private let keychainUtils: SFHFKeychainUtils.Type

    private var keychainGroup: String? {
        shouldUseSharedKeychain() ? WPAppKeychainAccessGroup : nil
    }

    init(shouldUseSharedKeychain: @escaping @autoclosure () -> Bool = FeatureFlag.sharedLogin.enabled,
         keychainUtils: SFHFKeychainUtils.Type = SFHFKeychainUtils.self) {
        self.shouldUseSharedKeychain = shouldUseSharedKeychain
        self.keychainUtils = keychainUtils
    }

    func storeUsername(_ username: String, password: String, serviceName: String, accessGroup: String? = nil, updateExisting: Bool) throws {
        try keychainUtils.storeUsername(
                username,
                andPassword: password,
                forServiceName: serviceName,
                accessGroup: accessGroup ?? keychainGroup,
                updateExisting: updateExisting
        )
    }

    func getPasswordForUsername(_ username: String, serviceName: String, accessGroup: String? = nil) throws -> String? {
        try keychainUtils.getPasswordForUsername(
                username,
                andServiceName: serviceName,
                accessGroup: accessGroup ?? keychainGroup
        )
    }

    func deleteItem(username: String, serviceName: String, accessGroup: String? = nil) throws {
        try keychainUtils.deleteItem(
                forUsername: username,
                andServiceName: serviceName,
                accessGroup: accessGroup ?? keychainGroup
        )
    }

}
