import Foundation

public struct PluginState {
    public let slug: String
    public let active: Bool
    public let name: String
    public let version: String?
    public let autoupdate: Bool
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
}
