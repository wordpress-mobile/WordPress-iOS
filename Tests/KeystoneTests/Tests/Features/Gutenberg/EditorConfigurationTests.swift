import Testing
import Foundation
import CoreData
import XCTest
import WordPressData
import GutenbergKit

@testable import WordPress

@Suite("EditorConfiguration Authentication Tests")
struct EditorConfigurationTests {
    private let contextManager = ContextManager.forTesting()
    private let keychain = TestKeychain()

    private var context: NSManagedObjectContext {
        contextManager.mainContext
    }

    @Test("Simple site uses WP.com REST API")
    func simpleSiteUses() async throws {
        let context = self.context

        let blog = BlogBuilder(context)
            .with(atomic: false)
            .isHostedAtWPcom()
            .withAnAccount(username: "simpleuser", authToken: "simple-bearer-token")
            .with(dotComID: 12345)
            .build()

        let config = EditorConfiguration(blog: blog, postType: .post)

        #expect(config.siteApiRoot == URL(string: "https://public-api.wordpress.com/")!, "Should use WP.com API root")
        #expect(config.authHeader == "Bearer simple-bearer-token", "Should use Bearer authentication from account")
    }

    @Test("Atomic site uses WP.com REST API")
    func atomicSiteUsesWPcomRestApi() async throws {
        let context = self.context

        let blog = BlogBuilder(context)
            .with(atomic: true)
            .isNotHostedAtWPcom()
            .withAnAccount(username: "atomicuser", authToken: "atomic-bearer-token")
            .with(username: "atomicuser")
            .with(dotComID: 67890)
            .with(url: "https://atomic.com")
            .build()

        let config = EditorConfiguration(blog: blog, postType: .post)

        #expect(config.siteApiRoot == URL(string: "https://public-api.wordpress.com/")!, "Should use WP.com API root")
        #expect(config.authHeader == "Bearer atomic-bearer-token", "Should use Bearer authentication")
        #expect(config.siteApiNamespace.contains("sites/67890/"), "Should include site ID namespace")
    }

    @Test("Atomic site with application password uses self-hosted REST API")
    func atomicSiteWithAppPasswordUsesSelfHostedRestApi() async throws {
        let context = self.context

        let blog = BlogBuilder(context, dotComID: 67890)
            .with(atomic: true)
            .isNotHostedAtWPcom()
            .withAnAccount(username: "atomicuser", authToken: "atomic-bearer-token")
            .with(username: "atomicuser")
            .withApplicationPassword("test-app-password-1234", using: keychain)
            .build()

        let config = EditorConfiguration(blog: blog, postType: .post, keychain: keychain)
        let base64Credentials = "YXRvbWljdXNlcjp0ZXN0LWFwcC1wYXNzd29yZC0xMjM0" // Base64 encoding of "atomicuser:test-app-password-1234"

        #expect(config.siteApiRoot == URL(string: "https://67890.example.com/wp-json/")!, "Should use self-hosted API URL")
        #expect(config.authHeader == "Basic \(base64Credentials)", "Should use Basic authentication")
        #expect(config.siteApiNamespace.isEmpty, "Should not have WP.com API namespace")
    }

    @Test("Self-hosted site uses self-hosted REST API")
    func selfHostedSiteUsesSelfHostedAPI() async throws {
        let context = self.context

        let blog = BlogBuilder(context)
            .with(atomic: false)
            .isNotHostedAtWPcom()
            .with(username: "selfhosteduser")
            .with(url: "https://self-hosted.org")
            .withApplicationPassword("test-app-password-1234", using: keychain)
            .with(restApiRootURL: "https://self-hosted.org/wp-json/")
            .build()

        let config = EditorConfiguration(blog: blog, postType: .post, keychain: keychain)
        let base64Credentials = "c2VsZmhvc3RlZHVzZXI6dGVzdC1hcHAtcGFzc3dvcmQtMTIzNA==" // Base64 encoding of "selfhosteduser:test-app-password-1234"

        #expect(config.siteApiRoot == URL(string: "https://self-hosted.org/wp-json/")!, "Should use self-hosted API URL")
        #expect(config.authHeader == "Basic \(base64Credentials)", "Should use Basic authentication")
        #expect(config.siteApiNamespace.isEmpty, "Should not have WP.com API namespace")
    }

