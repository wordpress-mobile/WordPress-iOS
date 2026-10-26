import CoreData
import Foundation
import Security
import Testing
import WordPressShared

@testable import WordPressData

struct BlogMissingCredentialsTests {
    private let contextManager = ContextManager.forTesting()
    private var mainContext: NSManagedObjectContext { contextManager.mainContext }
    private let keychain = ServiceKeyedKeychain()

    private func makeSelfHostedBlog() -> Blog {
        BlogBuilder(mainContext, dotComID: nil)
            .with(username: "admin")
            .build()
    }

    @Test func selfHostedSiteWithNothingStoredIsMissingCredentials() {
        let blog = makeSelfHostedBlog()

        #expect(blog.isMissingSelfHostedCredentials(using: keychain))
    }

    @Test func selfHostedSiteWithApplicationPasswordIsNotMissingCredentials() throws {
        let blog = makeSelfHostedBlog()
        try blog.setApplicationToken("app-password", using: keychain)

        #expect(!blog.isMissingSelfHostedCredentials(using: keychain))
    }

    @Test func selfHostedSiteWithXMLRPCPasswordIsNotMissingCredentials() throws {
        let blog = makeSelfHostedBlog()
        try blog.setPassword(to: "account-password", using: keychain)

        #expect(!blog.isMissingSelfHostedCredentials(using: keychain))
    }

    @Test func keychainFailureIsNotMissingCredentials() {
        let blog = makeSelfHostedBlog()
        // The error `AppKeychain` reports when the device is locked.
        keychain.readError = NSError(domain: "SFHFKeychainUtilsErrorDomain", code: Int(errSecInteractionNotAllowed))

        #expect(!blog.isMissingSelfHostedCredentials(using: keychain))
    }

    @Test func siteWithWordPressComAccountIsNotMissingCredentials() {
        let blog = BlogBuilder(mainContext)
            .with(username: "admin")
            .withAccount()
            .build()

        #expect(!blog.isMissingSelfHostedCredentials(using: keychain))
    }

    @Test func siteWithoutUsernameIsNotMissingCredentials() {
        let blog = BlogBuilder(mainContext, dotComID: nil).build()

        #expect(!blog.isMissingSelfHostedCredentials(using: keychain))
    }
}

/// Keeps the application password (keyed by site URL) apart from the XML-RPC password (keyed by
/// XML-RPC endpoint), which `MockKeychainService` does not.
private final class ServiceKeyedKeychain: KeychainAccessible {
    struct NotFound: Error {}

    var items: [String: String] = [:]
    var readError: Error?

    func getPassword(for username: String, serviceName: String) throws -> String {
        if let readError { throw readError }
        guard let value = items["\(serviceName)|\(username)"] else { throw NotFound() }
        return value
    }

    func setPassword(for username: String, to newValue: String?, serviceName: String) throws {
        items["\(serviceName)|\(username)"] = newValue
    }
}
