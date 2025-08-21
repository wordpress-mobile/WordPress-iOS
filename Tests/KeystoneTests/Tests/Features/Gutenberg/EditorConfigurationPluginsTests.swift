import Testing
import Foundation
import CoreData
import WordPressData
import GutenbergKit

@testable import WordPress

@Suite("EditorConfiguration.shouldEnablePlugins Tests")
final class EditorConfigurationPluginsTests {
    private let contextManager = ContextManager.forTesting()
    private let keychain = TestKeychain()
    private let featureFlags = FeatureFlagOverrideStore()

    private var context: NSManagedObjectContext {
        contextManager.mainContext
    }

    init() {
        featureFlags.override(RemoteFeatureFlag.newGutenbergPlugins, withValue: true)
    }

    func tearDown() {
        featureFlags.override(RemoteFeatureFlag.newGutenbergPlugins, withValue: RemoteFeatureFlag.newGutenbergPlugins.originalValue)
    }

    @Test("Should disable plugins for non-Jetpack-connected sites without app password")
    func disablesPluginsForNonJetpackSitesWithoutAppPassword() async throws {
        let blog = BlogBuilder(context)
            .with(atomic: false)
            .isNotHostedAtWPcom()
            .with(username: "selfhosted")
            .with(url: "https://self-hosted.org")
            .build()

        let result = EditorConfiguration.shouldEnablePlugins(for: blog, appPassword: nil)

        #expect(result == false, "Should return false for non-Jetpack sites without app password")
    }

    @Test("Should enable plugins for Simple WP.com sites")
    func enablesPluginsForSimpleSites() async throws {
        let blog = BlogBuilder(context)
            .with(atomic: false)
            .isHostedAtWPcom()
            .withAnAccount(username: "simpleuser", authToken: "token")
            .with(dotComID: 12345)
            .build()

        let result = EditorConfiguration.shouldEnablePlugins(for: blog, appPassword: nil)

        #expect(result == true, "Should return true for Simple WP.com sites")
    }

    @Test("Should enable plugins for Atomic sites with app password")
    func enablesPluginsForAtomicSitesWithAppPassword() async throws {
        let blog = BlogBuilder(context)
            .with(atomic: true)
            .isNotHostedAtWPcom()
            .withAnAccount(username: "atomicuser", authToken: "token")
            .with(dotComID: 67890)
            .with(url: "https://atomic.com")
            .build()

        let result = EditorConfiguration.shouldEnablePlugins(for: blog, appPassword: "app-password-123")

        #expect(result == true, "Should return true for Atomic sites with app password")
    }

    @Test("Should disable plugins for Atomic sites without app password")
    func disablesPluginsForAtomicSitesWithoutAppPassword() async throws {
        let blog = BlogBuilder(context)
            .with(atomic: true)
            .isNotHostedAtWPcom()
            .withAnAccount(username: "atomicuser", authToken: "token")
            .with(dotComID: 67890)
            .with(url: "https://atomic.com")
            .build()

        let result = EditorConfiguration.shouldEnablePlugins(for: blog, appPassword: nil)

        #expect(result == false, "Should return false for Atomic sites without app password")
    }

    @Test("Should enable plugins for Jetpack-connected sites with app password")
    func enablesPluginsForJetpackSitesWithAppPassword() async throws {
        let blog = BlogBuilder(context)
            .with(atomic: false)
            .isNotHostedAtWPcom()
            .withAnAccount(username: "jetpackuser", authToken: "token")
            .withJetpack(version: "13.0")
            .with(dotComID: 99999)
            .with(url: "https://jetpack-site.org")
            .build()

        let result = EditorConfiguration.shouldEnablePlugins(for: blog, appPassword: "jetpack-app-password")

        #expect(result == true, "Should return true for Jetpack sites with app password")
    }

    @Test("Should disable plugins for Jetpack-connected sites without app password")
    func disablesPluginsForJetpackSitesWithoutAppPassword() async throws {
        let blog = BlogBuilder(context)
            .with(atomic: false)
            .isNotHostedAtWPcom()
            .withAnAccount(username: "jetpackuser", authToken: "token")
            .withJetpack(version: "13.0")
            .with(dotComID: 99999)
            .with(url: "https://jetpack-site.org")
            .build()

        let result = EditorConfiguration.shouldEnablePlugins(for: blog, appPassword: nil)

        #expect(result == false, "Should return false for Jetpack sites without app password")
    }

    @Test("Should use default remote flag implementation when not provided")
    func usesDefaultRemoteFlagImplementation() async throws {
        let blog = BlogBuilder(context)
            .with(atomic: false)
            .isHostedAtWPcom()
            .withAnAccount(username: "user", authToken: "token")
            .with(dotComID: 12345)
            .build()

        let result = EditorConfiguration.shouldEnablePlugins(for: blog)

        let expectedResult = RemoteFeatureFlag.newGutenbergPlugins.enabled() &&
                           blog.isAccessibleThroughWPCom() &&
                           blog.isHostedAtWPcom

        #expect(result == expectedResult,
                "Should use RemoteFeatureFlag.newGutenbergPlugins.enabled() when not provided")
    }
}
