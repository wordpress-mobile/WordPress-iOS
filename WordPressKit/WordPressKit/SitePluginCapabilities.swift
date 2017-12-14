import Foundation

public struct SitePluginCapabilities: Equatable {
    public let modify: Bool
    public let autoupdate: Bool

    public static func ==(lhs: SitePluginCapabilities, rhs: SitePluginCapabilities) -> Bool {
        return lhs.modify == rhs.modify
            && lhs.autoupdate == rhs.autoupdate
    }
}
