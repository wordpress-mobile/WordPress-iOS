import Foundation

public struct PluginState {
    public let id: String
    public let slug: String
    public let active: Bool
    public let name: String
    public let version: String?
    public let autoupdate: Bool
}
