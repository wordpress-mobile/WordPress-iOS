import WordPressShared

final class MockKeychainService: KeychainAccessible {
    var storage: [String: String] = [:]
    var shouldThrow = false
    var passwordCallCount = 0
    var setPasswordCallCount = 0
    var deletedUsernames: [String] = []
    var receivedServiceNames: [String] = []

    func getPassword(for username: String, serviceName: String) throws(KeychainError) -> String {
        passwordCallCount += 1
        receivedServiceNames.append(serviceName)
        if shouldThrow { throw KeychainError.failure(errSecInteractionNotAllowed) }
        guard let password = storage[username] else {
            throw KeychainError.notFound
        }
        return password
    }

    func setPassword(for username: String, to newValue: String?, serviceName: String) throws(KeychainError) {
        setPasswordCallCount += 1
        receivedServiceNames.append(serviceName)
        if shouldThrow { throw KeychainError.failure(errSecInteractionNotAllowed) }
        if let newValue {
            storage[username] = newValue
        } else {
            deletedUsernames.append(username)
            storage[username] = nil
        }
    }
}
