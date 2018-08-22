import WordPressKit
import WordPressFlux

protocol PluginPresenter: class {
    func present(plugin: Plugin, capabilities: SitePluginCapabilities)
    func present(directoryEntry: PluginDirectoryEntry)
}

class PluginListViewModel: Observable {
    enum PluginResults: Equatable {
        case installed(Plugins)
        case directory([PluginDirectoryEntry])

        init(_ plugins: Plugins) {
            self = .installed(plugins)
        }

        init(_ directoryEntries: [PluginDirectoryEntry]) {
            self = .directory(directoryEntries)
        }

        static func ==(lhs: PluginListViewModel.PluginResults, rhs: PluginListViewModel.PluginResults) -> Bool {
            switch (lhs, rhs) {
            case (.installed(let lhsValue), .installed(let rhsValue)):
                return lhsValue == rhsValue
            case (.directory(let lhsValue), .directory(let rhsValue)):
                return lhsValue == rhsValue
            default: return false
            }
        }
    }

    enum StateChange {
        case replace
        case selective([Int])
    }

    enum State: Equatable {
        case loading
        case ready(PluginResults)
        case error(String)

        static func ==(lhs: PluginListViewModel.State, rhs: PluginListViewModel.State) -> Bool {
            switch (lhs, rhs) {
            case (.loading, .loading):
                return true
            case (.ready(let lhsValue), .ready(let rhsValue)):
                return lhsValue == rhsValue
            case (.error(let lhsValue), .error(let rhsValue)):
                return lhsValue == rhsValue
            default:
                return false
            }
        }

        static func changed(from: State, to: State) -> StateChange {
            switch (from, to) {
            case (.ready(let oldValue), .ready(let newValue)):
                switch (oldValue, newValue) {
                case (.installed(let oldPlugins), .installed(let newPlugins)):
                    guard oldPlugins.plugins.count == newPlugins.plugins.count else {
                        return .replace
                    }

                    return .selective(oldPlugins.plugins.differentIndices(newPlugins.plugins))
                case (.directory(let oldPlugins), .directory(let newPlugins)):
                    guard oldPlugins.count == newPlugins.count else {
                        return .replace
                    }
                    return .selective(oldPlugins.differentIndices(newPlugins))

                default: return.replace

                }
            default:
                return .replace
            }
        }
    }

    let site: JetpackSiteRef
    let changeDispatcher = Dispatcher<Void>()
    let stateChangeDispatcher = Dispatcher<StateChange>()

    private var state: State = .loading {
        didSet {
            guard state != oldValue else {
                return
            }
            stateChangeDispatcher.dispatch(State.changed(from: oldValue, to: state))
        }
    }
    private(set) var refreshing = false {
        didSet {
            if refreshing != oldValue {
                emitChange()
            }
        }
    }

    var query: PluginQuery {
        didSet {
            queryReceipt = store.query(query)
            refreshState()
        }
    }

    private let store: PluginStore
    private var storeReceipt: Receipt?
    private var actionReceipt: Receipt?
    private var queryReceipt: Receipt?

    init(site: JetpackSiteRef, query: PluginQuery, store: PluginStore = StoreContainer.shared.plugin) {
        self.site = site
        self.store = store
        self.query = query
        storeReceipt = store.onChange { [weak self] in
            self?.refreshState()
        }
        actionReceipt = ActionDispatcher.global.subscribe { [weak self] (action) in
            guard let error = self?.receiveError(from: action) else {
                return
            }
            self?.state = .error(error.localizedDescription)
        }
        queryReceipt = store.query(query)
        refreshState()
    }

    func receiveError(from action: Action) -> Error? {
        switch (query, action) {
        case (.all, PluginAction.receivePluginsFailed(let failedSite, let error)):
            guard site == failedSite else {
                return nil
            }
            return error
        case (.feed(let feed), PluginAction.receivePluginDirectoryFeedFailed(let failedFeed, let error)):
            guard feed == failedFeed else {
                return nil
            }
            return error
        default:
            return nil
        }

    }

    func onStateChange(_ handler: @escaping (StateChange) -> Void) -> Receipt {
        return stateChangeDispatcher.subscribe(handler)
    }

    func refresh() {
        let action: PluginAction?

        switch query {
        case .all(let site):
            action = PluginAction.refreshPlugins(site: site)
        case .feed(let feedType):
            action = PluginAction.refreshFeed(feed: feedType)
        default:
            // We don't show this view for `featured` and `search`.
            action = nil
        }

        if let action = action {
            ActionDispatcher.dispatch(action)
        }
    }

