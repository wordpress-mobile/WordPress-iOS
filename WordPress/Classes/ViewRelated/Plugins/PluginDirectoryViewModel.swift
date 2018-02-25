import Foundation
import WordPressFlux
import Gridicons

protocol PluginListPresenter: class {
    func present(site: JetpackSiteRef, query: PluginQuery)
}

class PluginDirectoryViewModel: Observable {

    let site: JetpackSiteRef

    let changeDispatcher = Dispatcher<Void>()

    private(set) var refreshing = false {
        didSet {
            if refreshing != oldValue {
                emitChange()
            }
        }
    }
    private let store: PluginStore

    private let installedReceipt: Receipt
    private let featuredReceipt: Receipt
    private let popularReceipt: Receipt
    private let newReceipt: Receipt

    private var storeReceipt: Receipt?
    private var actionReceipt: Receipt?

    public init(site: JetpackSiteRef, store: PluginStore = StoreContainer.shared.plugin) {
        self.store = store
        self.site = site

        installedReceipt = store.query(.all(site: site))
        featuredReceipt = store.query(.featured)
        popularReceipt = store.query(.feed(type: .popular))
        newReceipt = store.query(.feed(type: .newest))

        storeReceipt = store.onChange { [weak self] in
            self?.changeDispatcher.dispatch()
        }

        actionReceipt = ActionDispatcher.global.subscribe { [weak self] (action) in
            self?.refreshRefreshing()
        }

        refreshRefreshing()
    }

    private func refreshRefreshing() {
        refreshing = store.isFetchingPlugins(site: site) ||
            store.isFetchingFeatured() ||
            store.isFetchingFeed(feed: .popular) ||
            store.isFetchingFeed(feed: .newest)
    }

    var noResultsViewModel: WPNoResultsView.Model? {
        guard installedPlugins == nil,
            featuredPlugins == nil,
            popularPlugins == nil,
            newPlugins == nil else {
                // Only show the `no results` view when we have no data to show. otherwise let's just show what we can.
                return nil
        }

        if refreshing {
            let indicatorView = UIActivityIndicatorView(activityIndicatorStyle: .gray)
            indicatorView.startAnimating()
            return WPNoResultsView.Model(title: NSLocalizedString("Loading plugins...", comment: "Messaged displayed when first loading plugins"),
                                         accessoryView: indicatorView)
        }

        return WPNoResultsView.Model(title: NSLocalizedString("Error loading plugins.", comment: "Messaged displayed when fetching plugins failed."),
                                     buttonTitle: NSLocalizedString("Try again", comment: "Button that lets users try to reload the plugin directory after loading failure"))
    }

    func tableViewModel(presenter: PluginPresenter & PluginListPresenter) -> ImmuTable {

        let accessoryViewCallback = { [weak self] (entry: PluginDirectoryEntry) -> UIView in
            guard let strongSelf = self else {
                return UIView()
            }
            return strongSelf.accessoryView(for: entry)
        }
        // We need to be able to map between a `PluginDirectoryEntry` and a potentially already installed `Plugin`,
        // but passing the entire `PluginStore` to the CollectionViewContainerRow isn't the best idea.
        // Instead, we allow the row to reach back to us and ask for the accessoryView.

        var installedRow: ImmuTableRow?
        if let installed = installedPlugins {
            installedRow = CollectionViewContainerRow(title: NSLocalizedString("Installed", comment: "Header of section in Plugin Directory showing installed plugins"),
                                                      secondaryTitle: NSLocalizedString("Manage", comment: "Button leading to a screen where users can manage their installed plugins"),
                                                      sitePlugins: installed,
                                                      site: site,
                                                      listViewQuery: .all(site: site),
                                                      presenter: presenter)
        }

        var featuredRow: ImmuTableRow?
        if let featured = featuredPlugins {
            featuredRow = CollectionViewContainerRow(title: NSLocalizedString("Featured", comment: "Header of section in Plugin Directory showing featured plugins"),
                                                     secondaryTitle: nil,
                                                     plugins: featured,
                                                     site: site,
                                                     accessoryViewCallback: accessoryViewCallback,
                                                     listViewQuery: nil,
                                                     presenter: presenter)
        }

        var popularRow: ImmuTableRow?
        if let popular = popularPlugins {
            popularRow = CollectionViewContainerRow(title: NSLocalizedString("Popular", comment: "Header of section in Plugin Directory showing popular plugins"),
                                                    secondaryTitle: NSLocalizedString("See All", comment: "Button in Plugin Directory letting users see more plugins"),
                                                    plugins: popular,
                                                    site: site,
                                                    accessoryViewCallback: accessoryViewCallback,
                                                    listViewQuery: .feed(type: .popular),
                                                    presenter: presenter)
        }

        var newRow: ImmuTableRow?
        if let new = newPlugins {
            newRow = CollectionViewContainerRow(title: NSLocalizedString("New", comment: "Header of section in Plugin Directory showing newest plugins"),
                                                    secondaryTitle: NSLocalizedString("See All", comment: "Button in Plugin Directory letting users see more plugins"),
                                                    plugins: new,
                                                    site: site,
                                                    accessoryViewCallback: accessoryViewCallback,
                                                    listViewQuery: .feed(type: .newest),
                                                    presenter: presenter)
        }

        return ImmuTable(optionalSections: [
            ImmuTableSection(optionalRows: [
                installedRow,
                featuredRow,
                popularRow,
                newRow,
                ]),
            ])
    }

