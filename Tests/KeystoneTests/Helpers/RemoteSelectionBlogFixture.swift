import CoreData
import Foundation
@testable import WordPressData

/// Blogs for testing which remote a factory selects, with and without a WordPress.com token.
///
/// Keychain access is isolated, so these blogs never read or write the simulator keychain.
@objc public final class RemoteSelectionBlogFixture: NSObject {

    /// A blog hosted at WordPress.com whose account has the given token.
    @objc public static func dotComBlog(authToken: String?, context: NSManagedObjectContext) -> Blog {
        let blog = makeBlog(host: "example.wordpress.com", context: context)
        blog.isHostedAtWPcom = true
        blog.dotComID = 1
        blog.account = makeAccount(authToken: authToken, context: context)
        return blog
    }

    /// A Jetpack-connected self-hosted blog whose account has the given token and that may store XML-RPC credentials.
    @objc public static func jetpackBlog(
        authToken: String?,
        xmlrpcPassword: String?,
        context: NSManagedObjectContext
    ) -> Blog {
        let blog = makeBlog(host: "jetpack.example.com", context: context)
        blog.isHostedAtWPcom = false
        blog.dotComID = 2
        blog.account = makeAccount(authToken: authToken, context: context)
        if let xmlrpcPassword {
            blog.username = "xmlrpc-\(UUID().uuidString)"
            blog.password = xmlrpcPassword
        }
        return blog
    }

    /// A self-hosted blog without an account that stores XML-RPC credentials.
    @objc public static func selfHostedBlog(context: NSManagedObjectContext) -> Blog {
        let blog = makeBlog(host: "self-hosted.example.com", context: context)
        blog.username = "xmlrpc-\(UUID().uuidString)"
        blog.password = "password"
        return blog
    }

    private static func makeBlog(host: String, context: NSManagedObjectContext) -> Blog {
        let blog = Blog(context: context)
        blog.keychain = TestKeychain()
        blog.url = "https://\(host)/"
        blog.xmlrpc = "https://\(host)/xmlrpc.php"
        return blog
    }

    private static func makeAccount(authToken: String?, context: NSManagedObjectContext) -> WPAccount {
        let account = WPAccount(context: context)
        account.mockKeychain()
        // A unique username keeps the real keychain, which `WordPressSite(blog:)` falls back to, from matching.
        account.username = "account-\(UUID().uuidString)"
        account.authToken = authToken
        return account
    }
}