    var noResultsViewModel: NoResultsViewController.Model? {
        switch state {
        case .loading:
            return NoResultsViewController.Model(title: NoResultsText.loadingTitle, accessoryView: nil)

        case .ready(let plugins):
            guard case .feed(let feedType) = query,
                case .search = feedType,
                case .directory(let result) = plugins,
                result.count == 0 else {
                    return nil
            }

            return NoResultsViewController.Model(title: NoResultsText.noResultsTitle)

        case .error:
            let appDelegate = WordPressAppDelegate.sharedInstance()
            if (appDelegate?.connectionAvailable)! {
                return NoResultsViewController.Model(title: NoResultsText.errorTitle,
                                                     subtitle: NoResultsText.errorSubtitle,
                                                     buttonText: NoResultsText.errorButtonText)
            } else {
                return NoResultsViewController.Model(title: NoResultsText.noConnectionTitle,
                                                     subtitle: NoResultsText.noConnectionSubtitle)
            }
        }
    }

    func tableViewModel(presenter: PluginPresenter) -> ImmuTable {
        switch state {
        case .loading, .error:
            return .Empty
        case .ready(let plugins):
            let rows: [ImmuTableRow]

            switch plugins {
            case .directory(let directoryEntries):
                rows = directoryEntries.map { entry in
                    PluginListRow(name: entry.name,
                                  author: entry.author,
                                  iconURL: entry.icon,
                                  accessoryView: accessoryView(for: entry),
                                  action: { [weak presenter] _ in presenter?.present(directoryEntry: entry) }
                    )
                }
            case .installed(let installed):
                rows = installed.plugins.map { plugin in
                    PluginListRow(name: plugin.name,
                                  author: plugin.state.author,
                                  iconURL: plugin.directoryEntry?.icon,
                                  accessoryView: accessoryView(for: plugin),
                                  action: { [weak presenter] _ in presenter?.present(plugin: plugin, capabilities: installed.capabilities) }
                    )
                }
            }

            return ImmuTable(sections: [
                ImmuTableSection(rows: rows)
                ])
        }
    }

    static var immutableRows: [ImmuTableRow.Type] {
        return [PluginListRow.self]
    }

    var title: String {
        switch query {
        case .all:
            return NSLocalizedString("Manage", comment: "Screen title, where users can see all their installed plugins.")
        case .feed(.popular):
            return NSLocalizedString("Popular", comment: "Screen title, where users can see the most popular plugins")
        case .feed(.newest):
            return NSLocalizedString("Newest", comment: "Screen title, where users can see the newest plugins")
        case .feed(.search(let term)):
            return term
        case .featured, .directoryEntry:
            return ""
        }
    }

    private func refreshState() {
        refreshing = isFetching(for: query)

        guard !refreshing else {
            if results(for: query) == nil {
                state = .loading
            }
            return
        }

        guard let plugins = results(for: query) else {
            return
        }

        state = .ready(plugins)
    }

    private func accessoryView(`for` directoryEntry: PluginDirectoryEntry) -> UIView {
        if let plugin = store.getPlugin(slug: directoryEntry.slug, site: site) {
            return accessoryView(for: plugin)
        }

        return PluginDirectoryAccessoryItem.accessoryView(plugin: directoryEntry)
    }

    private func accessoryView(`for` plugin: Plugin) -> UIView {
        return PluginDirectoryAccessoryItem.accessoryView(pluginState: plugin.state)
    }

    private func isFetching(`for` query: PluginQuery) -> Bool {
        switch query {

        case .all(let site):
            return store.isFetchingPlugins(site: site)
        case .featured:
            return store.isFetchingFeatured()
        case .feed(let feed):
            return store.isFetchingFeed(feed: feed)
        case .directoryEntry:
            return false
        }
    }

    private func results(`for` query: PluginQuery) -> PluginResults? {
        switch query {

        case .all(let site):
            return store.getPlugins(site: site).flatMap { PluginResults($0) }
        case .featured:
            return store.getFeaturedPlugins().flatMap { PluginResults($0)}
        case .feed(let feed):
            return store.getPluginDirectoryFeedPlugins(from: feed).flatMap { PluginResults($0) }
        case .directoryEntry:
            return nil
        }
    }

    private struct NoResultsText {
        static let loadingTitle = NSLocalizedString("Loading Plugins...", comment: "Text displayed while loading plugins for a site")
        static let noResultsTitle = NSLocalizedString("No plugins found", comment: "Text displayed when search for plugins returns no results")
        static let errorTitle = NSLocalizedString("Oops", comment: "An informal exclaimation that means `something went wrong`.")
        static let errorSubtitle = NSLocalizedString("There was an error loading plugins", comment: "Text displayed when there is a failure loading plugins")
        static let errorButtonText = NSLocalizedString("Contact support", comment: "Button label for contacting support")
        static let noConnectionTitle = NSLocalizedString("No connection", comment: "Title for the error view when there's no connection")
        static let noConnectionSubtitle = NSLocalizedString("An active internet connection is required to view plugins", comment: "Error message shown when trying to view the Plugins feature and there is no internet connection.")
    }

}
