import Foundation
import CoreData
import CryptoKit
import WordPressAPI
import WordPressShared

public extension Blog {

    enum BlogCredentialsError: Error {
        case blogUrlMissing
        case blogUrlInvalid
        case blogUsernameMissing
        case blogPasswordMissing
        case blogIdentifierMissing
        case invalidCredentialsUrl
        case invalidXmlRpcEndpoint
        case incorrectCredentials
    }

    static func createRestApiBlog(
        with details: WpApiApplicationPasswordDetails,
        restApiRootURL: URL,
        xmlrpcEndpointURL: URL,
        blogID: TaggedManagedObjectID<Blog>?,
        in contextManager: ContextManager,
        using keychainImplementation: KeychainAccessible = KeychainUtils()
    ) async throws -> TaggedManagedObjectID<Blog> {
        try await contextManager.performAndSave { context in
            let blog =
                if let blogID {
                    try context.existingObject(with: blogID)
                } else {
                    Blog.lookup(username: details.userLogin, xmlrpc: xmlrpcEndpointURL.absoluteString, in: context)
                        ?? Blog.createBlankBlog(in: context)
                }

            blog.url = details.siteUrl
            blog.username = details.userLogin
            blog.restApiRootURL = restApiRootURL.absoluteString
            blog.setXMLRPCEndpoint(to: xmlrpcEndpointURL)
            blog.setSiteIdentifier(details.derivedSiteId)

            // `url` and `xmlrpc` need to be set before setting the application password.
            try blog.setApplicationToken(details.password, using: keychainImplementation)
            // We don't overwrite the `Blog.password` with the application password (`details.password`), because we want
            // the application continues to function when the application password is revoked.

            return TaggedManagedObjectID(blog)
        }
    }

    static func lookupRestApiBlog(with id: SiteIdentifier, in context: NSManagedObjectContext) throws -> Blog? {
        try BlogQuery().apiKey(is: id).blog(in: context)
    }

    static func hasRestApiBlog(with id: SiteIdentifier, in context: NSManagedObjectContext) throws -> Bool {
        BlogQuery().apiKey(is: id).count(in: context) != 0
    }

    @objc(getApplicationTokenWithError:)
    func objc_getApplicationToken() throws -> String {
        try getApplicationToken()
    }

    // MARK: Type-safe wrappers
    // The underlying `Blog` object has lots of field nullability that doesn't provide guarantees about
    // which fields are present. These wrappers will `throw` if the `Blog` is invalid, allowing any dependent
    // code can be much simpler.

    /// Retrieve Application Tokens
    ///
    func getApplicationToken(using keychainImplementation: KeychainAccessible = KeychainUtils()) throws -> String {
        try keychainImplementation.getPassword(for: self.getUsername(), serviceName: self.getUrlString())
    }

    /// Delete Application Token
    ///
    func deleteApplicationToken(using keychainImplementation: KeychainAccessible = KeychainUtils()) throws {
        try? keychainImplementation.setPassword(for: self.getUsername(), to: nil, serviceName: self.getUrlString())
    }

    @available(swift, obsoleted: 1.0)
    @objc(deleteApplicationToken)
    func objc_deleteApplicationToken() {
        _ = try? deleteApplicationToken()
    }

    /// Store Application Tokens
    ///
    func setApplicationToken(
        _ newValue: String,
        using keychainImplementation: KeychainAccessible = KeychainUtils()
    ) throws {
        try keychainImplementation.setPassword(for: self.getUsername(), to: newValue, serviceName: self.getUrlString())
    }

    /// A null-safe wrapper for `Blog.username`
    func getUsername() throws -> String {
        guard let username = self.username else {
            throw BlogCredentialsError.blogUsernameMissing
        }

        return username
    }

    /// A null-safe replacement for `Blog.password(get)`
    func getPassword(using keychainImplementation: KeychainAccessible = KeychainUtils()) throws -> String {
        try keychainImplementation.getPassword(
            for: self.getUsername(),
            serviceName: self.getXMLRPCEndpoint().absoluteString
        )
    }

    /// A null-safe replacement for `Blog.password(set)`
    func setPassword(to newValue: String, using keychainImplementation: KeychainAccessible = KeychainUtils()) throws {
        try keychainImplementation.setPassword(
            for: self.getUsername(),
            to: newValue,
            serviceName: self.getXMLRPCEndpoint().absoluteString
        )
    }