    public func refresh() {
        ActionDispatcher.dispatch(PluginAction.refreshPlugins(site: site))
        ActionDispatcher.dispatch(PluginAction.refreshFeaturedPlugins)
        ActionDispatcher.dispatch(PluginAction.refreshFeed(feed: .newest))
        ActionDispatcher.dispatch(PluginAction.refreshFeed(feed: .popular))
    }

    private var installedPlugins: Plugins? {
        return store.getPlugins(site: site)
    }

    private var featuredPlugins: [PluginDirectoryEntry]? {
        return store.getFeaturedPlugins()
    }

    private var popularPlugins: [PluginDirectoryEntry]? {
        guard let popular = store.getPluginDirectoryFeedPlugins(from: .popular) else {
            return nil
        }
        return Array(popular.prefix(6))
    }

    private var newPlugins: [PluginDirectoryEntry]? {
        guard let newest = store.getPluginDirectoryFeedPlugins(from: .newest) else {
            return nil
        }
        return Array(newest.prefix(6))
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

}

private extension CollectionViewContainerRow where Item == PluginDirectoryEntry, CollectionViewCellType == PluginDirectoryCollectionViewCell {

    init(title: String,
         secondaryTitle: String?,
         plugins: [PluginDirectoryEntry],
         site: JetpackSiteRef,
         accessoryViewCallback: @escaping ((Item) -> UIView),
         listViewQuery: PluginQuery?,
         presenter: PluginPresenter & PluginListPresenter) {

        let configureCell: (PluginDirectoryCollectionViewCell, PluginDirectoryEntry) -> Void = { cell, item in
            cell.configure(with: item)
            cell.accessoryView = accessoryViewCallback(item)
        }

        let actionClosure: ImmuTableAction = { [weak presenter] _ in
            guard let presenter = presenter, let query = listViewQuery else {
                return
            }

            presenter.present(site: site, query: query)
        }

        let cellSelected: (PluginDirectoryEntry) -> Void = { [weak presenter] entry in
            presenter?.present(directoryEntry: entry)
        }

        self.init(data: plugins,
                  title: title,
                  secondaryTitle: secondaryTitle,
                  action: actionClosure,
                  configureCollectionCell: configureCell,
                  collectionCellSelected: cellSelected)
    }

}

private extension CollectionViewContainerRow where Item == Plugin, CollectionViewCellType == PluginDirectoryCollectionViewCell {
    init(title: String,
         secondaryTitle: String?,
         sitePlugins: Plugins?,
         site: JetpackSiteRef,
         listViewQuery: PluginQuery?,
         presenter: PluginPresenter & PluginListPresenter) {

        let configureCell: (PluginDirectoryCollectionViewCell, Plugin) -> Void = { cell, item in
            cell.configure(with: item)
            cell.accessoryView = PluginDirectoryAccessoryItem.accessoryView(pluginState: item.state)
        }

        let actionClosure: ImmuTableAction = { [weak presenter] _ in
            guard let presenter = presenter, let query = listViewQuery else {
                return
            }

            presenter.present(site: site, query: query)
        }

        let cellSelected: (Plugin) -> Void = { [weak presenter] plugin in
            guard let capabilities = sitePlugins?.capabilities else {
                return
            }
            presenter?.present(plugin: plugin, capabilities: capabilities)
        }

        self.init(data: sitePlugins?.plugins ?? [],
                  title: title,
                  secondaryTitle: secondaryTitle,
                  action: actionClosure,
                  configureCollectionCell: configureCell,
                  collectionCellSelected: cellSelected)
    }
}
