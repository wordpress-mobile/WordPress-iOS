import SFHFKeychainUtils

public protocol KeychainServiceProtocol {
    func password(for username: String) throws -> String
    func setPassword(_ password: String, for username: String) throws
    func deletePassword(for username: String) throws
}

public struct KeychainService: KeychainServiceProtocol {
    private let serviceName: String

    public init(serviceName: String) {
        self.serviceName = serviceName
    }

    public func password(for username: String) throws -> String {
        try SFHFKeychainUtils.getPasswordForUsername(username, andServiceName: serviceName, accessGroup: nil)
    }

    public func setPassword(_ password: String, for username: String) throws {
        try SFHFKeychainUtils.storeUsername(username, andPassword: password, forServiceName: serviceName, accessGroup: nil, updateExisting: true)
    }

    public func deletePassword(for username: String) throws {
        try SFHFKeychainUtils.deleteItem(forUsername: username, andServiceName: serviceName, accessGroup: nil)
    }
}
