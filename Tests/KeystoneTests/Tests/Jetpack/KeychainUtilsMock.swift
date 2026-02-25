import WordPressShared

final class KeychainUtilsMock: KeychainAccessible {
    var passwords: [String: [String: String]] = [:]
    var getPasswordError: Error?
    var setPasswordError: Error?

    func getPassword(for username: String, serviceName: String) throws -> String {
        if let error = getPasswordError {
            throw error
        }
        return passwords[serviceName]?[username] ?? ""
    }

    func setPassword(for username: String, to newValue: String?, serviceName: String) throws {
        if let error = setPasswordError {
            throw error
        }
        if let newValue {
            passwords[serviceName, default: [:]][username] = newValue
        } else {
            passwords[serviceName]?[username] = nil
        }
    }
}
