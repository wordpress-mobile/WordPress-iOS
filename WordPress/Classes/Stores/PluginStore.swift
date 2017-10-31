import Foundation

enum PluginAction: FluxAction {
    case activate(id: String, siteID: Int)
    case deactivate(id: String, siteID: Int)
    case enableAutoupdates(id: String, siteID: Int)
    case disableAutoupdates(id: String, siteID: Int)
    case remove(id: String, siteID: Int)
}

class PluginStore: FluxStore {
    private var plugins = [Int: SitePlugins]() {
        didSet {
            emitChange()
        }
    }
    private var fetching = [Int: Bool]()

    override func removeListener(_ listener: FluxStore.Listener) {
        super.removeListener(listener)
        if listenerCount == 0 {
            // Remove plugins from memory if nothing is listening for changes
            plugins = [:]
        }
    }

    func getPlugins(siteID: Int) -> SitePlugins? {
        if let sitePlugins = plugins[siteID] {
            return sitePlugins
        }
        if !(fetching[siteID] ?? false),
            let remote = remote {
            remote.getPlugins(
                siteID: siteID,
                success: { [weak self] (plugins) in
                    self?.plugins[siteID] = plugins
                    self?.fetching[siteID] = false
                },
                failure: { [weak self] (error) in
                    self?.fetching[siteID] = false
                })
        }
        return nil
    }

    func getPlugin(id: String, siteID: Int) -> PluginState? {
        guard let sitePlugins = getPlugins(siteID: siteID) else {
            return nil
        }
        return sitePlugins.plugins.first(where: { $0.id == id })
    }

    override func onDispatch(_ action: FluxAction) {
        guard let pluginAction = action as? PluginAction else {
            return
        }
        switch pluginAction {
        case .activate(let pluginID, let siteID):
            activatePlugin(pluginID: pluginID, siteID: siteID)
        case .deactivate(let pluginID, let siteID):
            deactivatePlugin(pluginID: pluginID, siteID: siteID)
        case .enableAutoupdates(let pluginID, let siteID):
            enableAutoupdatesPlugin(pluginID: pluginID, siteID: siteID)
        case .disableAutoupdates(let pluginID, let siteID):
            disableAutoupdatesPlugin(pluginID: pluginID, siteID: siteID)
        case .remove(let pluginID, let siteID):
            removePlugin(pluginID: pluginID, siteID: siteID)
        }
    }

    func activatePlugin(pluginID: String, siteID: Int) {
        modifyPlugin(id: pluginID, siteID: siteID) { (plugin) in
            plugin.active = true
        }
        remote?.activatePlugin(
            pluginID: pluginID,
            siteID: siteID,
            success: {},
            failure: { [weak self] _ in
                self?.modifyPlugin(id: pluginID, siteID: siteID, change: { (plugin) in
                    plugin.active = false
                })
        })
    }

    func deactivatePlugin(pluginID: String, siteID: Int) {
        modifyPlugin(id: pluginID, siteID: siteID) { (plugin) in
            plugin.active = false
        }
        remote?.deactivatePlugin(
            pluginID: pluginID,
            siteID: siteID,
            success: {},
            failure: { [weak self] _ in
                self?.modifyPlugin(id: pluginID, siteID: siteID, change: { (plugin) in
                    plugin.active = true
                })
        })
    }

    func enableAutoupdatesPlugin(pluginID: String, siteID: Int) {
        modifyPlugin(id: pluginID, siteID: siteID) { (plugin) in
            plugin.autoupdate = true
        }
        remote?.enableAutoupdates(
            pluginID: pluginID,
            siteID: siteID,
            success: {},
            failure: { [weak self] _ in
                self?.modifyPlugin(id: pluginID, siteID: siteID, change: { (plugin) in
                    plugin.autoupdate = false
                })
        })
    }

    func disableAutoupdatesPlugin(pluginID: String, siteID: Int) {
        modifyPlugin(id: pluginID, siteID: siteID) { (plugin) in
            plugin.autoupdate = false
        }
        remote?.disableAutoupdates(
            pluginID: pluginID,
            siteID: siteID,
            success: {},
            failure: { [weak self] _ in
                self?.modifyPlugin(id: pluginID, siteID: siteID, change: { (plugin) in
                    plugin.autoupdate = true
                })
        })
    }

    func removePlugin(pluginID: String, siteID: Int) {
        guard let sitePlugins = plugins[siteID],
            let index = sitePlugins.plugins.index(where: { $0.id == pluginID }) else {
                return
        }
        plugins[siteID]?.plugins.remove(at: index)
        emitChange()
        remote?.remove(
            pluginID: pluginID,
            siteID: siteID,
            success: {},
            failure: { [weak self] _ in
                _ = self?.getPlugins(siteID: siteID)
        })
    }

    private func modifyPlugin(id: String, siteID: Int, change: (inout PluginState) -> Void) {
        guard let sitePlugins = plugins[siteID],
            let index = sitePlugins.plugins.index(where: { $0.id == id }) else {
                return
        }
        var plugin = sitePlugins.plugins[index]
        change(&plugin)
        plugins[siteID]?.plugins[index] = plugin
        emitChange()
    }

    private var remote: PluginServiceRemote? {
        let context = ContextManager.sharedInstance().mainContext
        let service = AccountService(managedObjectContext: context)
        guard let account = service.defaultWordPressComAccount() else {
            return nil
        }
        return PluginServiceRemote(wordPressComRestApi: account.wordPressComRestApi)
    }
}
