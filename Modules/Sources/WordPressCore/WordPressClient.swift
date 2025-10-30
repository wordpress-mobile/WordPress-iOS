import Foundation
import WordPressAPI
import WordPressAPIInternal

public actor WordPressClient {

    public enum Feature {
        /// Theme styles allow us to style the editor
        case themeStyles

        /// Application Password Extras grants additional capabilities using Application Passwords
        case applicationPasswordExtras

        /// WordPress.com sites don't all support plugins
        case plugins
    }

    public let api: WordPressAPI
    public let rootUrl: String

    private var apiRoot: WpApiDetails? = nil
    private var currentUser: UserWithEditContext? = nil

    private var loadSiteInfoTask: Task<(WpApiDetails, UserWithEditContext), Error>

    public init(api: WordPressAPI, rootUrl: ParsedUrl) {
        self.api = api
        self.rootUrl = rootUrl.url()
        self.loadSiteInfoTask = Task { [api] in
            async let apiRootTask = try await api.apiRoot.get().data
            async let currentUserTask = try await api.users.retrieveMeWithEditContext().data

            return try await (apiRootTask, currentUserTask)
        }
    }

    public func currentUserCan(_ capability: UserCapability) async throws -> Bool {
        try await fetchCurrentUser().capabilities.keys.contains(capability)
    }

    private func fetchCurrentUser() async throws -> UserWithEditContext {
        // Wait for the `loadSiteInfoTask` to finish the initial load then use that value
        return try await loadSiteInfoTask.value.1
    }

    public func supports(_ feature: Feature, forSiteId siteId: Int? = nil) async throws -> Bool {
        let apiRoot = try await fetchApiRoot()

        if let siteId {
            return switch feature {
            case .themeStyles: apiRoot.hasRoute(route: "/wp-block-editor/v1/sites/\(siteId)/settings")
            case .plugins: apiRoot.hasRoute(route: "/wp/v2/plugins")
            case .applicationPasswordExtras: apiRoot.hasRoute(route: "/application-password-extras/v1/admin-ajax")
            }
        }

        return switch feature {
        case .themeStyles: apiRoot.hasRoute(route: "/wp-block-editor/v1/settings")
        case .plugins: apiRoot.hasRoute(route: "/wp/v2/plugins")
        case .applicationPasswordExtras: apiRoot.hasRoute(route: "/application-password-extras/v1/admin-ajax")
        }
    }

    private func fetchApiRoot() async throws -> WpApiDetails {
        // Wait for the `loadSiteInfoTask` to finish the initial load then use that value
        return try await loadSiteInfoTask.value.0
    }

    private func setApiRoot(_ newValue: WpApiDetails) {
        self.apiRoot = newValue
    }

    private func setCurrentUser(_ newValue: UserWithEditContext) {
        self.currentUser = newValue
    }
}
