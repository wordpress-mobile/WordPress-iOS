import Foundation

class StoreContainer {
    static let shared = StoreContainer()

    private init() {}

    let plugin = PluginStore()
}
