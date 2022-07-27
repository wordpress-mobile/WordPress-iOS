import Foundation
import WordPressFlux
import WordPressKit

enum PluginAction: Action {
    case activate(id: String, site: JetpackSiteRef)
    case deactivate(id: String, site: JetpackSiteRef)
    case enableAutoupdates(id: String, site: JetpackSiteRef)
    case disableAutoupdates(id: String, site: JetpackSiteRef)
    case activateAndEnableAutoupdates(id: String, site: JetpackSiteRef)
    case install(plugin: PluginDirectoryEntry, site: JetpackSiteRef)
    case update(id: String, site: JetpackSiteRef)
    case remove(id: String, site: JetpackSiteRef)
    case refreshPlugins(site: JetpackSiteRef)
    case refreshFeaturedPlugins
    case refreshFeed(feed: PluginDirectoryFeedType)
    case receivePlugins(site: JetpackSiteRef, plugins: SitePlugins)
    case receivePluginsFailed(site: JetpackSiteRef, error: Error)
    case receiveFeaturedPlugins(plugins: [PluginDirectoryEntry])
    case receiveFeaturedPluginsFailed(error: Error)
    case receivePluginDirectoryEntry(slug: String, entry: PluginDirectoryEntry)
    case receivePluginDirectoryEntryFailed(slug: String, error: Error)
    case receivePluginDirectoryFeed(feed: PluginDirectoryFeedType, response: PluginDirectoryFeedPage)
    case receivePluginDirectoryFeedFailed(feed: PluginDirectoryFeedType, error: Error)
}

enum PluginQuery {
    case all(site: JetpackSiteRef)
    case feed(type: PluginDirectoryFeedType)
    case directoryEntry(slug: String)
    case featured

    var site: JetpackSiteRef? {
        switch self {
        case .all(let site):
            return site
        case .feed, .directoryEntry, .featured:
            return nil
        }
    }

    var feedType: PluginDirectoryFeedType? {
        switch self {
        case .all, .directoryEntry, .featured:
            return nil
        case .feed(let feedType):
            return feedType
        }
    }

    var slug: String? {
        switch self {
        case .directoryEntry(let slug):
            return slug
        case .all, .feed, .featured:
            return nil
        }
    }
}

enum PluginDirectoryEntryState: Codable {
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
            return entry.lastUpdated ?? .distantPast
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

    private enum CodingKeys: String, CodingKey {
        case unknown
        case missing
        case present
        case partial
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .unknown:
            try container.encode(true, forKey: .unknown)
        case .missing(let value):
            try container.encode(value, forKey: .missing)
        case .present(let value):
            try container.encode(value, forKey: .present)
        case .partial(let value):
            try container.encode(value, forKey: .partial)
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        if let date = try container.decodeIfPresent(Date.self, forKey: .missing) {
            self = .missing(date)
            return
        }

        if let entry = try container.decodeIfPresent(PluginDirectoryEntry.self, forKey: .present) {
            self = .present(entry)
            return
        }

        if let entry = try container.decodeIfPresent(PluginDirectoryEntry.self, forKey: .partial) {
            self = .partial(entry)
            return
        }

        self = .unknown
    }

}

struct PluginStoreState {
    var plugins = [JetpackSiteRef: SitePlugins]()
    var fetching = [JetpackSiteRef: Bool]()
    var lastFetch = [JetpackSiteRef: Date]()

    var updatesInProgress = [JetpackSiteRef: Set<String>]()

    var featuredPluginsSlugs = [String]()
    var fetchingFeatured = false

    var directoryFeeds = [String: PluginDirectoryPageMetadata]()
    var fetchingDirectoryFeed = [String: Bool]()
    var lastDirectoryFeedFetch = [String: Date]()

    var directoryEntries = [String: PluginDirectoryEntryState]()
    var fetchingDirectoryEntry = [String: Bool]()

    static func emptyState() -> PluginStoreState {
        return PluginStoreState()
    }
}

extension PluginStoreState {
    mutating func modifyPlugin(id: String, site: JetpackSiteRef, change: (inout PluginState) -> Void) {
        guard let sitePlugins = plugins[site],
            let index = sitePlugins.plugins.firstIndex(where: { $0.id == id }) else {
                return
        }
        var plugin = sitePlugins.plugins[index]
        change(&plugin)
        plugins[site]?.plugins[index] = plugin
    }

