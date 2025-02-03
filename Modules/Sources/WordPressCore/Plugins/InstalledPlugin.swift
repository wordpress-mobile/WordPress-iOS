import Foundation
import WordPressAPI

public struct InstalledPlugin: Equatable, Hashable, Identifiable, Sendable {
    public var slug: PluginSlug
    public var iconURL: URL?
    public var name: String
    public var version: String
    public var author: String
    public var shortDescription: String
    public var isActive: Bool

    public init(slug: PluginSlug, iconURL: URL?, name: String, version: String, author: String, shortDescription: String, isActive: Bool) {
        self.slug = slug
        self.iconURL = iconURL
        self.name = name
        self.version = version
        self.author = author
        self.shortDescription = shortDescription
        self.isActive = isActive
    }

    public init(plugin: PluginWithViewContext) {
        self.slug = plugin.plugin
        iconURL = nil
        name = plugin.name
        version = plugin.version
        author = plugin.author
        shortDescription = plugin.description.raw
        isActive = plugin.status == .active || plugin.status == .networkActive
    }

    public init(plugin: PluginWithEditContext) {
        self.slug = plugin.plugin
        iconURL = nil
        name = plugin.name
        version = plugin.version
        author = plugin.author
        shortDescription = plugin.description.raw
        isActive = plugin.status == .active || plugin.status == .networkActive
    }

    public var id: String {
        slug.slug
    }

    public var possibleWpOrgDirectorySlug: PluginWpOrgDirectorySlug? {
        guard let maybeWpOrgSlug = slug.slug.split(separator: "/").first else { return nil }
        return .init(slug: String(maybeWpOrgSlug))
    }
}
