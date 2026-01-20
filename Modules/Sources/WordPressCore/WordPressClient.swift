import Foundation
import WordPressAPI
import WordPressAPIInternal

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

    public let api: WordPressAPI
    public let rootUrl: String

    private var loadSiteInfoTask: Task<(WpApiDetails, UserWithEditContext, ThemeWithEditContext?), Error>

    public init(api: WordPressAPI, rootUrl: ParsedUrl) {
        self.api = api
        self.rootUrl = rootUrl.url()

        self.loadSiteInfoTask = Task { [api] in
            async let apiRootTask = try await api.apiRoot.get().data
            async let currentUserTask = try await api.users.retrieveMeWithEditContext().data
            async let activeThemeTask = try await api.themes.listWithEditContext(
                params: ThemeListParams(status: .active)
            ).data.first(where: { $0.status == .active })

            return try await (apiRootTask, currentUserTask, activeThemeTask)
        }
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
        // Wait for the `loadSiteInfoTask` to finish the initial load then use that value
        return try await loadSiteInfoTask.value.0
    }

    private func fetchActiveTheme() async throws -> ThemeWithEditContext? {
        // Wait for the `loadSiteInfoTask` to finish the initial load then use that value
        return try await loadSiteInfoTask.value.2
    }
}
