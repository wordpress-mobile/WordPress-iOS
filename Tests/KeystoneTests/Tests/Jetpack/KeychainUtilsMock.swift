import WordPressShared

final class KeychainUtilsMock: KeychainAccessible {
    var passwords: [String: [String: String]] = [:]
    var getPasswordError: KeychainError?
    var setPasswordError: KeychainError?

    func getPassword(for username: String, serviceName: String) throws(KeychainError) -> String {
        if let error = getPasswordError {
            throw error
        }
        guard let password = passwords[serviceName]?[username] else {
            // Match the real keychain: a missing item throws `.notFound`
            // instead of returning an empty string, so tests exercise the
            // same "already migrated" guards as production.
            throw KeychainError.notFound
        }
        return password
    }

    func setPassword(for username: String, to newValue: String?, serviceName: String) throws(KeychainError) {
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
