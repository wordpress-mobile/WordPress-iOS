import Foundation
import WordPressAPI
import WordPressAPIInternal
import WordPressApiCache
@testable import WordPressCore

/// Tracks call counts for API methods to verify caching behavior.
final class MockWordPressClientAPI: WordPressClientAPI, @unchecked Sendable {
    private let lock = NSLock()

    private var _apiRootCallCount = 0
    private var _usersCallCount = 0
    private var _themesCallCount = 0

    var apiRootCallCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return _apiRootCallCount
    }

    var usersCallCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return _usersCallCount
    }

    var themesCallCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return _themesCallCount
    }

    var mockRoutes: Set<String> = []
    var mockIsBlockTheme: Bool = false

    var apiRoot: ApiRootRequestExecutor {
        lock.lock()
        _apiRootCallCount += 1
        lock.unlock()
        return MockApiRootRequestExecutor(routes: mockRoutes)
    }

    var users: UsersRequestExecutor {
        lock.lock()
        _usersCallCount += 1
        lock.unlock()
        return MockUsersRequestExecutor(noHandle: UsersRequestExecutor.NoHandle())
    }

    var themes: ThemesRequestExecutor {
        lock.lock()
        _themesCallCount += 1
        lock.unlock()
        return MockThemesRequestExecutor(isBlockTheme: mockIsBlockTheme)
    }

    // Unused in WordPressClient.supports() - provide minimal implementations
    var plugins: PluginsRequestExecutor { fatalError("Not implemented") }
    var comments: CommentsRequestExecutor { fatalError("Not implemented") }
    var media: MediaRequestExecutor { fatalError("Not implemented") }
    var taxonomies: TaxonomiesRequestExecutor { fatalError("Not implemented") }
    var terms: TermsRequestExecutor { fatalError("Not implemented") }
    var applicationPasswords: ApplicationPasswordsRequestExecutor { fatalError("Not implemented") }
    var posts: PostsRequestExecutor { fatalError("Not implemented") }
    var postTypes: PostTypesRequestExecutor { fatalError("Not implemented") }

    func createSelfHostedService(cache: WordPressApiCache) throws -> WpSelfHostedService {
        fatalError("Not implemented")
    }

    func uploadMedia(params: MediaCreateParams, fulfilling progress: Progress) async throws -> MediaRequestCreateResponse {
        fatalError("Not implemented")
    }
}

// MARK: - Mock Executors

final class MockApiRootRequestExecutor: ApiRootRequestExecutor {
    private var routes: Set<String>

    init(routes: Set<String>) {
        self.routes = routes
        super.init(noHandle: ApiRootRequestExecutor.NoHandle())
    }

    required init(unsafeFromHandle handle: UInt64) {
        self.routes = []
        super.init(unsafeFromHandle: handle)
    }

    override func getCancellation(context: RequestContext?) async throws -> ApiRootRequestGetResponse {
        let mockApiDetails = MockWpApiDetails(routes: routes)
        let mockHeaderMap = WpNetworkHeaderMap(noHandle: WpNetworkHeaderMap.NoHandle())
        return ApiRootRequestGetResponse(data: mockApiDetails, headerMap: mockHeaderMap)
    }
}

final class MockUsersRequestExecutor: UsersRequestExecutor {
    override init(noHandle: UsersRequestExecutor.NoHandle) {
        super.init(noHandle: noHandle)
    }

    required init(unsafeFromHandle handle: UInt64) {
        super.init(unsafeFromHandle: handle)
    }

    override func retrieveMeWithEditContextCancellation(context: RequestContext?) async throws -> UsersRequestRetrieveMeWithEditContextResponse {
        let mockUser = UserWithEditContext(
            id: UserId(1),
            username: "testuser",
            name: "Test User",
            firstName: "Test",
            lastName: "User",
            email: "test@example.com",
            url: "",
            description: "",
            link: "https://example.com/author/testuser",
            locale: "en_US",
            nickname: "testuser",
            slug: "testuser",
            registeredDate: "2024-01-01T00:00:00",
            roles: [],
            capabilities: [:],
            extraCapabilities: [:],
            avatarUrls: nil
        )
        let mockHeaderMap = WpNetworkHeaderMap(noHandle: WpNetworkHeaderMap.NoHandle())
        return UsersRequestRetrieveMeWithEditContextResponse(data: mockUser, headerMap: mockHeaderMap)
    }
}

final class MockThemesRequestExecutor: ThemesRequestExecutor {
    private var isBlockTheme: Bool

    init(isBlockTheme: Bool) {
        self.isBlockTheme = isBlockTheme
        super.init(noHandle: ThemesRequestExecutor.NoHandle())
    }

    required init(unsafeFromHandle handle: UInt64) {
        self.isBlockTheme = false
        super.init(unsafeFromHandle: handle)
    }

    override func listWithEditContextCancellation(params: ThemeListParams, context: RequestContext?) async throws -> ThemesRequestListWithEditContextResponse {
        let mockTheme = ThemeWithEditContext(
            stylesheet: ThemeStylesheet(value: "twentytwentyfour"),
            template: "twentytwentyfour",
            requiresPhp: "7.0",
            requiresWp: "6.4",
            textdomain: "twentytwentyfour",
            version: "1.0",
            screenshot: "",
            author: ThemeAuthor(raw: "WordPress", rendered: "WordPress"),
            authorUri: ThemeAuthorUri(raw: "", rendered: ""),
            description: ThemeDescription(raw: "", rendered: ""),
            name: ThemeName(raw: "Twenty Twenty-Four", rendered: "Twenty Twenty-Four"),
            tags: ThemeTags(raw: [], rendered: ""),
            themeUri: ThemeUri(raw: "", rendered: ""),
            status: .active,
            isBlockTheme: isBlockTheme,
            stylesheetUri: "",
            templateUri: "",
            themeSupports: nil,
            defaultTemplateTypes: nil
        )
        let mockHeaderMap = WpNetworkHeaderMap(noHandle: WpNetworkHeaderMap.NoHandle())
        return ThemesRequestListWithEditContextResponse(data: [mockTheme], headerMap: mockHeaderMap)
    }
}

final class MockWpApiDetails: WpApiDetails {
    private var routes: Set<String>

    init(routes: Set<String>) {
        self.routes = routes
        super.init(noHandle: WpApiDetails.NoHandle())
    }

    required init(unsafeFromHandle handle: UInt64) {
        self.routes = []
        super.init(unsafeFromHandle: handle)
    }

    override func hasRoute(route: String) -> Bool {
        routes.contains(route)
    }
}
