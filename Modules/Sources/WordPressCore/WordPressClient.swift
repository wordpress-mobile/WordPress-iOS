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

    public init(api: WordPressAPI, rootUrl: ParsedUrl) {
        self.api = api
        self.rootUrl = rootUrl.url()
    }

    public func refreshCachedSiteInfo() async throws {
        let apiRoot = try await self.api.apiRoot.get()
        self.apiRoot = apiRoot.data
    }

    public func currentUserCan(_ capability: String) async throws -> Bool {
        false
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