    @Test("Self-hosted site with Jetpack connection uses WP.com REST API")
    func selfHostedSiteWithJetpackUsesWPcomRestApi() async throws {
        let context = self.context

        let blog = BlogBuilder(context, dotComID: 12345)
            .with(atomic: false)
            .isNotHostedAtWPcom()
            .withAnAccount(username: "selfhosteduser", authToken: "self-hosted-bearer-token")
            .with(username: "selfhosteduser")
            .with(url: "https://self-hosted.org")
            .build()

        let config = EditorConfiguration(blog: blog, postType: .post, keychain: keychain)

        #expect(config.siteApiRoot == URL(string: "https://public-api.wordpress.com/"), "Should use WP.com API root")
        #expect(config.authHeader == "Bearer self-hosted-bearer-token", "Should use Bearer authentication")
        #expect(config.siteApiNamespace.contains("sites/12345/"), "Should include site ID namespace")
    }

    @Test("Self-hosted site with Jetpack connection and application password uses self-hosted REST API")
    func selfHostedSiteWithJetpackAndAppPasswordUsesWPcomRestApi() async throws {
        let context = self.context

        let blog = BlogBuilder(context, dotComID: 12345)
            .with(atomic: false)
            .isNotHostedAtWPcom()
            .withAnAccount(username: "selfhosteduser", authToken: "self-hosted-bearer-token")
            .with(username: "selfhosteduser")
            .with(url: "https://self-hosted.org")
            .withApplicationPassword("test-app-password-1234", using: keychain)
            .with(restApiRootURL: "https://self-hosted.org/wp-json/")
            .build()

        let config = EditorConfiguration(blog: blog, postType: .post, keychain: keychain)
        let base64Credentials = "c2VsZmhvc3RlZHVzZXI6dGVzdC1hcHAtcGFzc3dvcmQtMTIzNA==" // Base64 encoding of "selfhosteduser:test-app-password-1234"

        #expect(config.siteApiRoot == URL(string: "https://self-hosted.org/wp-json/"), "Should use self-hosted API URL")
        #expect(config.authHeader == "Basic \(base64Credentials)", "Should use Basic authentication")
        #expect(config.siteApiNamespace.isEmpty, "Should not have WP.com API namespace")
    }

    // MARK: - Editor Assets Endpoint

    @Test("Editor assets endpoint is appended to a path-based API root")
    func editorAssetsEndpointWithPathBasedApiRoot() async throws {
        let context = self.context

        let blog = BlogBuilder(context)
            .with(atomic: false)
            .isNotHostedAtWPcom()
            .with(username: "selfhosteduser")
            .with(url: "https://self-hosted.org")
            .withApplicationPassword("test-app-password-1234", using: keychain)
            .with(restApiRootURL: "https://self-hosted.org/wp-json/")
            .build()

        let config = EditorConfiguration(blog: blog, postType: .post, keychain: keychain)

        #expect(
            config.editorAssetsEndpoint
                == URL(string: "https://self-hosted.org/wp-json/wpcom/v2/editor-assets"),
            "Should append the endpoint to the path of a path-based API root"
        )
    }

    /// Sites using plain permalinks have no path-based REST root, so WordPress advertises the
    /// query form and the endpoint belongs in the `rest_route` value rather than the URL path.
    @Test("Editor assets endpoint is appended to the route of a query-based API root")
    func editorAssetsEndpointWithQueryBasedApiRoot() async throws {
        let context = self.context

        let blog = BlogBuilder(context)
            .with(atomic: false)
            .isNotHostedAtWPcom()
            .with(username: "selfhosteduser")
            .with(url: "https://self-hosted.org")
            .withApplicationPassword("test-app-password-1234", using: keychain)
            .with(restApiRootURL: "https://self-hosted.org/?rest_route=/")
            .build()

        let config = EditorConfiguration(blog: blog, postType: .post, keychain: keychain)

        #expect(
            config.editorAssetsEndpoint
                == URL(string: "https://self-hosted.org/?rest_route=/wpcom/v2/editor-assets"),
            "Should append the endpoint to the rest_route value, not the URL path"
        )
    }

    @Test("Editor assets endpoint includes the site namespace for WP.com sites")
    func editorAssetsEndpointIncludesNamespace() async throws {
        let context = self.context

        let blog = BlogBuilder(context)
            .with(atomic: false)
            .isHostedAtWPcom()
            .withAnAccount(username: "simpleuser", authToken: "simple-bearer-token")
            .with(dotComID: 12345)
            .build()

        let config = EditorConfiguration(blog: blog, postType: .post, keychain: keychain)

        #expect(
            config.editorAssetsEndpoint
                == URL(string: "https://public-api.wordpress.com/wpcom/v2/sites/12345/editor-assets"),
            "Should insert the site namespace before the endpoint"
        )
    }
}
