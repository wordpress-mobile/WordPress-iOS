import CoreData
import Foundation
import GutenbergKit
import Testing
import WordPressCore
import WordPressData
import WordPressShared

@testable import WordPress

// Serialized because capability support is keyed on `Blog.locallyUniqueId`, which hashes the
// Core Data object ID. Newly inserted blogs have temporary IDs that can repeat across parallel
// tests, letting one test's `setSupports` write land on another test's blog.
@Suite("Third-party blocks capability resolution", .serialized)
final class EditorConfigurationPluginsTests {
    private let contextManager = ContextManager.forTesting()
    private let database = EphemeralKeyValueDatabase()

    private var context: NSManagedObjectContext {
        contextManager.mainContext
    }

    private var settings: GutenbergSettings {
        GutenbergSettings(database: database)
    }

    /// Resolves with the remote feature flag pinned on, which is the interesting case for most
    /// of these tests. The flag is passed explicitly rather than overridden globally so the
    /// suite can run in parallel without tests clobbering each other's flag state.
    private func resolve(
        for blog: Blog,
        appPassword: String? = nil,
        isFeatureFlagEnabled: Bool = true
    ) -> ThirdPartyBlocksCapability {
        settings.resolveThirdPartyBlocks(
            for: blog,
            appPassword: appPassword,
            isFeatureFlagEnabled: isFeatureFlagEnabled
        )
    }

    /// A Simple WP.com site, which needs no application password.
    private func makeSimpleBlog() -> Blog {
        let blog = BlogBuilder(context)
            .with(atomic: false)
            .isHostedAtWPcom()
            .withAnAccount(username: "plugins-simpleuser", authToken: "token")
            .with(dotComID: 12345)
            .build()
        return withPermanentID(blog)
    }

    /// Capability support is keyed on `Blog.locallyUniqueId`, which hashes the Core Data object
    /// ID. Newly inserted objects start with a temporary ID that Core Data replaces on save, so
    /// a write made before the save would be read back under a different key. Saving up front
    /// keeps the key stable for the life of the test.
    private func withPermanentID(_ blog: Blog) -> Blog {
        try? context.obtainPermanentIDs(for: [blog])
        return blog
    }

    /// A self-hosted site signed in directly, with no WordPress.com account.
    private func makeSelfHostedBlog() -> Blog {
        let blog = BlogBuilder(context)
            .with(atomic: false)
            .isNotHostedAtWPcom()
            .with(username: "selfhosted")
            .with(url: "https://self-hosted.org")
            .build()
        return withPermanentID(blog)
    }

    /// A Jetpack-connected site, which authenticates with an application password.
    private func makeJetpackBlog() -> Blog {
        let blog = BlogBuilder(context)
            .with(atomic: false)
            .isNotHostedAtWPcom()
            .withAnAccount(username: "plugins-jetpackuser", authToken: "token")
            .withJetpack(version: "13.0")
            .with(dotComID: 99999)
            .with(url: "https://jetpack-site.org")
            .build()
        return withPermanentID(blog)
    }

    // MARK: - Flag gating

    @Test("Hidden when the remote feature flag is off, even if the user opted in")
    func hiddenWhenFlagOff() throws {
        let blog = makeSimpleBlog()
        let settings = settings
        settings.setThirdPartyBlocksEnabled(true, for: blog)
        settings.setSupports(.editorAssets, true, for: blog)

        let capability = resolve(for: blog, isFeatureFlagEnabled: false)

        #expect(capability == .hidden)
        #expect(capability.shouldApplyInEditor == false)
        #expect(capability.isVisibleInSiteSettings == false)
    }

    // MARK: - Site eligibility

    /// A self-hosted site signed in with an application password has no WordPress.com account, so
    /// it isn't `isAccessibleThroughWPCom` — but a site running Jetpack still serves
    /// `/wpcom/v2/editor-assets` from its own API root. Eligibility is the probe's call, not a
    /// judgement about how the site is hosted.
    @Test("Available for a self-hosted site whose probe found the editor-assets route")
    func availableForSelfHostedSiteWithCapability() throws {
        let blog = makeSelfHostedBlog()
        let settings = settings
        settings.setSupports(.editorAssets, true, for: blog)
        settings.setThirdPartyBlocksEnabled(true, for: blog)

        let capability = resolve(for: blog, appPassword: "app-password")

        #expect(capability == .available(true))
        #expect(capability.shouldApplyInEditor == true)
    }

    @Test("Unsupported for a self-hosted site whose probe found no editor-assets route")
    func unsupportedForSelfHostedSiteWithoutCapability() throws {
        let blog = makeSelfHostedBlog()
        settings.setSupports(.editorAssets, false, for: blog)

        let capability = resolve(for: blog, appPassword: "app-password")

        #expect(capability == .unsupported)
        #expect(capability.shouldApplyInEditor == false)
        // Android shows the row disabled rather than hiding it.
        #expect(capability.isVisibleInSiteSettings == true)
        #expect(capability.isInteractive == false)
    }

    @Test("Unsupported for a Jetpack site with no application password")
    func unsupportedWithoutApplicationPassword() throws {
        let blog = makeJetpackBlog()

        let capability = resolve(for: blog, appPassword: nil)

        #expect(capability == .unsupported)
        #expect(capability.shouldApplyInEditor == false)
    }

