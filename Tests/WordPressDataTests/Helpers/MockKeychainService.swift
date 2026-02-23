import WordPressData

final class MockKeychainService: KeychainServiceProtocol {
    var storage: [String: String] = [:]
    var shouldThrow = false
    var passwordCallCount = 0
    var setPasswordCallCount = 0
    var deletedUsernames: [String] = []

    func password(for username: String) throws -> String {
        passwordCallCount += 1
        if shouldThrow { throw MockKeychainError.mockError }
        guard let password = storage[username] else {
            throw MockKeychainError.notFound
        }
        return password
    }

    func setPassword(_ password: String, for username: String) throws {
        setPasswordCallCount += 1
        if shouldThrow { throw MockKeychainError.mockError }
        storage[username] = password
    }

    func deletePassword(for username: String) throws {
        deletedUsernames.append(username)
        if shouldThrow { throw MockKeychainError.mockError }
        storage[username] = nil
    }
}

enum MockKeychainError: Error {
    case notFound
    case mockError
}
