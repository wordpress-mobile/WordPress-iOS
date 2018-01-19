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
    case receivePluginDirectoryFeed(feed: FeedType, response: PluginDirectoryResponse)
    case receivePluginDirectoryFeedFailed(feed: FeedType, error: Error)
}

enum PluginQuery {
    case all(site: JetpackSiteRef)
    case feed(type: FeedType)

    var site: JetpackSiteRef? {
        switch self {
        case .all(let site):
            return site
        case .feed(_):
            return nil
        }
    }

    var feedType: FeedType? {
        switch self {
        case .all(_):
            return nil
        case .feed(let feedType):
            return feedType
        }
    }
}

enum PluginDirectoryEntryState {
    case unknown
    case missing(Date)
    case present(PluginDirectoryEntry)
    case partial(PluginDirectoryEntry)

    var entry: PluginDirectoryEntry? {
        switch self {
        case .present(let entry), .partial(let entry):
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
        case .present(let entry), .partial(let entry):
            return entry.lastUpdated
        }
    }

    static func moreSpecific(_ left: PluginDirectoryEntryState, _ right: PluginDirectoryEntryState) -> PluginDirectoryEntryState {
        // When fetching data about plugins from the Directory, we specifically ask the backend
        // to not include some fields — otherwise the payload becomes too large and takes too long to parse (and we're probably gonna discard it anyway),
        // but it's possible we already "knew" about that Plugin from before — when user has that plugin installed on their site, for example.
        // We fetch all the required data for in that case, but we need to be careful not to overwrite it with "partial" data accidentaly, when refreshing
        // data from the directory.

        switch (left, right) {
        case (.present, _):
            return left
        case (_, .present):
            return right
        case (.partial, _):
            return left
        case (_, .partial):
            return right
        case (.missing, _):
            return left
        case (_, .missing):
            return right
        case (.unknown, _):
            return left
        }
    }
}

struct PluginStoreState {
    var plugins = [JetpackSiteRef: SitePlugins]()
    var fetching = [JetpackSiteRef: Bool]()
    var lastFetch = [JetpackSiteRef: Date]()

    var updatesInProgress = [JetpackSiteRef: Set<String>]()

    var directoryFeeds = [String: PluginDirectoryPageMetadata]()
    var fetchingDirectoryFeed = [String: Bool]()
    var lastDirectoryFeedFetch = [String: Date]()

