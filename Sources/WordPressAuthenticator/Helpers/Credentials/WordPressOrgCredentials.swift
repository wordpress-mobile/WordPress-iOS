import Foundation

// MARK: - WordPress.org (aka self-hosted site) Credentials
//
public struct WordPressOrgCredentials: Equatable {
    /// Self-hosted login username.
    /// The one used in the /wp-admin/ panel.
    ///
    public let username: String

    /// Self-hosted login password.
    /// The one used in the /wp-admin/ panel.
    ///
    public let password: String

    /// The URL to reach the XMLRPC file.
    /// e.g.: https://exmaple.com/xmlrpc.php
    ///
    public let xmlrpc: String

    /// Self-hosted site options
    ///
    public let options: [AnyHashable: Any]

    /// Designated initializer
    ///
    public init(username: String, password: String, xmlrpc: String, options: [AnyHashable: Any]) {
        self.username = username
        self.password = password
        self.xmlrpc = xmlrpc
        self.options = options
    }

    /// Returns site URL by stripping "/xmlrpc.php" from `xmlrpc` String property
    ///
    public var siteURL: String {
        xmlrpc.removingSuffix("/xmlrpc.php")
    }
}

// MARK: - Equatable Conformance
//
public func ==(lhs: WordPressOrgCredentials, rhs: WordPressOrgCredentials) -> Bool {
    return lhs.username == rhs.username && lhs.password == rhs.password && lhs.xmlrpc == rhs.xmlrpc
}