    mutating func upsertPlugin(id: String, site: JetpackSiteRef, newPlugin: PluginState) -> Void {
        guard let sitePlugins = plugins[site], sitePlugins.plugins.contains(where: { $0.id == newPlugin.id }) else {
            plugins[site]?.plugins.append(newPlugin)
            return
        }

        modifyPlugin(id: id, site: site) {
            $0 = newPlugin
        }
    }
}

class PluginStore: QueryStore<PluginStoreState, PluginQuery> {
    fileprivate let refreshInterval: TimeInterval = 60 // seconds

    override func queriesChanged() {
        super.queriesChanged()
        processQueries()
    }

    init() {
        super.init(initialState: PluginStoreState())
    }

    override func logError(_ error: String) {
        DDLogError(error)
    }

    func processQueries() {
        // Fetching installed Plugins.
         sitesToFetch
            .forEach { fetchPlugins(site: $0) }

        // Fetching directory feeds.
        feedsToFetch
            .forEach { fetchPluginDirectoryFeed(feed: $0) }

        // Fetching specific plugins from directory.
        pluginsToFetch
            .forEach { fetchPluginDirectoryEntry(slug: $0) }

        // Fetching featured plugins.
        if shouldFetchFeatured() {
            fetchFeaturedPlugins()
        }
    }

    private var sitesToFetch: [JetpackSiteRef] {
        return activeQueries
            .filter {
                if case .all = $0 { return true }
                else { return false }
            }
            .compactMap { $0.site }
            .unique
            .filter { shouldFetch(site: $0) }
    }

    private var feedsToFetch: [PluginDirectoryFeedType] {
        return activeQueries
            .compactMap { $0.feedType }
            .unique
            .filter { shouldFetchDirectory(feed: $0) }
    }

    private func shouldFetchFeatured() -> Bool {
        let hasFeaturedQuery = activeQueries.contains {
            if case .featured = $0 {
                return true
            }
            return false
        }

        guard hasFeaturedQuery, state.featuredPluginsSlugs.isEmpty, !isFetchingFeatured() else {
            return false
        }

        return true
    }

