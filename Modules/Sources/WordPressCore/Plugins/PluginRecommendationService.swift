import Foundation
import WordPressAPI
import WordPressAPIInternal

public struct RecommendedPlugin {

    /// The plugin name – this will be inserted into headers and buttons
    public let name: String

    /// The plugin slug – this is its identifier in the WordPress.org Plugins Directory
    public let slug: String

    /// An explanation of what you're asking the user to do.
    ///
    /// For example:
    /// - Gutenberg Required
    /// - Install Jetpack for a better experience
    public let usageTitle: String

    /// An explanation for how installing this plugin will help the user.
    ///
    /// This is _not_ the plugin's description from the WP.org directory.
    public let usageDescription: String

    /// An explanation for the new capabilities the user has because this plugin was installed.
    public let successMessage: String

    /// The banner image for this plugin
    public let imageUrl: URL?

    /// URL to a help article explaining why this is needed
    public let helpUrl: URL

    public init(
        name: String,
        slug: String,
        usageTitle: String,
        usageDescription: String,
        successMessage: String,
        imageUrl: URL?,
        helpUrl: URL
    ) {
        self.name = name
        self.slug = slug
        self.usageTitle = usageTitle
        self.usageDescription = usageDescription
        self.successMessage = successMessage
        self.imageUrl = imageUrl
        self.helpUrl = helpUrl
    }
}

public actor PluginRecommendationService {

    public enum Feature: CaseIterable {
        case themeStyles
        case postPreviews
        case editorCompatibility

        var explanation: String {
            switch self {
            case .themeStyles: NSLocalizedString(
                "org.wordpress.plugin-recommendations.explanations.gutenberg-for-theme-styles",
                value: "The Gutenberg Plugin is required to use your theme's styles in the editor.",
                comment: "A short message explaining why we're recommending this plugin"
            )
            case .postPreviews: NSLocalizedString(
                "org.wordpress.plugin-recommendations.explanations.jetpack-for-post-previews",
                value: "The Jetpack Plugin is required for post previews.",
                comment: "A short message explaining why we're recommending this plugin"
            )
            case .editorCompatibility: NSLocalizedString(
                "org.wordpress.plugin-recommendations.explanations.jetpack-for-editor-compatibility",
                value: "The Jetpack Plugin improves compatibility with plugins that provide blocks.",
                comment: "A short message explaining why we're recommending this plugin"
            )
            }
        }

        var successMessage: String {
            return switch self {
            case .themeStyles: NSLocalizedString(
                "org.wordpress.plugin-recommendations.success.theme-styles",
                value: "The editor will now display content exactly how it appears on your site.",
                comment: "A short message explaining what the user can do now that they've installed this plugin"
            )
            case .postPreviews: NSLocalizedString(
                "org.wordpress.plugin-recommendations.success.post-previews",
                value: "You can now preview posts within the app.",
                comment: "A short message explaining what the user can do now that they've installed this plugin"
            )
            case .editorCompatibility: NSLocalizedString(
                "org.wordpress.plugin-recommendations.success.editor-compatibility",
                value: "Your blocks will render correctly in the editor.",
                comment: "A short message explaining what the user can do now that they've installed this plugin"
            )
            }
        }

        var helpArticleUrl: URL {
            // TODO: We need to write these articles and update the URLs
            let url = switch self {
                case .themeStyles: "https://wordpress.com/support/plugins/install-a-plugin/"
                case .postPreviews: "https://wordpress.com/support/plugins/install-a-plugin/"
                case .editorCompatibility: "https://wordpress.com/support/plugins/install-a-plugin/"
            }

            return URL(string: url)!
        }

        var recommendedPlugin: PluginWpOrgDirectorySlug {
            let slug = switch self {
                case .themeStyles: "gutenberg"
                case .postPreviews: "jetpack"
                case .editorCompatibility: "jetpack"
            }

            return PluginWpOrgDirectorySlug(slug: slug)
        }

        fileprivate var cacheKey: String {
            return "plugin-recommendation-\(self)-\(recommendedPlugin.slug)"
        }
    }

    public enum Frequency {
        case daily
        case weekly
        case monthly

        var timeInterval: TimeInterval {
            return switch self {
            case .daily: 86_400
            case .weekly: 604_800
            case .monthly: 14_515_200
            }
        }
    }

    private let dotOrgClient: WordPressOrgApiClient
    private let userDefaults: UserDefaults

    public init(
        dotOrgClient: WordPressOrgApiClient = WordPressOrgApiClient(urlSession: .shared),
        userDefaults: UserDefaults = .standard
    ) {
        self.dotOrgClient = dotOrgClient
        self.userDefaults = userDefaults
    }

    public func recommendedPluginSlug(for feature: Feature) async throws -> PluginWpOrgDirectorySlug {
        feature.recommendedPlugin
    }

    public func recommendPlugin(for feature: Feature) async throws -> RecommendedPlugin {
        let plugin = try await dotOrgClient.pluginInformation(slug: feature.recommendedPlugin)

        return RecommendedPlugin(
            name: plugin.name,
            slug: plugin.slug.slug,
            usageTitle: "Install \(plugin.name)",
            usageDescription: feature.explanation,
            successMessage: feature.successMessage,
            imageUrl: try await cachePluginHeader(for: plugin),
            helpUrl: feature.helpArticleUrl
        )
    }

    public func shouldRecommendPlugin(for feature: Feature, frequency: Frequency) -> Bool {
        let featureTimestamp = self.userDefaults.double(forKey: feature.cacheKey)
        let globalTimestamp = self.userDefaults.double(forKey: "plugin-last-recommended")

        if featureTimestamp == 0 && globalTimestamp == 0 {
            return true
        }

        let earliestFeatureDate = Date().timeIntervalSince1970 - frequency.timeInterval
        let earliestGlobalDate = Date().timeIntervalSince1970 - 86_400

        return earliestFeatureDate > featureTimestamp && earliestGlobalDate > globalTimestamp
    }

    public func didRecommendPlugin(for feature: Feature, at date: Date = Date()) {
        self.userDefaults.set(date.timeIntervalSince1970, forKey: feature.cacheKey)
        self.userDefaults.set(date.timeIntervalSince1970, forKey: "plugin-last-recommended")
    }

    public func resetRecommendations() {
        for feature in Feature.allCases {
            self.userDefaults.removeObject(forKey: feature.cacheKey)
        }
        self.userDefaults.removeObject(forKey: "plugin-last-recommended")
    }

    private func cachePluginHeader(for plugin: PluginInformation) async throws -> URL? {
        guard let pluginUrl = plugin.bannerUrl, let bannerFileName = plugin.bannerFileName else {
            return nil
        }

        let cachePath = self.storagePath(for: plugin, filename: bannerFileName)
        return try await cacheAsset(pluginUrl, at: cachePath)
    }

    private func cacheAsset(_ url: URL, at path: URL) async throws -> URL {
        if FileManager.default.fileExists(at: path) {
            return path
        }

        let (tempPath, _) = try await URLSession.shared.download(from: url)
        try FileManager.default.moveItem(at: tempPath, to: path)

        return path
    }

    private func storagePath(for plugin: PluginInformation, filename: String) -> URL {
        URL.cachesDirectory
            .appendingPathComponent("plugin-assets")
            .appendingPathComponent(plugin.slug.slug)
            .appendingPathComponent(filename)
    }
}

fileprivate extension PluginInformation {
    var bannerFileName: String? {
        bannerUrl?.lastPathComponent
    }

    var bannerUrl: URL? {
        URL(string: self.banners.high)
    }
}