    var directoryEntries = [String: PluginDirectoryEntryState]()
    var fetchingDirectoryEntry = [String: Bool]()
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
                state.directoryFeeds = [:]
                state.lastDirectoryFeedFetch = [:]
            })
            return
        }
        processQueries()
    }

    func processQueries() {
        let sitesToFetch = activeQueries
            .flatMap { query -> JetpackSiteRef? in
                guard case .all(let site) = query else { return nil }
                return site
            }
            .unique
            .filter { shouldFetch(site: $0) }

        sitesToFetch.forEach { (site) in
            fetchPlugins(site: site)
        }

        let feedsToFetch = activeQueries
            .flatMap { query -> FeedType? in
                guard case .feed(let feedType) = query else { return nil }
                return feedType
            }
            .unique(by: \FeedType.feedName)
            .filter { shouldFetchDirectory(feed: $0) }

        feedsToFetch
            .forEach { fetchPluginDirectoryFeed(feed: $0) }

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
        case .receivePluginDirectoryFeed(let feed, let response):
            receivePluginDirectoryFeed(feed: feed, response: response)
        case .receivePluginDirectoryFeedFailed(let feed, let error):
            receivePluginDirectoryFeedFailed(feed: feed, error: error)
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

    func getPluginDirectoryFeedPlugins(from feed: FeedType) -> [PluginDirectoryEntry] {
        guard let fetchedFeed = state.directoryFeeds[feed.feedName] else { return [] }
        let directoryEntries = fetchedFeed.pluginSlugs.flatMap { getPluginDirectoryEntry(slug: $0) }

        return directoryEntries
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

    func shouldFetchDirectory(feed: FeedType) -> Bool {
        let lastFetch = state.lastDirectoryFeedFetch[feed.feedName, default: .distantPast]
        let needsRefresh = lastFetch + refreshInterval < Date()
        let isFetching = state.fetchingDirectoryFeed[feed.feedName, default: false]
        return needsRefresh && !isFetching
    }
}

// MARK: - Action handlers
private extension PluginStore {
    func activatePlugin(pluginID: String, site: JetpackSiteRef) {
        guard let plugin = getPlugin(id: pluginID, site: site) else {
            return
        }
        state.modifyPlugin(id: pluginID, site: site) { (plugin) in
            plugin.active = true
        }
        remote(site: site)?.activatePlugin(
            pluginID: pluginID,
            siteID: site.siteID,
            success: {},
            failure: { [weak self] (error) in
                let message = String(format: NSLocalizedString("Error activating %@.", comment: "There was an error activating a plugin, placeholder is the plugin name"), plugin.name)
                self?.notifyRemoteError(message: message, error: error)
                self?.state.modifyPlugin(id: pluginID, site: site, change: { (plugin) in
                    plugin.active = false
                })
        })
    }

    func deactivatePlugin(pluginID: String, site: JetpackSiteRef) {
        guard let plugin = getPlugin(id: pluginID, site: site) else {
            return
        }
        state.modifyPlugin(id: pluginID, site: site) { (plugin) in
            plugin.active = false
        }
        remote(site: site)?.deactivatePlugin(
            pluginID: pluginID,
            siteID: site.siteID,
            success: {},
            failure: { [weak self] (error) in
                let message = String(format: NSLocalizedString("Error deactivating %@.", comment: "There was an error deactivating a plugin, placeholder is the plugin name"), plugin.name)
                self?.notifyRemoteError(message: message, error: error)
                self?.state.modifyPlugin(id: pluginID, site: site, change: { (plugin) in
                    plugin.active = true
                })
        })
    }

    func enableAutoupdatesPlugin(pluginID: String, site: JetpackSiteRef) {
        guard let plugin = getPlugin(id: pluginID, site: site) else {
            return
        }
        state.modifyPlugin(id: pluginID, site: site) { (plugin) in
            plugin.autoupdate = true
        }
        remote(site: site)?.enableAutoupdates(
            pluginID: pluginID,
            siteID: site.siteID,
            success: {},
            failure: { [weak self] (error) in
                let message = String(format: NSLocalizedString("Error enabling autoupdates for %@.", comment: "There was an error enabling autoupdates for a plugin, placeholder is the plugin name"), plugin.name)
                self?.notifyRemoteError(message: message, error: error)
                self?.state.modifyPlugin(id: pluginID, site: site, change: { (plugin) in
                    plugin.autoupdate = false
                })
        })
    }

    func disableAutoupdatesPlugin(pluginID: String, site: JetpackSiteRef) {
        guard let plugin = getPlugin(id: pluginID, site: site) else {
            return
        }
        state.modifyPlugin(id: pluginID, site: site) { (plugin) in
            plugin.autoupdate = false
        }
        remote(site: site)?.disableAutoupdates(
            pluginID: pluginID,
            siteID: site.siteID,
            success: {},
            failure: { [weak self] (error) in
                let message = String(format: NSLocalizedString("Error disabling autoupdates for %@.", comment: "There was an error disabling autoupdates for a plugin, placeholder is the plugin name"), plugin.name)
                self?.notifyRemoteError(message: message, error: error)
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
                    self?.notifyRemoteError(message: message, error: error)
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
            let message = String(format: NSLocalizedString("Error removing %@.", comment: "There was an error removing a plugin, placeholder is the plugin name"), plugin.name)
            self?.notifyRemoteError(message: message, error: error)
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

    func fetchPluginDirectoryFeed(feed: FeedType) {
        state.fetchingDirectoryFeed[feed.feedName] = true

        let remote = PluginDirectoryServiceRemote()
        remote.getPluginFeed(feed) { [actionDispatcher] result in
            switch result {
            case .success(let response):
                actionDispatcher.dispatch(PluginAction.receivePluginDirectoryFeed(feed: feed, response: response))
            case .failure(let error):
                actionDispatcher.dispatch(PluginAction.receivePluginDirectoryFeedFailed(feed: feed, error: error))
            }
        }
    }

    func receivePluginDirectoryFeed(feed: FeedType, response: PluginDirectoryResponse) {
        let zippedPlugins = zip(response.pageMetadata.pluginSlugs, response.plugins.map { PluginDirectoryEntryState.partial($0)})
        let plugins = Dictionary(uniqueKeysWithValues: zippedPlugins)

        transaction { (state) in
            state.fetchingDirectoryFeed[feed.feedName] = false
            state.directoryFeeds[feed.feedName] = response.pageMetadata
            state.lastDirectoryFeedFetch[feed.feedName] = Date()
            state.directoryEntries.merge(plugins) { PluginDirectoryEntryState.moreSpecific($0, $1) }
        }
    }

    func receivePluginDirectoryFeedFailed(feed: FeedType, error: Error) {
        transaction { state in
            state.fetchingDirectoryFeed[feed.feedName] = false
            state.lastDirectoryFeedFetch[feed.feedName] = Date()
        }
    }

    func notifyRemoteError(message: String, error: Error) {
        DDLogError("[PluginStore Error] \(message)")
        DDLogError("[PluginStore Error] \(error)")
        ActionDispatcher.dispatch(NoticeAction.post(Notice(title: message)))
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