    func wordPressClientParsedUrl() throws -> ParsedUrl {
        try ParsedUrl.parse(input: self.getUrl().absoluteString)
    }

    /// A null-and-type-safe replacement for `Blog.url(get)`
    func getUrl() throws -> URL {
        guard let stringUrl = self.url else {
            throw BlogCredentialsError.blogUrlMissing
        }

        guard let url = URL(string: stringUrl) else {
            throw BlogCredentialsError.blogUrlInvalid
        }

        return url
    }

    /// A null-safe helper for `Blog.url(get)`, when what you really want is a String
    func getUrlString() throws -> String {
        try getUrl().absoluteString
    }

    /// A type-safe helper for `Blog.url(set)` that takes a URL directly (instead of a string)
    func setUrl(_ newValue: URL) {
        self.url = newValue.absoluteString
    }

    /// A null-and-type-safe replacement for `Blog.xmlrpc(get)`
    func getXMLRPCEndpoint() throws -> URL {
        guard let urlString = self.xmlrpc, let url = URL(string: urlString) else {
            throw BlogCredentialsError.invalidXmlRpcEndpoint
        }

        return url
    }

    /// A type-safe helper for `Blog.xmlrpc(set)` that takes a URL directly (instead of a string)
    func setXMLRPCEndpoint(to newValue: URL) {
        self.xmlrpc = newValue.absoluteString
    }

    /// There's `dotComId` for WordPress.com blogs, but we don't have a good way to lookup REST API sites with a scalar value.
    ///
    /// This hack fixes that – we should never store API Keys in Core Data anyway, so we can (mis)use that field to add a unique identifier
    typealias SiteIdentifier = String

    func getSiteIdentifier() throws -> SiteIdentifier {
        guard let identifier = self.apiKey else {
            throw BlogCredentialsError.blogIdentifierMissing
        }

        return identifier
    }

    func setSiteIdentifier(_ newValue: SiteIdentifier) {
        self.apiKey = newValue
    }

    @objc var isSelfHosted: Bool {
        self.account == nil
    }

    @objc var hasDirectCoreRESTAPIAccess: Bool {
        guard let site = try? WordPressSite(blog: self) else {
            return false
        }
        return site.applicationPasswordCredentials != nil
    }
}

public extension WpApiApplicationPasswordDetails {
    var derivedSiteId: String {
        SHA256.hash(data: Data(siteUrl.localizedLowercase.utf8))
            .compactMap { String(format: "%02x", $0) }
            .joined()
    }
}

/// Describes a WordPress site's hosting type, authentication credentials,
/// and API capabilities.
///
/// This is a value type constructed from a `Blog` Core Data object. It captures
/// a snapshot of the site's characteristics at construction time.
///
/// `WordPressSite` is not a one-to-one mapping with `Blog`. It represents the
/// subset of `Blog` instances that have access to the WordPress core REST API
/// (wp/v2). A self-hosted site that only has XML-RPC credentials is not
/// representable as a `WordPressSite`.
///
/// - All WordPress.com sites qualify (wp/v2 is accessed via WP.com REST API
///   with OAuth).
/// - Self-hosted sites must have application password credentials.
public struct WordPressSite {
    public let blogId: TaggedManagedObjectID<Blog>
    public let siteURL: URL
    public let flavor: Flavor

    public init(blogId: TaggedManagedObjectID<Blog>, siteURL: URL, flavor: Flavor) {
        self.blogId = blogId
        self.siteURL = siteURL
        self.flavor = flavor
    }
}

extension WordPressSite {
    public enum Flavor {
        /// A site hosted on WordPress.com. Always has OAuth access via
        /// WPAccount. May also have application password credentials
        /// (e.g., Atomic sites).
        case dotCom(DotComCredentials)

        /// A self-hosted WordPress site with application password credentials.
        /// Application password is required for wp/v2 API access.
        case selfHosted(ApplicationPasswordCredentials)
    }
}

extension WordPressSite {
    public struct DotComCredentials: Hashable {
        public let siteId: Int
        public let oAuthToken: String
        /// Non-nil for Atomic sites that also have application password access.
        public let applicationPassword: ApplicationPasswordCredentials?

        public init(siteId: Int, oAuthToken: String, applicationPassword: ApplicationPasswordCredentials?) {
            self.siteId = siteId
            self.oAuthToken = oAuthToken
            self.applicationPassword = applicationPassword
        }
    }

