import Foundation
import WordPressFlux

enum PluginAction: Action {
    case activate(id: String, site: JetpackSiteRef)
    case deactivate(id: String, site: JetpackSiteRef)
    case enableAutoupdates(id: String, site: JetpackSiteRef)
    case disableAutoupdates(id: String, site: JetpackSiteRef)
    case update(id: String, site: JetpackSiteRef)
    case remove(id: String, site: JetpackSiteRef)
    case refreshPlugins(site: JetpackSiteRef)
    case receivePlugins(site: JetpackSiteRef, plugins: SitePlugins)
    case receivePluginsFailed(site: JetpackSiteRef, error: Error)
    case receivePluginDirectoryEntry(slug: String, entry: PluginDirectoryEntry)
    case receivePluginDirectoryEntryFailed(slug: String, error: Error)
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

enum PluginDirectoryEntryState {
    case unknown
    case missing(Date)
    case present(PluginDirectoryEntry)

    var entry: PluginDirectoryEntry? {
        switch self {
        case .present(let entry):
            return entry
        case .missing, .unknown:
            return nil
        }
    }

    var lastUpdated: Date {
        switch self {
        case .unknown:
            return .distantPast
        case .missing(let date):
            return date
        case .present(let entry):
            return entry.lastUpdated
        }
    }
}

struct PluginStoreState {
    var plugins = [JetpackSiteRef: SitePlugins]()
    var fetching = [JetpackSiteRef: Bool]()
    var lastFetch = [JetpackSiteRef: Date]()
    var directoryEntries = [String: PluginDirectoryEntryState]()
    var fetchingDirectoryEntry = [String: Bool]()
    var updatesInProgress = [JetpackSiteRef: Set<String>]()
}

extension PluginStoreState {
    mutating func modifyPlugin(id: String, site: JetpackSiteRef, change: (inout PluginState) -> Void) {
        guard let sitePlugins = plugins[site],
            let index = sitePlugins.plugins.index(where: { $0.id == id }) else {
                return
        }
        var plugin = sitePlugins.plugins[index]
        change(&plugin)
        plugins[site]?.plugins[index] = plugin
    }
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
                state.directoryEntries = [:]
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
        case .update(let pluginID, let site):
            updatePlugin(pluginID: pluginID, site: site)
        case .remove(let pluginID, let site):
            removePlugin(pluginID: pluginID, site: site)
        case .refreshPlugins(let site):
            refreshPlugins(site: site)
        case .receivePlugins(let site, let plugins):
            receivePlugins(site: site, plugins: plugins)
        case .receivePluginsFailed(let site, _):
            state.fetching[site] = false
        case .receivePluginDirectoryEntry(let slug, let entry):
            receivePluginDirectoryEntry(slug: slug, entry: entry)
        case .receivePluginDirectoryEntryFailed(let slug, let error):
            receivePluginDirectoryEntryFailed(slug: slug, error: error)
        }
    }
}

// MARK: - Selectors
extension PluginStore {
    func getPlugins(site: JetpackSiteRef) -> Plugins? {
        return state.plugins[site].map({ (sitePlugins) in
            let plugins = sitePlugins.plugins.map({ (state) -> Plugin in
                let entry = getPluginDirectoryEntry(slug: state.slug)
                return Plugin(state: state, directoryEntry: entry)
            })
            return Plugins(
                plugins: plugins,
                capabilities: sitePlugins.capabilities
            )
        })
    }

    func getPlugin(id: String, site: JetpackSiteRef) -> Plugin? {
        return getPlugins(site: site)?.plugins.first(where: { $0.id == id })
    }

    func getPluginDirectoryEntry(slug: String) -> PluginDirectoryEntry? {
        return state.directoryEntries[slug]?.entry
    }

    func isFetchingPlugins(site: JetpackSiteRef) -> Bool {
        return state.fetching[site, default: false]
    }

    func shouldFetch(site: JetpackSiteRef) -> Bool {
        let lastFetch = state.lastFetch[site, default: .distantPast]
        let needsRefresh = lastFetch + refreshInterval < Date()
        let isFetching = isFetchingPlugins(site: site)
        return needsRefresh && !isFetching
    }

