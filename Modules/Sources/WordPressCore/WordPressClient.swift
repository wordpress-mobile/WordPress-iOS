import Foundation
import WordPressAPI
import WordPressAPIInternal
import WordPressApiCache

/// Protocol defining the WordPress API methods that WordPressClient needs.
/// This abstraction allows for mocking in tests using the `NoHandle` constructors
/// available on the executor classes.
public protocol WordPressClientAPI: Sendable {
    var apiRoot: ApiRootRequestExecutor { get }
    var users: UsersRequestExecutor { get }
    var themes: ThemesRequestExecutor { get }
    var plugins: PluginsRequestExecutor { get }
    var comments: CommentsRequestExecutor { get }
    var media: MediaRequestExecutor { get }
    var taxonomies: TaxonomiesRequestExecutor { get }
    var terms: TermsRequestExecutor { get }
    var applicationPasswords: ApplicationPasswordsRequestExecutor { get }
    var posts: PostsRequestExecutor { get }

    func createSelfHostedService(cache: WordPressApiCache) throws -> WpSelfHostedService

    func uploadMedia(
        params: MediaCreateParams,
        fulfilling progress: Progress
    ) async throws -> MediaRequestCreateResponse
}

/// WordPressAPI already has these properties with the correct types,
/// so conformance is automatic.
extension WordPressAPI: WordPressClientAPI {}

