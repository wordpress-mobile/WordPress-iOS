import Foundation
import WordPressFlux

enum PluginAction: Action {
    case activate(id: String, site: JetpackSiteRef)
    case deactivate(id: String, site: JetpackSiteRef)
    case enableAutoupdates(id: String, site: JetpackSiteRef)
    case disableAutoupdates(id: String, site: JetpackSiteRef)
    case remove(id: String, site: JetpackSiteRef)
    case receivePlugins(site: JetpackSiteRef, plugins: SitePlugins)
    case receivePluginsFailed(site: JetpackSiteRef, error: Error)
}

enum PluginQuery {
    case all(site: JetpackSiteRef)

    var site: JetpackSiteRef {
        switch self {
        case .all(let site):
            return site
        }
    }
}

struct PluginStoreState {
    var plugins = [JetpackSiteRef: SitePlugins]()
    var fetching = [JetpackSiteRef: Bool]()
    var lastFetch = [JetpackSiteRef: Date]()
}

class PluginStore: QueryStore<PluginStoreState, PluginQuery> {
    fileprivate let refreshInterval: TimeInterval = 60 // seconds

    init(dispatcher: ActionDispatcher = .global) {
        super.init(initialState: PluginStoreState(), dispatcher: dispatcher)
    }

    override func queriesChanged() {
        guard !activeQueries.isEmpty else {
            // Remove plugins from memory if nothing is listening for changes
            transaction({ (state) in
                state.plugins = [:]
                state.lastFetch = [:]
            })
            return
        }
        processQueries()
    }

    func processQueries() {
        let sitesWithQuery = activeQueries
            .map({ $0.site })
            .unique
        let sitesToFetch = sitesWithQuery
            .filter(shouldFetch(site:))

        sitesToFetch.forEach { (site) in
            fetchPlugins(site: site)
        }
    }

    override func onDispatch(_ action: Action) {
        guard let pluginAction = action as? PluginAction else {
            return
        }
        switch pluginAction {
        case .activate(let pluginID, let site):
            activatePlugin(pluginID: pluginID, site: site)
        case .deactivate(let pluginID, let site):
            deactivatePlugin(pluginID: pluginID, site: site)
        case .enableAutoupdates(let pluginID, let site):
            enableAutoupdatesPlugin(pluginID: pluginID, site: site)
        case .disableAutoupdates(let pluginID, let site):
            disableAutoupdatesPlugin(pluginID: pluginID, site: site)
        case .remove(let pluginID, let site):
            removePlugin(pluginID: pluginID, site: site)
        case .receivePlugins(let site, let plugins):
            receivePlugins(site: site, plugins: plugins)
        case .receivePluginsFailed(let site, _):
            state.fetching[site] = false
        }
    }
}

// MARK: - Selectors
extension PluginStore {
    func getPlugins(site: JetpackSiteRef) -> SitePlugins? {
        return state.plugins[site]
    }

    func getPlugin(id: String, site: JetpackSiteRef) -> PluginState? {
        return getPlugins(site: site)?.plugins.first(where: { $0.id == id })
    }

    func shouldFetch(site: JetpackSiteRef) -> Bool {
        let lastFetch = state.lastFetch[site, default: .distantPast]
        let needsRefresh = lastFetch + refreshInterval < Date()
        let isFetching = state.fetching[site, default: false]
        return needsRefresh && !isFetching
    }
}

// MARK: - Action handlers
private extension PluginStore {
    func activatePlugin(pluginID: String, site: JetpackSiteRef) {
        modifyPlugin(id: pluginID, site: site) { (plugin) in
            plugin.active = true
        }
        remote(site: site)?.activatePlugin(
            pluginID: pluginID,
            siteID: site.siteID,
            success: {},
            failure: { [weak self] _ in
                self?.modifyPlugin(id: pluginID, site: site, change: { (plugin) in
                    plugin.active = false
                })
        })
    }

    func deactivatePlugin(pluginID: String, site: JetpackSiteRef) {
        modifyPlugin(id: pluginID, site: site) { (plugin) in
            plugin.active = false
        }
        remote(site: site)?.deactivatePlugin(
            pluginID: pluginID,
            siteID: site.siteID,
            success: {},
            failure: { [weak self] _ in
                self?.modifyPlugin(id: pluginID, site: site, change: { (plugin) in
                    plugin.active = true
                })
        })
    }

    func enableAutoupdatesPlugin(pluginID: String, site: JetpackSiteRef) {
        modifyPlugin(id: pluginID, site: site) { (plugin) in
            plugin.autoupdate = true
        }
        remote(site: site)?.enableAutoupdates(
            pluginID: pluginID,
            siteID: site.siteID,
            success: {},
            failure: { [weak self] _ in
                self?.modifyPlugin(id: pluginID, site: site, change: { (plugin) in
                    plugin.autoupdate = false
                })
        })
    }

    func disableAutoupdatesPlugin(pluginID: String, site: JetpackSiteRef) {
        modifyPlugin(id: pluginID, site: site) { (plugin) in
            plugin.autoupdate = false
        }
        remote(site: site)?.disableAutoupdates(
            pluginID: pluginID,
            siteID: site.siteID,
            success: {},
            failure: { [weak self] _ in
                self?.modifyPlugin(id: pluginID, site: site, change: { (plugin) in
                    plugin.autoupdate = true
                })
        })
    }

    func removePlugin(pluginID: String, site: JetpackSiteRef) {
        guard let sitePlugins = state.plugins[site],
            let index = sitePlugins.plugins.index(where: { $0.id == pluginID }) else {
                return
        }
        state.plugins[site]?.plugins.remove(at: index)
        remote(site: site)?.remove(
            pluginID: pluginID,
            siteID: site.siteID,
            success: {},
            failure: { [weak self] _ in
                _ = self?.getPlugins(site: site)
        })
    }

    func modifyPlugin(id: String, site: JetpackSiteRef, change: (inout PluginState) -> Void) {
        guard let sitePlugins = state.plugins[site],
            let index = sitePlugins.plugins.index(where: { $0.id == id }) else {
                return
        }
        var plugin = sitePlugins.plugins[index]
        change(&plugin)
        state.plugins[site]?.plugins[index] = plugin
    }

    func fetchPlugins(site: JetpackSiteRef) {
        guard let remote = remote(site: site) else {
            return
        }
        state.fetching[site] = true
        remote.getPlugins(
            siteID: site.siteID,
            success: { [actionDispatcher] (plugins) in
                actionDispatcher.dispatch(PluginAction.receivePlugins(site: site, plugins: plugins))
            },
            failure: { [actionDispatcher] (error) in
                actionDispatcher.dispatch(PluginAction.receivePluginsFailed(site: site, error: error))
        })
    }

    func receivePlugins(site: JetpackSiteRef, plugins: SitePlugins) {
        transaction { (state) in
            state.plugins[site] = plugins
            state.fetching[site] = false
            state.lastFetch[site] = Date()
        }
    }

    func receivePluginsFailed(site: JetpackSiteRef) {
        transaction { (state) in
            state.fetching[site] = false
            state.lastFetch[site] = Date()
        }
    }

    func remote(site: JetpackSiteRef) -> PluginServiceRemote? {
        guard let token = CredentialsService().getOAuthToken(site: site) else {
            return nil
        }
        let api = WordPressComRestApi(oAuthToken: token, userAgent: WPUserAgent.wordPress())

        return PluginServiceRemote(wordPressComRestApi: api)
    }
}