    private var pluginsToFetch: [String] {
        return activeQueries
            .compactMap { $0.slug }
            .unique
            .filter { shouldFetchDirectory(slug: $0) }
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
        case .activateAndEnableAutoupdates(let pluginID, let site):
            activateAndEnableAutoupdatesPlugin(pluginID: pluginID, site: site)
        case .install(let plugin, let site):
            installPlugin(plugin: plugin, site: site)
        case .update(let pluginID, let site):
            updatePlugin(pluginID: pluginID, site: site)
        case .remove(let pluginID, let site):
            removePlugin(pluginID: pluginID, site: site)
        case .refreshPlugins(let site):
            refreshPlugins(site: site)
        case .refreshFeaturedPlugins:
            refreshFeaturedPlugins()
        case .refreshFeed(let feed):
            refreshFeed(feed: feed)
        case .receivePlugins(let site, let plugins):
            receivePlugins(site: site, plugins: plugins)
        case .receivePluginsFailed(let site, _):
            state.fetching[site] = false
        case .receiveFeaturedPlugins(let plugins):
            receiveFeaturedPlugins(plugins: plugins)
        case .receiveFeaturedPluginsFailed:
            state.fetchingFeatured = false
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

    func getPlugin(slug: String, site: JetpackSiteRef) -> Plugin? {
        return getPlugins(site: site)?.plugins.first(where: { $0.state.slug.hasPrefix(slug) })
    }

    func getFeaturedPlugins() -> [PluginDirectoryEntry]? {
        guard !state.featuredPluginsSlugs.isEmpty else {
            return nil
        }
        return state.featuredPluginsSlugs.compactMap { getPluginDirectoryEntry(slug: $0)}
    }

    func getPluginDirectoryEntry(slug: String) -> PluginDirectoryEntry? {
        return state.directoryEntries[slug]?.entry
    }

    func isFetchingPlugins(site: JetpackSiteRef) -> Bool {
        return state.fetching[site, default: false]
    }

    func isFetchingFeatured() -> Bool {
        return state.fetchingFeatured
    }

    func isFetchingFeed(feed: PluginDirectoryFeedType) -> Bool {
        return state.fetchingDirectoryFeed[feed.slug, default: false]
    }

    func isInstallingPlugin(site: JetpackSiteRef, slug: String) -> Bool {
        return state.updatesInProgress[site, default: Set()].contains(slug)
    }

    func getPluginDirectoryFeedPlugins(from feed: PluginDirectoryFeedType) -> [PluginDirectoryEntry]? {
        guard let fetchedFeed = state.directoryFeeds[feed.slug] else { return nil }
        let directoryEntries = fetchedFeed.pluginSlugs.compactMap { getPluginDirectoryEntry(slug: $0) }

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

    func shouldFetchDirectory(feed: PluginDirectoryFeedType) -> Bool {
        let isFetching = state.fetchingDirectoryFeed[feed.slug, default: false]

        if case .search(let term) = feed, term.count > 0 {
            return !isFetching
        }

        let lastFetch = state.lastDirectoryFeedFetch[feed.slug, default: .distantPast]
        let needsRefresh = lastFetch + refreshInterval < Date()
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

        track(.pluginActivated, with: site)

        remote(site: site)?.activatePlugin(
            pluginID: plugin.state.id,
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

        track(.pluginDeactivated, with: site)

        remote(site: site)?.deactivatePlugin(
            pluginID: plugin.state.id,
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

        track(.pluginAutoupdateEnabled, with: site)

        remote(site: site)?.enableAutoupdates(
            pluginID: plugin.state.id,
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

        track(.pluginAutoupdateDisabled, with: site)

        remote(site: site)?.disableAutoupdates(
            pluginID: plugin.state.id,
            success: {},
            failure: { [weak self] (error) in
                let message = String(format: NSLocalizedString("Error disabling autoupdates for %@.", comment: "There was an error disabling autoupdates for a plugin, placeholder is the plugin name"), plugin.name)
                self?.notifyRemoteError(message: message, error: error)
                self?.state.modifyPlugin(id: pluginID, site: site, change: { (plugin) in
                    plugin.autoupdate = true
                })
        })
    }

    func activateAndEnableAutoupdatesPlugin(pluginID: String, site: JetpackSiteRef) {
        guard let plugin = getPlugin(id: pluginID, site: site) else {
            return
        }
        state.modifyPlugin(id: pluginID, site: site) { plugin in
            plugin.autoupdate = true
            plugin.active = true
        }
        remote(site: site)?.activateAndEnableAutoupdates(pluginID: plugin.state.id,
                                                         success: {},
                                                         failure: { [weak self] error in
                                                            self?.state.modifyPlugin(id: pluginID, site: site) { plugin in
                                                                plugin.autoupdate = false
                                                                plugin.active = false
                                                            }
        })
    }

    func installPlugin(plugin: PluginDirectoryEntry, site: JetpackSiteRef) {
        guard let remote = remote(site: site), !isInstallingPlugin(site: site, slug: plugin.slug),
            getPlugin(slug: plugin.slug, site: site) == nil else {
                return
        }

        state.updatesInProgress[site, default: Set()].insert(plugin.slug)
        track(.pluginInstalled, with: site)
        remote.install(
            pluginSlug: plugin.slug,
            success: { [weak self] installedPlugin in
                self?.transaction { state in
                    state.upsertPlugin(id: installedPlugin.id, site: site, newPlugin: installedPlugin)
                    state.updatesInProgress[site]?.remove(installedPlugin.id)
                }

                let message = String(format: NSLocalizedString("Successfully installed %@.", comment: "Notice displayed after installing a plug-in."), installedPlugin.name)
                ActionDispatcher.dispatch(NoticeAction.post(Notice(title: message)))
                ActionDispatcher.dispatch(PluginAction.activateAndEnableAutoupdates(id: installedPlugin.id, site: site))
            },
            failure: { [weak self] error in
                self?.state.updatesInProgress[site]?.remove(plugin.slug)

                let message = String(format: NSLocalizedString("Error installing %@.", comment: "Notice displayed after attempt to install a plugin fails."), plugin.name)
                self?.notifyRemoteError(message: message, error: error)
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
        track(.pluginUpdated, with: site)

        remote(site: site)?.updatePlugin(
            pluginID: plugin.state.id,
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
        })
    }

    func removePlugin(pluginID: String, site: JetpackSiteRef) {
        guard let sitePlugins = state.plugins[site],
            let plugin = getPlugin(id: pluginID, site: site),
            let index = sitePlugins.plugins.firstIndex(where: { $0.id == pluginID }) else {
                return
        }
        state.plugins[site]?.plugins.remove(at: index)
        track(.pluginRemoved, with: site)

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
                pluginID: plugin.state.id,
                success: {},
                failure: failure)
        }

        if plugin.state.active {
            remote.deactivatePlugin(pluginID: plugin.state.id,
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

    func refreshFeaturedPlugins() {
        guard !isFetchingFeatured() else {
            DDLogInfo("Featured plugins refresh triggered while one was in progress")
            return
        }
        fetchFeaturedPlugins()
    }

    func refreshFeed(feed: PluginDirectoryFeedType) {
        guard !isFetchingFeed(feed: feed) else {
            DDLogInfo("Plugin feed refresh triggered while one was in progress")
            return
        }
        fetchPluginDirectoryFeed(feed: feed)
    }

    func fetchPlugins(site: JetpackSiteRef) {
        guard let remote = remote(site: site) else {
            return
        }
        state.fetching[site] = true
        remote.getPlugins(
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
        if BlogService.blog(with: site)?.isAutomatedTransfer() == true {
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

    func fetchFeaturedPlugins() {
        let anonymousAPI = WordPressComRestApi.defaultApi(userAgent: WPUserAgent.wordPress())
        let remote = PluginServiceRemote(wordPressComRestApi: anonymousAPI)

        state.fetchingFeatured = true

        remote.getFeaturedPlugins(success: { [actionDispatcher] plugins in
            actionDispatcher.dispatch(PluginAction.receiveFeaturedPlugins(plugins: plugins))
        }, failure: { [actionDispatcher] error in
            actionDispatcher.dispatch(PluginAction.receiveFeaturedPluginsFailed(error: error))
        })
    }

    func receiveFeaturedPlugins(plugins: [PluginDirectoryEntry]) {
        let slugs = plugins.map { $0.slug }
        let pluginStates = Dictionary(uniqueKeysWithValues: zip(slugs, plugins.map { PluginDirectoryEntryState.partial($0) }))

        transaction { state in
            state.fetchingFeatured = false
            state.featuredPluginsSlugs = slugs
            state.directoryEntries.merge(pluginStates) { PluginDirectoryEntryState.moreSpecific($0, $1) }
        }
    }

    func fetchPluginDirectoryFeed(feed: PluginDirectoryFeedType) {
        state.fetchingDirectoryFeed[feed.slug] = true

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

    func receivePluginDirectoryFeed(feed: PluginDirectoryFeedType, response: PluginDirectoryFeedPage) {
        let zippedPlugins = zip(response.pageMetadata.pluginSlugs, response.plugins.map { PluginDirectoryEntryState.partial($0)})
        let plugins = Dictionary(uniqueKeysWithValues: zippedPlugins)

        transaction { (state) in
            state.fetchingDirectoryFeed[feed.slug] = false
            state.directoryFeeds[feed.slug] = response.pageMetadata
            state.lastDirectoryFeedFetch[feed.slug] = Date()
            state.directoryEntries.merge(plugins) { PluginDirectoryEntryState.moreSpecific($0, $1) }
        }
    }

    func receivePluginDirectoryFeedFailed(feed: PluginDirectoryFeedType, error: Error) {
        transaction { state in
            state.fetchingDirectoryFeed[feed.slug] = false
            state.lastDirectoryFeedFetch[feed.slug] = Date()
        }
    }

    func notifyRemoteError(message: String, error: Error) {
        logError(message)
        logError(error.localizedDescription)
        ActionDispatcher.dispatch(NoticeAction.post(Notice(title: message)))
    }

    func remote(site: JetpackSiteRef) -> PluginManagementClient? {
        guard site.isSelfHostedWithoutJetpack else {
            return jetpackRemoteClient(site: site)
        }

        return selfHostedRemoteClient(site: site)
    }

    private func jetpackRemoteClient(site: JetpackSiteRef) -> PluginManagementClient? {
        guard let token = CredentialsService().getOAuthToken(site: site) else {
            return nil
        }

        let api = WordPressComRestApi.defaultApi(oAuthToken: token, userAgent: WPUserAgent.wordPress())
        let pluginRemote = PluginServiceRemote(wordPressComRestApi: api)

        return JetpackPluginManagementClient(with: site.siteID, remote: pluginRemote)
    }

    private func selfHostedRemoteClient(site: JetpackSiteRef) -> PluginManagementClient? {
        guard let remote = BlogService.blog(with: site)?.wordPressOrgRestApi else {
            return nil
        }

        return SelfHostedPluginManagementClient(with: remote)
    }

    func track(_ statName: WPAnalyticsStat, with site: JetpackSiteRef) {
        let siteID: NSNumber? = (site.isSelfHostedWithoutJetpack ? nil : site.siteID) as NSNumber?

        WPAppAnalytics.track(statName, withBlogID: siteID)
    }
}
