import Foundation
import WordPressAPI
import WordPressAPIInternal

public struct InstalledPlugin: Equatable, Hashable, Identifiable, Sendable {
    public var slug: PluginSlug
    public var name: String
    public var version: String
    public var author: String
    public var shortDescription: String
    public var status: PluginStatus
    public var networkOnly: Bool

    public var isActive: Bool {
        status == .active || status == .networkActive
    }

    public var id: String {
        slug.slug
    }

    init(plugin: PluginWithEditContext) {
        self.slug = plugin.plugin
        self.name = plugin.name
        self.version = plugin.version
        self.author = plugin.author
        self.shortDescription = plugin.description.raw
        self.status = plugin.status
        self.networkOnly = plugin.networkOnly
    }

    init(plugin: PluginWithViewContext) {
        self.slug = plugin.plugin
        self.name = plugin.name
        self.version = plugin.version
        self.author = plugin.author
        self.shortDescription = plugin.description.raw
        self.status = plugin.status
        self.networkOnly = plugin.networkOnly
    }

    public var possibleWpOrgDirectorySlug: PluginWpOrgDirectorySlug? {
        guard let maybeWpOrgSlug = slug.slug.split(separator: "/").first else { return nil }
        return .init(slug: String(maybeWpOrgSlug))
    }

    public var possibleWpOrgDirectoryURL: URL? {
        guard let slug = possibleWpOrgDirectorySlug else { return nil }
        return URL(string: "https://wordpress.org/plugins/\(slug.slug)/")
    }
}
