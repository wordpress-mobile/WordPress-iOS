import Foundation
import CoreData
import SFHFKeychainUtils
import CocoaLumberjackSwift

extension WPAccount {

    static func token(forUsername username: String, isJetpack: Bool) throws -> String {
        if isJetpack {
            Migration.shared.migrate(username: username)
        }

        do {
            return try SFHFKeychainUtils.getPasswordForUsername(
                username,
                andServiceName: WPAccount.authKeychainServiceName,
                accessGroup: nil
            )
        } catch {
            DDLogError("Error while retrieving WordPressComOAuthKeychainServiceName token: %\(error)")
            throw error
        }
    }

}

private class Migration {
    static let shared = Migration()

    private let lock = NSLock()
    private var migrated: Set<String> = []
    private let instance = SharedDataIssueSolver.instance()

    private init() {}

    func migrate(username: String) {
        lock.lock()
        defer { lock.unlock() }

        if migrated.contains(username) {
            return
        }

        instance.migrateAuthKey(for: username)
        migrated.insert(username)
    }
}
