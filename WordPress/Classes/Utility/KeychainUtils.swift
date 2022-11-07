@objcMembers
class KeychainUtils: NSObject {

    private let keychainUtils: SFHFKeychainUtils.Type

    init(keychainUtils: SFHFKeychainUtils.Type = SFHFKeychainUtils.self) {
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
