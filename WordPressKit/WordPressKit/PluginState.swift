import Foundation

public struct PluginState {
    public let id: String
    public let slug: String
    public let active: Bool
    public let name: String
    public let version: String?
    public let autoupdate: Bool
}

public extension PluginState {
    var stateDescription: String {
        switch (active, autoupdate) {
        case (false, _):
            return NSLocalizedString("Inactive", comment: "A plugin is not active on the site")
        case (true, false):
            return NSLocalizedString("Active, Autoupdates off", comment: "A plugin is active on the site and has not enabled automatic updates")
        case (true, true):
            return NSLocalizedString("Active, Autoupdates on", comment: "A plugin is active on the site and has enabled automatic updates")
        }
    }
}
