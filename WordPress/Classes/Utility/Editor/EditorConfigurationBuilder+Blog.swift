import Foundation
import GutenbergKit
import WordPressData
import WordPressShared

extension EditorConfigurationBuilder {
    init(blog: Blog) {
        let selfHostedApiUrl = blog.restApiRootURL ?? blog.url(withPath: "wp-json/")
        let isWPComSite = blog.isHostedAtWPcom || blog.isAtomic()
        let siteApiRoot = blog.isAccessibleThroughWPCom() && isWPComSite ? blog.wordPressComRestApi?.baseURL.absoluteString : selfHostedApiUrl
        let siteId = blog.dotComID?.stringValue
        let siteDomain = blog.primaryDomainAddress
        let authToken = blog.authToken ?? ""
        var authHeader = "Bearer \(authToken)"

        let applicationPassword = try? blog.getApplicationToken()

        if let appPassword = applicationPassword, let username = blog.username {
            let credentials = "\(username):\(appPassword)"
            if let credentialsData = credentials.data(using: .utf8) {
                let base64Credentials = credentialsData.base64EncodedString()
                authHeader = "Basic \(base64Credentials)"
            }
        }

        // Must provide both namespace forms to detect usages of both forms in third-party code
        var siteApiNamespace: [String] = []
        if isWPComSite {
            if let siteId {
                siteApiNamespace.append("sites/\(siteId)/")
            }
            siteApiNamespace.append("sites/\(siteDomain)/")
        }

        self = EditorConfigurationBuilder()
            .setSiteUrl(blog.url ?? "")
            .setSiteApiRoot(siteApiRoot ?? "")
            .setSiteApiNamespace(siteApiNamespace)
            .setNamespaceExcludedPaths(["/wpcom/v2/following/recommendations", "/wpcom/v2/following/mine"])
            .setAuthHeader(authHeader)
            .setShouldUseThemeStyles(FeatureFlag.newGutenbergThemeStyles.enabled)

        // Limited to Simple sites until application password auth is supported
        if RemoteFeatureFlag.newGutenbergPlugins.enabled() && blog.isHostedAtWPcom {
            self = self.setShouldUsePlugins(true)
            if var editorAssetsEndpoint = blog.wordPressComRestApi?.baseURL {
                editorAssetsEndpoint.appendPathComponent("wpcom/v2/sites")
                if let siteId {
                    editorAssetsEndpoint.appendPathComponent(siteId)
                } else {
                    editorAssetsEndpoint.appendPathComponent(siteDomain)
                }
                editorAssetsEndpoint.appendPathComponent("editor-assets")
                self = self.setEditorAssetsEndpoint(editorAssetsEndpoint)
            }
        }
        self = self.setLocale(WordPressComLanguageDatabase().deviceLanguage.slug)
    }
}
