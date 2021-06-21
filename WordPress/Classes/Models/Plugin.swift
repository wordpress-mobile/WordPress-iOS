import Foundation

struct Plugin: Equatable {
    let state: PluginState
    var directoryEntry: PluginDirectoryEntry?

    var id: String {
        return state.id
    }

    var name: String {
        return state.name
    }

    static func ==(lhs: Plugin, rhs: Plugin) -> Bool {
        return lhs.state == rhs.state
            && lhs.directoryEntry == rhs.directoryEntry
    }
}

struct Plugins: Equatable {
    let plugins: [Plugin]
    let capabilities: SitePluginCapabilities

    static func ==(lhs: Plugins, rhs: Plugins) -> Bool {
        return lhs.plugins == rhs.plugins
            && lhs.capabilities == rhs.capabilities
    }
}
