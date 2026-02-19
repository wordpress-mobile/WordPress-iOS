import BuildSettingsKit
import SFHFKeychainUtils
import WordPressShared

extension WPAccount {

    private static var authKeychainServiceName: String {
        BuildSettings.current.authKeychainServiceName
    }

    /// The OAuth2 auth token for WordPress.com accounts
    @objc public var authToken: String? {
        get { _getAuthToken() }
        set { _setAuthToken(newValue) }
    }

    private func _getAuthToken() -> String? {
        if let cachedToken {
            return cachedToken
        }
        let token = try? Self.token(forUsername: username)
        cachedToken = token
        return token
    }

    private func _setAuthToken(_ authToken: String?) {
        cachedToken = nil

        // Make sure to release any RestAPI alloc'ed, since it might have an invalid token
        _private_wordPressComRestApi = nil

        do {
            if let authToken {
                try SFHFKeychainUtils.storeUsername(
                    username,
                    andPassword: authToken,
                    forServiceName: Self.authKeychainServiceName,
                    accessGroup: nil,
                    updateExisting: true
                )
            } else {
                try SFHFKeychainUtils.deleteItem(
                    forUsername: username,
                    andServiceName: Self.authKeychainServiceName,
                    accessGroup: nil
                )
            }
        } catch {
            WPLogError("Error while updating or deleting WordPressComOAuthKeychainServiceName token: %@", error.localizedDescription)
        }
    }

    public static func token(
        forUsername username: String,
        isJetpack: Bool = BuildSettings.current.brand == .jetpack
    ) throws -> String {
        if isJetpack {
            AuthKeyMigration.migrateIfNeeded(username: username)
        }
        do {
            return try SFHFKeychainUtils.getPasswordForUsername(
                username,
                andServiceName: WPAccount.authKeychainServiceName,
                accessGroup: nil
            )
        } catch {
            WPLogError("Error while retrieving WordPressComOAuthKeychainServiceName token: %@", error.localizedDescription)
            throw error
        }
    }
}

private enum AuthKeyMigration {
    static let lock = NSLock()
    static var didMigrate = false

    static func migrateIfNeeded(username: String) {
        let shouldMigrate = lock.withLock {
            guard !didMigrate else { return false }
            didMigrate = true
            return true
        }
        guard shouldMigrate else { return }
        SharedDataIssueSolver.instance().migrateAuthKey(for: username)
    }
}
