import Foundation
import WordPressAPI
import WordPressAPIInternal

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

    func uploadMedia(
        params: MediaCreateParams,
        fulfilling progress: Progress
    ) async throws -> MediaRequestCreateResponse
}

/// WordPressAPI already has these properties with the correct types,
/// so conformance is automatic.
extension WordPressAPI: WordPressClientAPI {}

public actor WordPressClient {

    public enum Feature {
        /// A block theme is required to style the editor.
        case blockTheme

        /// The block editor settings API is required to style the editor.
        case blockEditorSettings

        /// Application Password Extras grants additional capabilities using Application Passwords.
        case applicationPasswordExtras

        /// WordPress.com sites don't all support plugins.
        case plugins

        public var stringValue: String {
            switch self {
            case .blockTheme: "is-block-theme"
            case .blockEditorSettings: "block-editor-settings"
            case .applicationPasswordExtras: "application-password-extras"
            case .plugins: "plugins"
            }
        }
    }

    public let api: any WordPressClientAPI
    public let rootUrl: String

    private var loadSiteInfoTask: Task<WpApiDetails, Error>
    private var loadCurrentUserTask: Task<UserWithEditContext, Error>
    private var loadActiveThemeTask: Task<ThemeWithEditContext?, Error>

    public init(api: any WordPressClientAPI, rootUrl: ParsedUrl) {
        self.api = api
        self.rootUrl = rootUrl.url()

        // These tasks need to be manually restated here because we can't use the task constructors
        self.loadSiteInfoTask = Task { try await api.apiRoot.get().data }
        self.loadCurrentUserTask = Task { try await api.users.retrieveMeWithEditContext().data }
        self.loadActiveThemeTask = Task { try await api.themes.listWithEditContext(params: ThemeListParams(status: .active)).data.first }
    }

    /// Invalidates all cached data and triggers a fresh fetch from the server.
    public func refresh() {
        loadSiteInfoTask = self.newSiteInfoTask()
        loadCurrentUserTask = self.newCurrentUserTask()
        loadActiveThemeTask = self.newActiveThemeTask()
    }

    public func supports(_ feature: Feature, forSiteId siteId: Int? = nil) async throws -> Bool {
        let apiRoot = try await fetchApiRoot()
        let isBlockTheme: Bool = try await fetchActiveTheme()?.isBlockTheme ?? false

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

    /// Asynchronously read the site's API details. This value is cached internally.
    ///
    private var apiRoot: WpApiDetails {
        get async throws {
            try await self.fetchApiRoot()
        }
    }

    private func fetchApiRoot() async throws -> WpApiDetails {
        switch await self.loadSiteInfoTask.result {
        case .success(let details): return details
        case .failure(let error):
            self.loadSiteInfoTask = newSiteInfoTask()
            throw error
        }
    }

    private func fetchActiveTheme() async throws -> ThemeWithEditContext? {
        switch await self.loadActiveThemeTask.result {
        case .success(let theme): return theme
        case .failure(let error):
            self.loadActiveThemeTask = newActiveThemeTask()
            throw error
        }
    }

    private func fetchCurrentUser() async throws -> UserWithEditContext {
        switch await self.loadCurrentUserTask.result {
        case .success(let user): return user
        case .failure(let error):
            self.loadCurrentUserTask = newCurrentUserTask()
            throw error
        }
    }

    private nonisolated func newSiteInfoTask() -> Task<WpApiDetails, Error> {
        Task {
            try await api.apiRoot.get().data
        }
    }

    private nonisolated func newCurrentUserTask() -> Task<UserWithEditContext, Error> {
        Task {
            try await api.users.retrieveMeWithEditContext().data
        }
    }

    private nonisolated func newActiveThemeTask() -> Task<ThemeWithEditContext?, Error> {
        Task {
            try await api.themes.listWithEditContext(params: ThemeListParams(status: .active)).data.first
        }
    }
}
