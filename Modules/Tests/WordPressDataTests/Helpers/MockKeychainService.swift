import WordPressShared

final class MockKeychainService: KeychainAccessible {
    var storage: [String: String] = [:]
    var shouldThrow = false
    var passwordCallCount = 0
    var setPasswordCallCount = 0
    var deletedUsernames: [String] = []
    var receivedServiceNames: [String] = []

    func getPassword(for username: String, serviceName: String) throws -> String {
        passwordCallCount += 1
        receivedServiceNames.append(serviceName)
        if shouldThrow { throw MockKeychainError.mockError }
        guard let password = storage[username] else {
            throw MockKeychainError.notFound
        }
        return password
    }

    func setPassword(for username: String, to newValue: String?, serviceName: String) throws {
        setPasswordCallCount += 1
        receivedServiceNames.append(serviceName)
        if shouldThrow { throw MockKeychainError.mockError }
        if let newValue {
            storage[username] = newValue
        } else {
            deletedUsernames.append(username)
            storage[username] = nil
        }
    }
}

enum MockKeychainError: Error {
    case notFound
    case mockError
}