    func shouldFetchDirectory(slug: String) -> Bool {
        let lastFetch = state.directoryEntries[slug, default: .unknown].lastUpdated
        let needsRefresh = lastFetch + refreshInterval < Date()
        let isFetching = state.fetchingDirectoryEntry[slug, default: false]
        return needsRefresh && !isFetching
    }
}

// MARK: - Action handlers
private extension PluginStore {
    func activatePlugin(pluginID: String, site: JetpackSiteRef) {
        state.modifyPlugin(id: pluginID, site: site) { (plugin) in
            plugin.active = true
        }
        remote(site: site)?.activatePlugin(
            pluginID: pluginID,
            siteID: site.siteID,
            success: {},
            failure: { [weak self] _ in
                self?.state.modifyPlugin(id: pluginID, site: site, change: { (plugin) in
                    plugin.active = false
                })
        })
    }

    func deactivatePlugin(pluginID: String, site: JetpackSiteRef) {
        state.modifyPlugin(id: pluginID, site: site) { (plugin) in
            plugin.active = false
        }
        remote(site: site)?.deactivatePlugin(
            pluginID: pluginID,
            siteID: site.siteID,
            success: {},
            failure: { [weak self] _ in
                self?.state.modifyPlugin(id: pluginID, site: site, change: { (plugin) in
                    plugin.active = true
                })
        })
    }

    func enableAutoupdatesPlugin(pluginID: String, site: JetpackSiteRef) {
        state.modifyPlugin(id: pluginID, site: site) { (plugin) in
            plugin.autoupdate = true
        }
        remote(site: site)?.enableAutoupdates(
            pluginID: pluginID,
            siteID: site.siteID,
            success: {},
            failure: { [weak self] _ in
                self?.state.modifyPlugin(id: pluginID, site: site, change: { (plugin) in
                    plugin.autoupdate = false
                })
        })
    }

    func disableAutoupdatesPlugin(pluginID: String, site: JetpackSiteRef) {
        state.modifyPlugin(id: pluginID, site: site) { (plugin) in
            plugin.autoupdate = false
        }
        remote(site: site)?.disableAutoupdates(
            pluginID: pluginID,
            siteID: site.siteID,
            success: {},
            failure: { [weak self] _ in
                self?.state.modifyPlugin(id: pluginID, site: site, change: { (plugin) in
                    plugin.autoupdate = true
                })
        })
    }

    func updatePlugin(pluginID: String, site: JetpackSiteRef) {
        guard !state.updatesInProgress[site, default: Set()].contains(pluginID),
            let plugin = getPlugin(id: pluginID, site: site),
            case let .available(version) = plugin.state.updateState else {
            return
        }
        transaction { (state) in
            state.updatesInProgress[site, default: Set()].insert(pluginID)
            state.modifyPlugin(id: pluginID, site: site, change: { (plugin) in
                plugin.updateState = .updating(version)
            })
        }
        WPAppAnalytics.track(.pluginUpdated, withBlogID: site.siteID as NSNumber)
        remote(site: site)?.updatePlugin(
            pluginID: pluginID,
            siteID: site.siteID,
            success: { [weak self] (plugin) in
                self?.transaction({ (state) in
                    state.modifyPlugin(id: pluginID, site: site, change: { (updatedPlugin) in
                        updatedPlugin = plugin
                    })
                    state.updatesInProgress[site]?.remove(pluginID)
                })
            },
            failure: { [weak self] (error) in
                self?.transaction({ (state) in
                    state.modifyPlugin(id: pluginID, site: site, change: { (updatedPlugin) in
                        updatedPlugin.updateState = .available(version)
                    })
                    state.updatesInProgress[site]?.remove(pluginID)
                    let message = String(format: NSLocalizedString("Error updating %@.", comment: "There was an error updating a plugin, placeholder is the plugin name"), plugin.name)
                    ActionDispatcher.dispatch(NoticeAction.post(Notice(title: message)))
                })
                print("Error updating plugin: \(error)")
        })
    }

