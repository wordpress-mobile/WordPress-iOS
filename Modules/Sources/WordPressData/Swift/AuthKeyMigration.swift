import Foundation

public protocol AuthKeyMigrationProtocol {
    func migrateIfNeeded(username: String)
}

public struct AuthKeyMigration: AuthKeyMigrationProtocol {
    private static let lock = NSLock()
    private static var didMigrate = false

    public init() {}

    public func migrateIfNeeded(username: String) {
        let shouldMigrate = Self.lock.withLock {
            guard !Self.didMigrate else { return false }
            Self.didMigrate = true
            return true
        }
        guard shouldMigrate else { return }
        SharedDataIssueSolver().migrateAuthKey(for: username)
    }
}
