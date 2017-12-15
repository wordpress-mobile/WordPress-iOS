import Foundation

public struct PluginState: Equatable {
    public enum UpdateState: Equatable {
        public static func ==(lhs: PluginState.UpdateState, rhs: PluginState.UpdateState) -> Bool {
            switch (lhs, rhs) {
            case (.updated, .updated):
                return true
            case (.available(let lhsValue), .available(let rhsValue)):
                return lhsValue == rhsValue
            case (.updating(let lhsValue), .updating(let rhsValue)):
                return lhsValue == rhsValue
            default:
                return false
            }
        }

        case updated
        case available(String)
        case updating(String)
    }
    public let id: String
    public let slug: String
    public var active: Bool
    public let name: String
    public let version: String?
    public var updateState: UpdateState
    public var autoupdate: Bool
    public var automanaged: Bool
    public let url: URL?

    public static func ==(lhs: PluginState, rhs: PluginState) -> Bool {
        return lhs.id == rhs.id
            && lhs.slug == rhs.slug
            && lhs.active == rhs.active
            && lhs.name == rhs.name
            && lhs.version == rhs.version
            && lhs.updateState == rhs.updateState
            && lhs.autoupdate == rhs.autoupdate
            && lhs.automanaged == rhs.automanaged
            && lhs.url == rhs.url
    }
}

public extension PluginState {
    var stateDescription: String {
        if automanaged {
            return NSLocalizedString("Auto-managed on this site", comment: "The plugin can not be manually updated or deactivated")
        }
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
        return !isJetpack && !automanaged
    }

    var isJetpack: Bool {
        return slug == "jetpack"
            || slug == "jetpack-dev"
    }
}

