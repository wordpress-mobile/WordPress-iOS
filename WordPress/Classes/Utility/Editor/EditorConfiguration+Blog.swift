import Foundation
import GutenbergKit
import WordPressData
import WordPressShared

extension EditorConfiguration {
    init(blog: Blog, keychain: KeychainAccessible = KeychainUtils()) {
        let selfHostedApiUrl = blog.restApiRootURL ?? blog.url(withPath: "wp-json/")
        let applicationPassword = try? blog.getApplicationToken(using: keychain)
        let shouldUseWPComRestApi = applicationPassword == nil && blog.isAccessibleThroughWPCom()

        let siteApiRoot: String?
        if applicationPassword != nil {
            siteApiRoot = selfHostedApiUrl
        } else {
            siteApiRoot = shouldUseWPComRestApi ? blog.wordPressComRestApi?.baseURL.absoluteString : selfHostedApiUrl
        }

        let siteId = blog.dotComID?.stringValue
        let siteDomain = blog.primaryDomainAddress
        let authToken = blog.authToken ?? ""
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

        var builder = EditorConfigurationBuilder()
            .setSiteApiNamespace(siteApiNamespace)
            .setNamespaceExcludedPaths(["/wpcom/v2/following/recommendations", "/wpcom/v2/following/mine"])
            .setAuthHeader(authHeader)
            .setShouldUseThemeStyles(GutenbergSettings().isThemeStylesEnabled(for: blog))
            // Limited to Jetpack-connected sites until editor assets endpoint is available in WordPress core
            .setShouldUsePlugins(Self.shouldEnablePlugins(for: blog, appPassword: applicationPassword))
            .setLocale(WordPressComLanguageDatabase.shared.deviceLanguage.slug)

        if let blogUrl = blog.url {
            builder = builder.setSiteUrl(blogUrl)
        }

        if let siteApiRoot {
            builder = builder.setSiteApiRoot(siteApiRoot)

            if var editorAssetsEndpoint = URL(string: siteApiRoot) {
                editorAssetsEndpoint.appendPathComponent("wpcom/v2/")
                if let namespace = siteApiNamespace.first {
                    editorAssetsEndpoint.appendPathComponent(namespace)
                }

                editorAssetsEndpoint.appendPathComponent("editor-assets")
                builder = builder.setEditorAssetsEndpoint(editorAssetsEndpoint)
            }
        }

        self = builder.build()
    }

    /// Returns true if the plugins should be enabled for the given blog.
    /// This is used to determine if the editor should load third-party
    /// plugins providing blocks.
    static func shouldEnablePlugins(for blog: Blog, appPassword: String? = nil) -> Bool {
        // Requires a Jetpack until editor assets endpoint is available in WordPress core.
        // Requires a WP.com Simple site or an application password to authenticate all REST
        // API requests, including those originating from non-core blocks.
        return RemoteFeatureFlag.newGutenbergPlugins.enabled() &&
            blog.isAccessibleThroughWPCom() &&
            (blog.isHostedAtWPcom || appPassword != nil)
    }
}
