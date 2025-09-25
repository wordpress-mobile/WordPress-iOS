import Foundation
import WordPressAPI
import WordPressAPIInternal

public actor WordPressClient {

    public enum Feature {
        case themeStyles
        case applicationPasswordExtras
        case managePlugins
    }

    public let api: WordPressAPI
    public let rootUrl: String

    private var apiRoot: WpApiDetails?
    private var currentUser: UserWithEditContext?

    public init(api: WordPressAPI, rootUrl: ParsedUrl) {
        self.api = api
        self.rootUrl = rootUrl.url()
    }

    public func refreshCachedSiteInfo() async throws {
        async let apiRootTask = try await self.api.apiRoot.get().data
        async let currentUserTask = try await self.api.users.retrieveMeWithEditContext().data

        let (apiRoot, currentUser) = try await (apiRootTask, currentUserTask)

        self.apiRoot = apiRoot
        self.currentUser = currentUser
    }

    public func currentUserCan(_ capability: UserCapability) async throws -> Bool {
        try await fetchCurrentUser().capabilities.keys.contains(capability)
    }

    private func fetchCurrentUser() async throws -> UserWithEditContext {
        if let currentUser = self.currentUser {
            return currentUser
        }

        let currentUser = try await self.api.users.retrieveMeWithEditContext().data
        self.currentUser = currentUser
        return currentUser
    }

    public func supports(_ feature: Feature, forSiteId siteId: Int? = nil) async throws -> Bool {
        let apiRoot = try await fetchApiRoot()

        if let siteId {
            return switch feature {
            case .themeStyles: apiRoot.hasRoute(route: "/wp-block-editor/v1/sites/\(siteId)/settings")
            case .managePlugins: apiRoot.hasRoute(route: "/wp/v2/plugins")
            case .applicationPasswordExtras: apiRoot.hasRoute(route: "/application-password-extras/v1/admin-ajax")
            }
        }

        return switch feature {
        case .themeStyles: apiRoot.hasRoute(route: "/wp-block-editor/v1/settings")
        case .managePlugins: apiRoot.hasRoute(route: "/wp/v2/plugins")
        case .applicationPasswordExtras: apiRoot.hasRoute(route: "/application-password-extras/v1/admin-ajax")
        }
    }

    private func fetchApiRoot() async throws -> WpApiDetails {
        if let apiRoot = self.apiRoot {
            return apiRoot
        }
        let apiRoot = try await self.api.apiRoot.get()
        self.apiRoot = apiRoot.data
        return apiRoot.data
    }
}