    public struct ApplicationPasswordCredentials: Hashable {
        public let apiRootURL: ParsedUrl
        public let username: String
        public let token: String

        public init(apiRootURL: ParsedUrl, username: String, token: String) {
            self.apiRootURL = apiRootURL
            self.username = username
            self.token = token
        }
    }
}

extension WordPressSite: Hashable {
    public static func == (lhs: WordPressSite, rhs: WordPressSite) -> Bool {
        lhs.blogId == rhs.blogId
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(blogId)
    }
}

extension WordPressSite {
    /// Constructs a `WordPressSite` from a `Blog` Core Data object.
    ///
    /// Throws if the blog lacks enough data to determine its hosting type
    /// and at least one valid authentication method.
    ///
    /// For self-hosted sites, application password credentials are required.
    /// Sites without them cannot be represented as a `WordPressSite`.
    public init(blog: Blog, keychain: KeychainAccessible = KeychainUtils()) throws {
        let siteURL = try blog.getUrl()
        self.blogId = TaggedManagedObjectID(blog)
        self.siteURL = siteURL

        // Build application password credentials if available.
        // These are shared across both hosting types — WordPress.com Atomic
        // sites can have them too.
        let applicationPassword: ApplicationPasswordCredentials?
        if let restApiRootURL = blog.restApiRootURL,
            let parsedApiRoot = try? ParsedUrl.parse(input: restApiRootURL),
            let username = blog.username,
            let token = try? blog.getApplicationToken(using: keychain)
        {
            applicationPassword = ApplicationPasswordCredentials(
                apiRootURL: parsedApiRoot,
                username: username,
                token: token
            )
        } else {
            applicationPassword = nil
        }

        // Check for WordPress.com account first. This means Atomic sites
        // (which have both an account and application password credentials)
        // resolve to `.dotCom`.
        if let account = blog.account,
            let siteId = blog.dotComID?.intValue
        {
            let authToken =
                try account.authToken
                ?? WPAccount.token(forUsername: account.username)
            self.flavor = .dotCom(
                DotComCredentials(
                    siteId: siteId,
                    oAuthToken: authToken,
                    applicationPassword: applicationPassword
                )
            )
        } else {
            // Self-hosted sites must have application password credentials
            // for wp/v2 API access.
            guard let applicationPassword else {
                throw Blog.BlogCredentialsError.blogPasswordMissing
            }
            self.flavor = .selfHosted(applicationPassword)
        }
    }
}

extension WordPressSite {
    /// How the app reaches the site's wp/v2 REST API.
    ///
    /// Unlike `flavor`, which describes how the site is presented in the app,
    /// `Transport` decides which endpoint and credentials to use for API
    /// access. The two don't always line up: a WordPress.com Atomic site
    /// presents as `.dotCom` but is accessed directly when application
    /// password credentials are available.
    public enum Transport {
        /// Requests go to the site's own REST API root, authenticated with
        /// an application password.
        case direct(ApplicationPasswordCredentials)

        /// Requests are proxied through the WP.com REST API, authenticated
        /// with the account's OAuth token.
        case dotComProxy(siteId: Int, oAuthToken: String)
    }

    /// Direct site access is preferred whenever application password
    /// credentials are available, because it does not depend on the WP.com
    /// proxy and works for site features the proxy does not expose.
    public var transport: Transport {
        switch flavor {
        case let .dotCom(credentials):
            if let applicationPassword = credentials.applicationPassword {
                return .direct(applicationPassword)
            }
            return .dotComProxy(siteId: credentials.siteId, oAuthToken: credentials.oAuthToken)
        case let .selfHosted(credentials):
            return .direct(credentials)
        }
    }

    /// The application password credentials, if available.
    /// Always non-nil for self-hosted sites. Optional for WordPress.com sites
    /// (non-nil for Atomic sites).
    public var applicationPasswordCredentials: ApplicationPasswordCredentials? {
        switch flavor {
        case let .dotCom(credentials):
            return credentials.applicationPassword
        case let .selfHosted(credentials):
            return credentials
        }
    }

    /// Look up the `Blog` object in a given Core Data context.
    public func blog(in context: NSManagedObjectContext) throws -> Blog {
        try context.existingObject(with: blogId)
    }
}
