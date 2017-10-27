import Foundation

public struct PluginState {
    public let id: String
    public let slug: String
    public var active: Bool
    public let name: String
    public let version: String?
    public var autoupdate: Bool
    public let url: URL?
}

public extension PluginState {
    var stateDescription: String {
        switch (active, autoupdate) {
        case (false, false):
            return NSLocalizedString("Inactive, Autoupdates off", comment: "The plugin is not active on the site and has not enabled automatic updates")
        case (false, true):
            return NSLocalizedString("Inactive, Autoupdates on", comment: "The plugin is not active on the site and has enabled automatic updates")
        case (true, false):
            return NSLocalizedString("Active, Autoupdates off", comment: "The plugin is active on the site and has not enabled automatic updates")
        case (true, true):
            return NSLocalizedString("Active, Autoupdates on", comment: "The plugin is active on the site and has enabled automatic updates")
        }
    }

    var homeURL: URL? {
        return url
    }

    @available(*, unavailable, message: "Don't use until we can figure out if the plugin is in the WordPress.org directory")
    var directoryURL: URL {
        return URL(string: "https://wordpress.org/plugins/\(slug)")!
    }

    var deactivateAllowed: Bool {
        return !isJetpack
    }

    var isJetpack: Bool {
        return slug == "jetpack"
            || slug == "jetpack-dev"
    }
}