    func removePlugin(pluginID: String, site: JetpackSiteRef) {
        guard let sitePlugins = state.plugins[site],
            let plugin = getPlugin(id: pluginID, site: site),
            let index = sitePlugins.plugins.index(where: { $0.id == pluginID }) else {
                return
        }
        state.plugins[site]?.plugins.remove(at: index)
        WPAppAnalytics.track(.pluginRemoved, withBlogID: site.siteID as NSNumber)

        guard let remote = self.remote(site: site) else {
            return
        }

        let failure: (Error) -> Void = { [weak self] (error) in
            DDLogError("Error removing \(plugin.name): \(error)")
            let message = String(format: NSLocalizedString("Error removing %@.", comment: "There was an error removing a plugin, placeholder is the plugin name"), plugin.name)
            ActionDispatcher.dispatch(NoticeAction.post(Notice(title: message)))
            self?.refreshPlugins(site: site)
        }

        let remove = {
            remote.remove(
                pluginID: pluginID,
                siteID: site.siteID,
                success: {},
                failure: failure)
        }

        if plugin.state.active {
            remote.deactivatePlugin(pluginID: pluginID,
                                    siteID: site.siteID,
                                    success: remove,
                                    failure: failure)
        } else {
            remove()
        }
    }

    func refreshPlugins(site: JetpackSiteRef) {
        guard !isFetchingPlugins(site: site) else {
            DDLogInfo("Plugin refresh triggered while one was in progress")
            return
        }
        fetchPlugins(site: site)
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
        var plugins = plugins
        if let updatesForSite = state.updatesInProgress[site].map(Set.init(_:)) {
            plugins.plugins = plugins.plugins.map({ (plugin) in
                var plugin = plugin
                if case let .available(version) = plugin.updateState,
                    updatesForSite.contains(plugin.id) {
                    plugin.updateState = .updating(version)
                }
                return plugin
            })
        }
        if isAutomatedTransfer(site: site) {
            plugins.plugins = plugins.plugins.map({ (plugin) in
                var plugin = plugin
                if ["akismet", "jetpack", "vaultpress"].contains(plugin.slug) {
                    plugin.automanaged = true
                }
                return plugin
            })
        }
        transaction { (state) in
            state.plugins[site] = plugins
            state.fetching[site] = false
            state.lastFetch[site] = Date()
        }
        fetchPluginDirectoryEntries(site: site)
    }

    func receivePluginsFailed(site: JetpackSiteRef) {
        transaction { (state) in
            state.fetching[site] = false
            state.lastFetch[site] = Date()
        }
    }

    func fetchPluginDirectoryEntries(site: JetpackSiteRef) {
        state.plugins[site]?.plugins
            .map({ $0.slug })
            .filter(shouldFetchDirectory(slug:))
            .forEach(fetchPluginDirectoryEntry(slug:))
    }

    func fetchPluginDirectoryEntry(slug: String) {
        let remote = PluginDirectoryServiceRemote()
        state.fetchingDirectoryEntry[slug] = true
        remote.getPluginInformation(
            slug: slug,
            completion: { [actionDispatcher] (result) in
                switch result {
                case .success(let entry):
                    actionDispatcher.dispatch(PluginAction.receivePluginDirectoryEntry(slug: slug, entry: entry))
                case .failure(let error):
                    actionDispatcher.dispatch(PluginAction.receivePluginDirectoryEntryFailed(slug: slug, error: error))
                }
            })
    }

    func receivePluginDirectoryEntry(slug: String, entry: PluginDirectoryEntry) {
        transaction { (state) in
            state.directoryEntries[slug] = .present(entry)
            state.fetchingDirectoryEntry[slug] = false
        }
    }

    func receivePluginDirectoryEntryFailed(slug: String, error: Error) {
        transaction { (state) in
            if (error as? PluginDirectoryGetInformationEndpoint.Error) == .pluginNotFound {
                state.directoryEntries[slug] = .missing(Date())
            }
            state.fetchingDirectoryEntry[slug] = false
        }
    }

    func isAutomatedTransfer(site: JetpackSiteRef) -> Bool {
        let context = ContextManager.sharedInstance().mainContext
        let predicate = NSPredicate(format: "blogID = %i AND account.username = %@", site.siteID, site.username)
        let blog = context.firstObject(ofType: Blog.self, matching: predicate)
        return blog?.jetpack?.automatedTransfer ?? false
    }

    func remote(site: JetpackSiteRef) -> PluginServiceRemote? {
        guard let token = CredentialsService().getOAuthToken(site: site) else {
            return nil
        }
        let api = WordPressComRestApi(oAuthToken: token, userAgent: WPUserAgent.wordPress())

        return PluginServiceRemote(wordPressComRestApi: api)
    }
}
