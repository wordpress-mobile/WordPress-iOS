import Foundation

// MARK: - Authenticator Credentials
//
public struct AuthenticatorCredentials {
    /// WordPress.com credentials
    ///
    public let wpcom: WordPressComCredentials?

    /// Self-hosted site credentials
    ///
    public let wporg: WordPressOrgCredentials?

    /// Designated initializer
    ///
    public init(wpcom: WordPressComCredentials? = nil, wporg: WordPressOrgCredentials? = nil) {
        self.wpcom = wpcom
        self.wporg = wporg
    }
}
