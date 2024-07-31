import Foundation

extension Blog {

    enum BlogCredentialsError: Error {
        case blogUrlMissing
        case blogUrlInvalid
        case blogUsernameMissing
        case blogPasswordMissing
        case blogIdentifierMissing
        case invalidCredentialsUrl
        case invalidXmlRpcEndpoint
    }

    static func createRestApiBlog(
        with details: SelfHostedLoginDetails,
        in contextManager: ContextManager,
        using keychainImplementation: KeychainAccessible = KeychainUtils()
    ) async throws -> String {
        try await contextManager.performAndSave { context in
            let blog = Blog.createBlankBlog(in: context)
            blog.setUrl(details.url)
            blog.username = details.username
            try blog.setPassword(to: details.password, using: keychainImplementation)
            blog.setXMLRPCEndpoint(to: details.derivedXMLRPCRoot)
            blog.setSiteIdentifier(details.derivedSiteId)

            return details.derivedSiteId
        }
    }

    static func lookupRestApiBlog(with id: SiteIdentifier, in context: NSManagedObjectContext) throws -> Blog? {
        try BlogQuery().apiKey(is: id).blog(in: context)
    }

    static func hasRestApiBlog(with id: SiteIdentifier, in context: NSManagedObjectContext) throws -> Bool {
        BlogQuery().apiKey(is: id).count(in: context) != 0
    }

    // MARK: Type-safe wrappers
    // The underlying `Blog` object has lots of field nullability that doesn't provide guarantees about
    // which fields are present. These wrappers will `throw` if the `Blog` is invalid, allowing any dependent
    // code can be much simpler.

    /// An alias for `getPassword` to make it obvious how to retrieve Application Tokens
    ///
    func getApplicationToken(using keychainImplementation: KeychainAccessible = KeychainUtils()) throws -> String {
        try getPassword(using: keychainImplementation)
    }

    /// An alias for `setPassword` to make it obvious how to store Application Tokens
    ///
    func setApplicationToken(
        _ newValue: String,
        using keychainImplementation: KeychainAccessible = KeychainUtils()
    ) throws {
        try setPassword(to: newValue, using: keychainImplementation)
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
        try keychainImplementation.getPassword(for: self.getUsername(), serviceName: self.getUrlString())
    }

    /// A null-safe replacement for `Blog.password(set)`
    func setPassword(to newValue: String, using keychainImplementation: KeychainAccessible = KeychainUtils()) throws {
        try keychainImplementation.setPassword(for: self.getUsername(), to: newValue, serviceName: self.getUrlString())
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
}
