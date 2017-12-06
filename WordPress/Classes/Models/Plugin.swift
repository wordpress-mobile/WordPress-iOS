import Foundation

struct Plugin {
    let state: PluginState
    let directoryEntry: PluginDirectoryEntry?

    var id: String {
        return state.id
    }

    var name: String {
        return state.name
    }
}

struct Plugins {
    let plugins: [Plugin]
    let capabilities: SitePluginCapabilities
}