    @Test("Unsupported when the site was probed and lacks the editor-assets route")
    func unsupportedWhenProbedWithoutCapability() throws {
        let blog = makeSimpleBlog()
        let settings = settings
        settings.setSupports(.editorAssets, false, for: blog)
        // Even an explicit opt-in can't override a site that can't serve the blocks.
        settings.setThirdPartyBlocksEnabled(true, for: blog)

        let capability = resolve(for: blog)

        #expect(capability == .unsupported)
        #expect(capability.shouldApplyInEditor == false)
    }

    @Test("Available when the site has not been probed yet, so the setting stays reachable")
    func availableWhenNotYetProbed() throws {
        let blog = makeSimpleBlog()

        #expect(settings.hasProbedSupport(for: .editorAssets, blog: blog) == false)

        let capability = resolve(for: blog)

        #expect(capability == .available(false))
        #expect(capability.isInteractive == true)
    }

    // MARK: - User preference

    @Test("Defaults to off, so a capable site does not load plugins until the user opts in")
    func defaultsToDisabled() throws {
        let blog = makeSimpleBlog()
        let settings = settings
        settings.setSupports(.editorAssets, true, for: blog)

        let capability = resolve(for: blog)

        #expect(capability == .available(false))
        #expect(capability.shouldApplyInEditor == false)
    }

    @Test("Applies in the editor once flag, capability, and preference all agree")
    func appliesWhenAllConditionsMet() throws {
        let blog = makeSimpleBlog()
        let settings = settings
        settings.setSupports(.editorAssets, true, for: blog)
        settings.setThirdPartyBlocksEnabled(true, for: blog)

        let capability = resolve(for: blog)

        #expect(capability == .available(true))
        #expect(capability.shouldApplyInEditor == true)
    }

    @Test("Applies for a Jetpack site with an application password")
    func appliesForJetpackSiteWithApplicationPassword() throws {
        let blog = makeJetpackBlog()
        let settings = settings
        settings.setSupports(.editorAssets, true, for: blog)
        settings.setThirdPartyBlocksEnabled(true, for: blog)

        let capability = resolve(for: blog, appPassword: "jetpack-app-password")

        #expect(capability == .available(true))
        #expect(capability.shouldApplyInEditor == true)
    }

    @Test("Preference is stored per site")
    func preferenceIsPerSite() throws {
        let enabledBlog = makeSimpleBlog()
        let otherBlog = withPermanentID(
            BlogBuilder(context)
                .with(atomic: false)
                .isHostedAtWPcom()
                .withAnAccount(username: "plugins-otheruser", authToken: "token")
                .with(dotComID: 54321)
                .with(url: "https://other-site.com")
                .build()
        )

        let settings = settings
        settings.setSupports(.editorAssets, true, for: enabledBlog)
        settings.setSupports(.editorAssets, true, for: otherBlog)
        settings.setThirdPartyBlocksEnabled(true, for: enabledBlog)

        #expect(resolve(for: enabledBlog) == .available(true))
        #expect(resolve(for: otherBlog) == .available(false))
    }

    // MARK: - Editor entry point

    @Test("shouldEnablePlugins follows the resolved capability")
    func shouldEnablePluginsFollowsCapability() throws {
        let blog = makeSimpleBlog()
        let settings = settings
        settings.setSupports(.editorAssets, true, for: blog)

        #expect(
            EditorConfiguration.shouldEnablePlugins(
                for: blog,
                settings: settings,
                isFeatureFlagEnabled: true
            ) == false
        )

        settings.setThirdPartyBlocksEnabled(true, for: blog)

        #expect(
            EditorConfiguration.shouldEnablePlugins(
                for: blog,
                settings: settings,
                isFeatureFlagEnabled: true
            ) == true
        )
    }

    @Test("shouldEnablePlugins resolves the application password with the injected keychain")
    func shouldEnablePluginsUsesInjectedKeychain() throws {
        let blog = makeSelfHostedBlog()
        let settings = settings
        settings.setSupports(.editorAssets, true, for: blog)
        settings.setThirdPartyBlocksEnabled(true, for: blog)

        // The site is eligible only by way of an application password, and that password exists
        // solely in the injected keychain. Without it the lookup falls back to the device
        // keychain, finds nothing, and the site resolves as unsupported.
        let keychain = TestKeychain()
        try keychain.setPassword(
            for: try blog.getUsername(),
            to: "app-password",
            serviceName: try blog.getUrlString()
        )

        #expect(
            EditorConfiguration.shouldEnablePlugins(
                for: blog,
                settings: settings,
                keychain: keychain,
                isFeatureFlagEnabled: true
            ) == true
        )
    }

    @Test("Preference survives the remote flag being turned off and back on")
    func preferenceSurvivesFlagCycle() throws {
        let blog = makeSimpleBlog()
        let settings = settings
        settings.setSupports(.editorAssets, true, for: blog)
        settings.setThirdPartyBlocksEnabled(true, for: blog)

        #expect(resolve(for: blog, isFeatureFlagEnabled: false) == .hidden)
        #expect(resolve(for: blog, isFeatureFlagEnabled: true) == .available(true))
    }
}
