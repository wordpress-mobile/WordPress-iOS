import WordPressKit
import WordPressFlux

protocol PluginPresenter: class {
    func present(plugin: Plugin, capabilities: SitePluginCapabilities)
}

class PluginListViewModel: Observable {
    enum StateChange {
        case replace
        case selective([Int])
    }

    enum State: Equatable {
        case loading
        case ready(Plugins)
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
                guard oldValue.plugins.count == newValue.plugins.count else {
                    return .replace
                }
                return .selective(oldValue.plugins.differentIndices(newValue.plugins))
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

    private let store: PluginStore
    private var storeReceipt: Receipt?
    private var actionReceipt: Receipt?
    private var queryReceipt: Receipt?

    init(site: JetpackSiteRef, store: PluginStore = StoreContainer.shared.plugin) {
        self.site = site
        self.store = store
        storeReceipt = store.onChange { [weak self] in
            self?.refreshState()
        }
        actionReceipt = ActionDispatcher.global.subscribe { [weak self] (action) in
            guard case PluginAction.receivePluginsFailed(let receivedSite, let error) = action,
                case receivedSite = site else {
                    return
            }
            self?.state = .error(error.localizedDescription)
        }
        queryReceipt = store.query(.all(site: site))
        refreshState()
    }

    func onStateChange(_ handler: @escaping (StateChange) -> Void) -> Receipt {
        return stateChangeDispatcher.subscribe(handler)
    }

    var noResultsViewModel: WPNoResultsView.Model? {
        switch state {
        case .loading:
            return WPNoResultsView.Model(
                title: NSLocalizedString("Loading Plugins...", comment: "Text displayed while loading plugins for a site")
            )
        case .ready:
            return nil
        case .error:
            let appDelegate = WordPressAppDelegate.sharedInstance()
            if (appDelegate?.connectionAvailable)! {
                return WPNoResultsView.Model(
                    title: NSLocalizedString("Oops", comment: ""),
                    message: NSLocalizedString("There was an error loading plugins", comment: ""),
                    buttonTitle: NSLocalizedString("Contact support", comment: "")
                )
            } else {
                return WPNoResultsView.Model(
                    title: NSLocalizedString("No connection", comment: ""),
                    message: NSLocalizedString("An active internet connection is required to view plugins", comment: "")
                )
            }
        }
    }

    func tableViewModel(presenter: PluginPresenter) -> ImmuTable {
        switch state {
        case .loading, .error:
            return .Empty
        case .ready(let plugins):
            let rows = plugins.plugins.map({ plugin in
                return PluginListRow(
                    name: plugin.name,
                    state: plugin.state.stateDescription,
                    iconURL: plugin.directoryEntry?.icon,
                    updateState: plugin.state.updateState,
                    action: { [weak presenter] (row) in
                        presenter?.present(plugin: plugin, capabilities: plugins.capabilities)
                })
            })
            return ImmuTable(sections: [
                ImmuTableSection(rows: rows)
                ])
        }
    }

    static var immutableRows: [ImmuTableRow.Type] {
        return [PluginListRow.self]
    }

    private func refreshState() {
        refreshing = store.isFetchingPlugins(site: site)
        guard let plugins = store.getPlugins(site: site) else {
            return
        }
        state = .ready(plugins)
    }
}
