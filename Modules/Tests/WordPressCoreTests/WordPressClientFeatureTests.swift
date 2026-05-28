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
    }
}

@Suite("API Caching Behavior")
struct WordPressClientCachingTests {

    @Test
    func supports_cachesAPIResponses_doesNotRefetch() async throws {
        let mockAPI = MockWordPressClientAPI()
        mockAPI.mockRoutes = ["/wp-block-editor/v1/settings"]
        mockAPI.mockIsBlockTheme = true

        let client = try WordPressClient(api: mockAPI, siteURL: URL(string: "https://example.com")!)

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

        let client = try WordPressClient(api: mockAPI, siteURL: URL(string: "https://example.com")!)

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

        let client = try WordPressClient(api: mockAPI, siteURL: URL(string: "https://example.com")!)

        // Make multiple concurrent calls
        async let result1 = client.supports(.blockEditorSettings)
        async let result2 = client.supports(.blockTheme)
        async let result3 = client.supports(.plugins)
        async let result4 = client.supports(.applicationPasswordExtras)

        let results = try await [result1, result2, result3, result4]

        #expect(results[0] == true)  // blockEditorSettings
        #expect(results[1] == true)  // blockTheme
        #expect(results[2] == true)  // plugins
        #expect(results[3] == false) // applicationPasswordExtras (not in routes)

        // Despite 4 concurrent calls, API should only be called once
        #expect(mockAPI.apiRootCallCount == 1)
        #expect(mockAPI.usersCallCount == 1)
        #expect(mockAPI.themesCallCount == 1)
    }
}