/// A client for interacting with the WordPress REST API.
///
/// `WordPressClient` provides a high-level interface for making WordPress API requests with
/// built-in caching of commonly-accessed data like site info, current user, and active theme.
/// It is implemented as an actor to ensure thread-safe access to its internal cache state.
public actor WordPressClient {

    /// Features that a WordPress site may or may not support.
    ///
    /// Use these values with ``supports(_:forSiteId:)`` to check if a site
    /// has the necessary capabilities for specific functionality.
    public enum Feature {
        /// A block theme is required to style the editor.
        case blockTheme

        /// The block editor settings API is required to style the editor.
        case blockEditorSettings

        /// Application Password Extras grants additional capabilities using Application Passwords.
        case applicationPasswordExtras

        /// WordPress.com sites don't all support plugins.
        case plugins

        /// A string representation of the feature for use in API queries or logging.
        public var stringValue: String {
            switch self {
            case .blockTheme: "is-block-theme"
            case .blockEditorSettings: "block-editor-settings"
            case .applicationPasswordExtras: "application-password-extras"
            case .plugins: "plugins"
            }
        }
    }

    /// Errors that can occur when accessing cached client data.
    public enum ClientCacheError: Swift.Error {
        /// No active theme was found for the site.
        ///
        /// This typically indicates an unexpected server state, as WordPress sites
        /// should always have exactly one active theme.
        case noActiveTheme
    }

    public let siteURL: URL

    /// The underlying API executor used for making network requests.
    public let api: any WordPressClientAPI

    private var _cache: WordPressApiCache?
    public var cache: WordPressApiCache {
        get {
            if let _cache {
                return _cache
            }
            let cache = WordPressApiCache.bootstrap()
            _cache = cache
            return cache
        }
    }

    private var _service: WpSelfHostedService?
    public var service: WpSelfHostedService {
        get throws {
            if let _service {
                return _service
            }
            let service = try api.createSelfHostedService(cache: cache)
            _service = service
            return service
        }
    }

    /// The cached task for fetching site API details.
    private var loadSiteInfoTask: Task<WpApiDetails, Error>

    /// The cached task for fetching the current authenticated user.
    private var loadCurrentUserTask: Task<UserWithEditContext, Error>

    /// The cached task for fetching the site's active theme.
    private var loadActiveThemeTask: Task<ThemeWithEditContext, Error>

    /// Creates a new WordPress client for the specified site.
    ///
    /// Upon initialization, the client automatically begins fetching and caching site info,
    /// the current user, and the active theme in parallel. These cached values are used
    /// by subsequent API calls to avoid redundant network requests.
    ///
    /// - Parameters:
    ///   - api: The API executor to use for network requests.
    ///   - siteURL: The parsed root URL of the WordPress site.
    public init(api: WordPressClientAPI, siteURL: URL) {
        self.api = api
        self.siteURL = siteURL

        // These tasks need to be manually restated here because we can't use the task constructors
        self.loadSiteInfoTask = Task { try await api.apiRoot.get().data }
        self.loadCurrentUserTask = Task { try await api.users.retrieveMeWithEditContext().data }
        self.loadActiveThemeTask = Task {
            let query = ThemeListParams(status: .active)

            guard let activeTheme = try await api.themes.listWithEditContext(params: query).data.first else {
                throw ClientCacheError.noActiveTheme
            }

            return activeTheme
        }
    }

    /// Invalidates all cached data and triggers a fresh fetch from the server.
    ///
    /// Call this method when you need to ensure the client has the latest data from the server,
    /// such as after the user makes changes that affect site settings, theme, or user profile.
    /// This clears the cached site info, current user, and active theme, then initiates new
    /// background fetches for each.
    public func refresh() {
        loadSiteInfoTask = self.newSiteInfoTask()
        loadCurrentUserTask = self.newCurrentUserTask()
        loadActiveThemeTask = self.newActiveThemeTask()
    }

    /// Checks whether the WordPress site supports a given feature.
    ///
    /// This method queries the site's API root to determine if specific REST API routes
    /// are available, and checks theme capabilities where relevant.
    ///
    /// - Parameters:
    ///   - feature: The feature to check support for.
    ///   - siteId: An optional site ID for WordPress.com multi-site configurations.
    ///             When provided, uses site-specific API routes for feature detection.
    /// - Returns: `true` if the feature is supported, `false` otherwise.
    /// - Throws: An error if the API root or active theme cannot be fetched.
    public func supports(_ feature: Feature, forSiteId siteId: Int? = nil) async throws -> Bool {
        let apiRoot = try await fetchApiRoot()
        let isBlockTheme = try await fetchActiveTheme().isBlockTheme

        if let siteId {
            return switch feature {
            case .blockEditorSettings: apiRoot.hasRoute(route: "/wp-block-editor/v1/sites/\(siteId)/settings")
            case .blockTheme: isBlockTheme
            case .plugins: apiRoot.hasRoute(route: "/wp/v2/plugins")
            case .applicationPasswordExtras: apiRoot.hasRoute(route: "/application-password-extras/v1/admin-ajax")
            }
        }

        return switch feature {
        case .blockEditorSettings: apiRoot.hasRoute(route: "/wp-block-editor/v1/settings")
        case .blockTheme: isBlockTheme
        case .plugins: apiRoot.hasRoute(route: "/wp/v2/plugins")
        case .applicationPasswordExtras: apiRoot.hasRoute(route: "/application-password-extras/v1/admin-ajax")
        }
    }

    /// Fetches the site's API root details, using the cached value if available.
    ///
    /// If the cached task has failed, creates a new task and retries the fetch.
    /// This ensures transient network failures don't permanently block API access.
    ///
    /// - Returns: The site's API details including available routes and namespaces.
    private func fetchApiRoot() async throws -> WpApiDetails {
        switch await self.loadSiteInfoTask.result {
        case .success(let details): return details
        case .failure:
            self.loadSiteInfoTask = newSiteInfoTask()
            return try await self.loadSiteInfoTask.value
        }
    }

    /// Fetches the site's active theme, using the cached value if available.
    ///
    /// If the cached task has failed, creates a new task and retries the fetch.
    ///
    /// - Returns: The currently active theme with edit context.
    private func fetchActiveTheme() async throws -> ThemeWithEditContext {
        switch await self.loadActiveThemeTask.result {
        case .success(let theme): return theme
        case .failure:
            self.loadActiveThemeTask = newActiveThemeTask()
            return try await self.loadActiveThemeTask.value
        }
    }

    /// Fetches the current authenticated user, using the cached value if available.
    ///
    /// If the cached task has failed, creates a new task and retries the fetch.
    ///
    /// - Returns: The current user with edit context.
    private func fetchCurrentUser() async throws -> UserWithEditContext {
        switch await self.loadCurrentUserTask.result {
        case .success(let user): return user
        case .failure:
            self.loadCurrentUserTask = newCurrentUserTask()
            return try await self.loadCurrentUserTask.value
        }
    }

    /// Creates a new task to fetch the site's API root details from the server.
    ///
    /// - Returns: A task that resolves to the site's API details.
    private func newSiteInfoTask() -> Task<WpApiDetails, Error> {
        Task {
            try await api.apiRoot.get().data
        }
    }

    /// Creates a new task to fetch the current authenticated user from the server.
    ///
    /// - Returns: A task that resolves to the current user with edit context.
    private func newCurrentUserTask() -> Task<UserWithEditContext, Error> {
        Task {
            try await api.users.retrieveMeWithEditContext().data
        }
    }

    /// Creates a new task to fetch the site's active theme from the server.
    ///
    /// - Returns: A task that resolves to the active theme with edit context.
    /// - Throws: ``ClientCacheError/noActiveTheme`` if no active theme is found.
    private func newActiveThemeTask() -> Task<ThemeWithEditContext, Error> {
        Task {
            let params = ThemeListParams(status: .active)

            // There should only ever be one active theme for a site
            guard let theme = try await api.themes.listWithEditContext(params: params).data.first else {
                throw ClientCacheError.noActiveTheme
            }

            return theme
        }
    }
}
