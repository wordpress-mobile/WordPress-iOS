import Foundation

public struct RecommendedPlugin: Codable, Sendable {

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
