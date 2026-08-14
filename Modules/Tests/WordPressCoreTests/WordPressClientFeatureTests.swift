import Foundation
import Testing
import WordPressAPI
import WordPressAPIInternal
@testable import WordPressCore

@Suite
struct WordPressClientFeatureTests {

    @Test
    func featureStringValues() {
        // These should never change – doing so will cause settings data to be lost
        #expect(WordPressClient.Feature.blockTheme.stringValue == "is-block-theme")
        #expect(WordPressClient.Feature.blockEditorSettings.stringValue == "block-editor-settings")
        #expect(WordPressClient.Feature.applicationPasswordExtras.stringValue == "application-password-extras")
        #expect(WordPressClient.Feature.plugins.stringValue == "plugins")
        #expect(WordPressClient.Feature.editorAssets.stringValue == "editor-assets")
    }

    /// `editorAssets` reports whether the site can serve blocks provided by plugins, which is
    /// the `editor-assets` route. `plugins` reports whether the plugin *management* API is
    /// exposed — a different route that WP.com Simple sites don't have. Conflating the two
    /// makes third-party blocks look unsupported on sites that support them perfectly well.
    @Test
    func editorAssetsIsDistinctFromPluginManagement() async throws {
        let mockAPI = MockWordPressClientAPI()
        mockAPI.mockRoutes = ["/wpcom/v2/editor-assets"]

        let client = WordPressClient(api: mockAPI, siteURL: URL(string: "https://example.com")!)

        #expect(try await client.supports(.editorAssets) == true)
        #expect(try await client.supports(.plugins) == false)
    }

    /// A site proxied through WP.com — a Simple site, or a Jetpack site with no application
    /// password — serves the route namespaced under its site id.
    @Test
    func editorAssetsUsesTheNamespacedRouteWhenProxied() async throws {
        let mockAPI = MockWordPressClientAPI()
        mockAPI.mockRoutes = ["/wpcom/v2/sites/12345/editor-assets"]

        let client = WordPressClient(api: mockAPI, siteURL: URL(string: "https://example.com")!)

        #expect(try await client.supports(.editorAssets, forSiteId: 12345) == true)
    }

    /// The two forms are alternatives, not aliases: the editor fetches whichever one matches the
    /// transport it is configured for, so a route the site serves under the *other* form is not
    /// support. Accepting either here reported support for sites the editor would then fail to
    /// load assets from.
    @Test
    func editorAssetsRejectsTheFormTheEditorWouldNotFetch() async throws {
        let bareOnly = MockWordPressClientAPI()
        bareOnly.mockRoutes = ["/wpcom/v2/editor-assets"]
        let proxiedClient = WordPressClient(api: bareOnly, siteURL: URL(string: "https://example.com")!)

        // Proxied: the editor fetches the namespaced path, which this site does not serve.
        #expect(try await proxiedClient.supports(.editorAssets, forSiteId: 12345) == false)

        let namespacedOnly = MockWordPressClientAPI()
        namespacedOnly.mockRoutes = ["/wpcom/v2/sites/12345/editor-assets"]
        let directClient = WordPressClient(api: namespacedOnly, siteURL: URL(string: "https://example.com")!)

        // Direct: the editor fetches the bare path, which this site does not serve.
        #expect(try await directClient.supports(.editorAssets) == false)
    }

    /// An Atomic, Jetpack, or self-hosted site addressed with an application password serves the
    /// route bare, and is probed without a site id.
    @Test
    func editorAssetsUsesTheBareRouteWhenDirect() async throws {
        let mockAPI = MockWordPressClientAPI()
        mockAPI.mockRoutes = ["/wpcom/v2/editor-assets"]

        let client = WordPressClient(api: mockAPI, siteURL: URL(string: "https://example.com")!)

        #expect(try await client.supports(.editorAssets) == true)
    }
}

@Suite("API Caching Behavior")
struct WordPressClientCachingTests {

    @Test
    func supports_cachesAPIResponses_doesNotRefetch() async throws {
        let mockAPI = MockWordPressClientAPI()
        mockAPI.mockRoutes = ["/wp-block-editor/v1/settings"]
        mockAPI.mockIsBlockTheme = true

        let client = WordPressClient(api: mockAPI, siteURL: URL(string: "https://example.com")!)

        // First call - should trigger API fetches
        let result1 = try await client.supports(.blockEditorSettings)
        #expect(result1 == true)

        // Verify API was called once
        #expect(mockAPI.apiRootCallCount == 1)
        #expect(mockAPI.usersCallCount == 1)
        #expect(mockAPI.themesCallCount == 1)

        // Second call - should use cached Task, not refetch
        let result2 = try await client.supports(.blockTheme)
        #expect(result2 == true)

        // Verify API was NOT called again
        #expect(mockAPI.apiRootCallCount == 1)
        #expect(mockAPI.usersCallCount == 1)
        #expect(mockAPI.themesCallCount == 1)

        // Third call with different feature - still uses cache
        let result3 = try await client.supports(.plugins)
        #expect(result3 == false) // Route not in mockRoutes

        // Still no additional API calls
        #expect(mockAPI.apiRootCallCount == 1)
        #expect(mockAPI.usersCallCount == 1)
        #expect(mockAPI.themesCallCount == 1)
    }

    @Test
    func supports_withSiteId_usesCachedData() async throws {
        let mockAPI = MockWordPressClientAPI()
        mockAPI.mockRoutes = ["/wp-block-editor/v1/sites/12345/settings"]

        let client = WordPressClient(api: mockAPI, siteURL: URL(string: "https://example.com")!)

        // Call with siteId
        let result = try await client.supports(.blockEditorSettings, forSiteId: 12345)
        #expect(result == true)

        // Second call with different siteId - uses same cached data
        let result2 = try await client.supports(.blockEditorSettings, forSiteId: 99999)
        #expect(result2 == false) // Different siteId, route not found

        // API was only called once total
        #expect(mockAPI.apiRootCallCount == 1)
    }

    @Test
    func supports_concurrentCalls_onlyFetchesOnce() async throws {
        let mockAPI = MockWordPressClientAPI()
        mockAPI.mockRoutes = ["/wp-block-editor/v1/settings", "/wp/v2/plugins"]
        mockAPI.mockIsBlockTheme = true

        let client = WordPressClient(api: mockAPI, siteURL: URL(string: "https://example.com")!)

        // Make multiple concurrent calls
        async let result1 = client.supports(.blockEditorSettings)
        async let result2 = client.supports(.blockTheme)
        async let result3 = client.supports(.plugins)
        async let result4 = client.supports(.applicationPasswordExtras)

        let results = try await [result1, result2, result3, result4]

        #expect(results[0] == true) // blockEditorSettings
        #expect(results[1] == true) // blockTheme
        #expect(results[2] == true) // plugins
        #expect(results[3] == false) // applicationPasswordExtras (not in routes)

        // Despite 4 concurrent calls, API should only be called once
        #expect(mockAPI.apiRootCallCount == 1)
        #expect(mockAPI.usersCallCount == 1)
        #expect(mockAPI.themesCallCount == 1)
    }
}
