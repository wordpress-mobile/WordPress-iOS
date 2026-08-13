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
        .setShouldUsePlugins(
            Self.shouldEnablePlugins(for: blog, appPassword: applicationPassword, keychain: keychain)
        )
        .setLocale(WordPressComLanguageDatabase.shared.deviceLanguage.slug)
        .setEnableNetworkLogging(ExtensiveLogging.enabled)
        .setNetworkFallbackMode(.automatic)

        // Build editor assets endpoint
        var editorAssetsEndpoint = siteApiRoot
        editorAssetsEndpoint.appendPathComponent("wpcom/v2/")
        if let namespace = siteApiNamespace.first {
            editorAssetsEndpoint.appendPathComponent(namespace)
        }
        editorAssetsEndpoint.appendPathComponent("editor-assets")
        builder = builder.setEditorAssetsEndpoint(editorAssetsEndpoint)

        self = builder.build()
    }

    /// Returns true if the plugins should be enabled for the given blog.
    /// This is used to determine if the editor should load third-party
    /// plugins providing blocks.
    ///
    /// Requires the remote feature flag, a site that can support the feature, and the user's
    /// per-site opt-in. See `GutenbergSettings.resolveThirdPartyBlocks(for:)`.
    static func shouldEnablePlugins(
        for blog: Blog,
        appPassword: String? = nil,
        settings: GutenbergSettings = GutenbergSettings(),
        keychain: KeychainAccessible = AppKeychain(),
        isFeatureFlagEnabled: Bool = RemoteFeatureFlag.newGutenbergPlugins.enabled()
    ) -> Bool {
        settings
            .resolveThirdPartyBlocks(
                for: blog,
                appPassword: appPassword,
                keychain: keychain,
                isFeatureFlagEnabled: isFeatureFlagEnabled
            )
            .shouldApplyInEditor
    }
}
