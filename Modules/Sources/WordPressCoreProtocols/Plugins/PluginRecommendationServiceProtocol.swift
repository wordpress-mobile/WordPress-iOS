import Foundation

public enum PluginRecommendationFeature: CaseIterable {
    case themeStyles
    case postPreviews
    case editorCompatibility

    public var explanation: String {
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

    public var successMessage: String {
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

    public var helpArticleUrl: URL {
        // TODO: We need to write these articles and update the URLs
        let url = switch self {
            case .themeStyles: "https://wordpress.com/support/plugins/install-a-plugin/"
            case .postPreviews: "https://wordpress.com/support/plugins/install-a-plugin/"
            case .editorCompatibility: "https://wordpress.com/support/plugins/install-a-plugin/"
        }

        return URL(string: url)!
    }

    public var recommendedPlugin: String {
        switch self {
            case .themeStyles: "gutenberg"
            case .postPreviews: "jetpack"
            case .editorCompatibility: "jetpack"
        }
    }
}

public enum PluginRecommendationFrequency {
    case daily
    case weekly
    case monthly

    public var timeInterval: TimeInterval {
        return switch self {
        case .daily: 86_400
        case .weekly: 604_800
        case .monthly: 14_515_200
        }
    }
}

public protocol PluginRecommendationServiceProtocol: Actor {
    func recommendedPluginSlug(for feature: PluginRecommendationFeature) async throws -> String
    func recommendPlugin(for feature: PluginRecommendationFeature) async throws -> RecommendedPlugin
    func shouldRecommendPlugin(
        for feature: PluginRecommendationFeature,
        frequency: PluginRecommendationFrequency
    ) -> Bool

    func displayedRecommendation(for feature: PluginRecommendationFeature, at date: Date)
    func resetRecommendations()
}
