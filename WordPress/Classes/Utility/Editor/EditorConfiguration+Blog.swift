import Foundation
import GutenbergKit
import WordPressData
import WordPressShared
import Support

extension EditorConfiguration {
    init(blog: Blog, postType: PostTypeDetails, keychain: KeychainAccessible = AppKeychain()) {
        let selfHostedApiUrl = blog.restApiRootURL ?? blog.url(withPath: "wp-json/")
        let applicationPassword = try? blog.getApplicationToken(using: keychain)
        let shouldUseWPComRestApi = applicationPassword == nil && blog.isAccessibleThroughWPCom

        let siteApiRootString: String?
        if applicationPassword != nil {
            siteApiRootString = selfHostedApiUrl
        } else {
            siteApiRootString =
                shouldUseWPComRestApi ? blog.wordPressComRestApi?.baseURL.absoluteString : selfHostedApiUrl
        }

        let siteId = blog.dotComID?.stringValue
        let siteDomain = blog.primaryDomainAddress
        let authToken = blog.account?.authToken ?? ""
        var authHeader = "Bearer \(authToken)"

        if let appPassword = applicationPassword, let username = blog.username {
            let credentials = "\(username):\(appPassword)"
            if let credentialsData = credentials.data(using: .utf8) {
                let base64Credentials = credentialsData.base64EncodedString()
                authHeader = "Basic \(base64Credentials)"
            }
        }

        // Must provide both namespace forms to detect usages of both forms in third-party code
        var siteApiNamespace: [String] = []
        if shouldUseWPComRestApi {
            if let siteId {
                siteApiNamespace.append("sites/\(siteId)/")
            }
            siteApiNamespace.append("sites/\(siteDomain)/")
        }

        // Convert to URL types (required by new GutenbergKit API)
        let siteURL = blog.url.flatMap { URL(string: $0) } ?? URL(string: "https://example.com")!
        let siteApiRoot = siteApiRootString.flatMap { URL(string: $0) } ?? URL(string: "https://example.com/wp-json")!

        var builder = EditorConfigurationBuilder(
            postType: postType,
            siteURL: siteURL,
            siteApiRoot: siteApiRoot
        )
        .setSiteApiNamespace(siteApiNamespace)
        .setNamespaceExcludedPaths(["/wpcom/v2/following/recommendations", "/wpcom/v2/following/mine"])
        .setAuthHeader(authHeader)
        .setShouldUseThemeStyles(GutenbergSettings().isThemeStylesEnabled(for: blog))
        // Limited to Jetpack-connected sites until editor assets endpoint is available in WordPress core
        .setShouldUsePlugins(Self.shouldEnablePlugins(for: blog, appPassword: applicationPassword))
        .setLocale(WordPressComLanguageDatabase.shared.deviceLanguage.slug)
        .setEnableNetworkLogging(ExtensiveLogging.enabled)
        .setNetworkFallbackMode(.automatic)

        // Build editor assets endpoint
        let namespacePath = siteApiNamespace.first.map { $0.hasSuffix("/") ? $0 : $0 + "/" } ?? ""
        builder = builder.setEditorAssetsEndpoint(
            Self.appendingRESTPath("wpcom/v2/\(namespacePath)editor-assets", to: siteApiRoot)
        )

        self = builder.build()
    }

    /// Appends a REST API path to a site's API root.
    ///
    /// Sites using plain permalinks have no path-based REST root — WordPress advertises the
    /// query form `https://example.com/?rest_route=/` instead — so the path belongs in the
    /// `rest_route` value rather than the URL path:
    ///
    /// ```
    /// https://example.com/?rest_route=/ + wpcom/v2/editor-assets
    ///     -> https://example.com/?rest_route=/wpcom/v2/editor-assets
    /// ```
    ///
    /// Path-based roots keep the usual behavior. This mirrors `@wordpress/api-fetch`'s root URL
    /// middleware and GutenbergKit's native URL builders, so every layer resolves the same
    /// endpoints for a given site.
    ///
    /// - Parameters:
    ///   - path: The REST path to append, without a leading slash.
    ///   - apiRoot: The site's REST API root.
    /// - Returns: The endpoint URL, or `apiRoot` unchanged if the result isn't a valid URL.
    static func appendingRESTPath(_ path: String, to apiRoot: URL) -> URL {
        // Concatenate onto the root's full string rather than appending path components, so a
        // query-based root grows its `rest_route` value instead of stranding it behind the path.
        // One slash is kept between the two whether the root ends in `wp-json/`, `wp-json`,
        // `?rest_route=/`, or `?rest_route=`.
        let root = apiRoot.absoluteString
        let separator = root.hasSuffix("/") ? "" : "/"
        return URL(string: root + separator + path) ?? apiRoot
    }

    /// Returns true if the plugins should be enabled for the given blog.
    /// This is used to determine if the editor should load third-party
    /// plugins providing blocks.
    static func shouldEnablePlugins(for blog: Blog, appPassword: String? = nil) -> Bool {
        // Requires a Jetpack until editor assets endpoint is available in WordPress core.
        // Requires a WP.com Simple site or an application password to authenticate all REST
        // API requests, including those originating from non-core blocks.
        RemoteFeatureFlag.newGutenbergPlugins.enabled() && blog.isAccessibleThroughWPCom
            && (blog.isHostedAtWPcom || appPassword != nil)
    }
}
