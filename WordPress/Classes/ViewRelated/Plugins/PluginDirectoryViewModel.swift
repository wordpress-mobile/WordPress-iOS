import Foundation
import WordPressFlux
import Gridicons

protocol PluginListPresenter: AnyObject {
    func present(site: JetpackSiteRef, query: PluginQuery)
}

class PluginDirectoryViewModel: Observable {

    let site: JetpackSiteRef

    let changeDispatcher = Dispatcher<Void>()

    weak var noResultsDelegate: NoResultsViewControllerDelegate?

    private let store: PluginStore

    private let installedReceipt: Receipt
    private let featuredReceipt: Receipt
    private let popularReceipt: Receipt
    private let newReceipt: Receipt

    private var actionReceipt: Receipt?

    private let throttle = Scheduler(seconds: 1)

    public init(site: JetpackSiteRef, store: PluginStore = StoreContainer.shared.plugin) {
        self.store = store
        self.site = site

        installedReceipt = store.query(.all(site: site))
        featuredReceipt = store.query(.featured)
        popularReceipt = store.query(.feed(type: .popular))
        newReceipt = store.query(.feed(type: .newest))

        actionReceipt = ActionDispatcher.global.subscribe { [changeDispatcher, throttle] action in
            // Fairly often, a bunch of those network calls can finish very close to each other — within few hundred
            // milliseconds or so. Doing a reload in this case is both wasteful and noticably slow.
            // Instead, we throttle the call so we trigger the reload at most once a second.
            throttle.throttle {
                changeDispatcher.dispatch()
            }
        }
    }

    func reloadFailed() {
        allQueries
            .filter { !isFetching(for: $0) }
            .filter { !hasResults(for: $0) }
            .compactMap { refreshAction(for: $0) }
            .forEach { ActionDispatcher.dispatch($0) }
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

    private func hasResults(`for` query: PluginQuery) -> Bool {
        switch query {

        case .all:
            return installedPlugins != nil
        case .featured:
            return featuredPlugins != nil
        case .feed(.popular):
            return popularPlugins != nil
        case .feed(.newest):
            return newPlugins != nil
        case .feed(.search):
            return false
        case .directoryEntry:
            return false
        }
    }

    private func noResultsView(for query: PluginQuery) -> NoResultsViewController? {
        guard hasResults(for: query) == false else {
            return nil
        }

        let noResultsView = NoResultsViewController.controller()
        noResultsView.delegate = noResultsDelegate
        noResultsView.hideImageView()
        let model: NoResultsViewController.Model

        if isFetching(for: query) {
            model = NoResultsViewController.Model(title: NSLocalizedString("Loading plugins...", comment: "Messaged displayed when fetching plugins."),
                                                  accessoryView: NoResultsViewController.loadingAccessoryView())
        } else {
            model = NoResultsViewController.Model(title: NSLocalizedString("Error loading plugins", comment: "Messaged displayed when fetching plugins failed."),
                                                  buttonText: NSLocalizedString("Try again", comment: "Button that lets users try to reload the plugin directory after loading failure"))
        }

        noResultsView.bindViewModel(model)
        return noResultsView
    }

    private func installedRow(presenter: PluginPresenter & PluginListPresenter) -> ImmuTableRow? {
        guard BlogService.blog(with: site)?.isHostedAtWPcom == false else {
            // If it's a (probably) AT-eligible site, but not a Jetpack site yet, hide the "installed" row.
            return nil
        }


        let title = NSLocalizedString("Installed", comment: "Header of section in Plugin Directory showing installed plugins")
        let secondaryTitle = NSLocalizedString("Manage", comment: "Button leading to a screen where users can manage their installed plugins")
        let query = PluginQuery.all(site: site)

        if let installed = installedPlugins {
            return CollectionViewContainerRow(title: title,
                                              secondaryTitle: secondaryTitle,
                                              sitePlugins: installed,
                                              site: site,
                                              listViewQuery: query,
                                              presenter: presenter)
        } else if let noResults = noResultsView(for: query) {
            return CollectionViewContainerRow(title: title,
                                              secondaryTitle: secondaryTitle,
                                              site: site,
                                              listViewQuery: query,
                                              noResultsView: noResults,
                                              presenter: presenter)
        }
        return nil
    }

    private func featuredRow(presenter: PluginPresenter & PluginListPresenter) -> ImmuTableRow? {
        let title = NSLocalizedString("Featured", comment: "Header of section in Plugin Directory showing featured plugins")

        if let featured = featuredPlugins {
            return CollectionViewContainerRow(title: title,
                                              secondaryTitle: nil,
                                              plugins: featured,
                                              site: site,
                                              accessoryViewCallback: accessoryViewCallback,
                                              listViewQuery: nil,
                                              presenter: presenter)
        } else if let noResults = noResultsView(for: .featured) {
            return CollectionViewContainerRow(title: title,
                                              secondaryTitle: nil,
                                              site: site,
                                              listViewQuery: nil,
                                              noResultsView: noResults,
                                              presenter: presenter)
        }
        return nil
    }

    private func popularRow(presenter: PluginPresenter & PluginListPresenter) -> ImmuTableRow? {
        let title = NSLocalizedString("Popular", comment: "Header of section in Plugin Directory showing popular plugins")
        let secondaryTitle = NSLocalizedString("See All", comment: "Button in Plugin Directory letting users see more plugins")
        let query = PluginQuery.feed(type: .popular)

        if let popular = popularPlugins {
            return CollectionViewContainerRow(title: title,
                                              secondaryTitle: secondaryTitle,
                                              plugins: popular,
                                              site: site,
                                              accessoryViewCallback: accessoryViewCallback,
                                              listViewQuery: query,
                                              presenter: presenter)
        } else if let noResults = noResultsView(for: query) {
            return CollectionViewContainerRow(title: title,
                                              secondaryTitle: secondaryTitle,
                                              site: site,
                                              listViewQuery: query,
                                              noResultsView: noResults,
                                              presenter: presenter)
        }
        return nil
    }

    private func newRow(presenter: PluginPresenter & PluginListPresenter) -> ImmuTableRow? {
        let title = NSLocalizedString("New", comment: "Header of section in Plugin Directory showing newest plugins")
        let secondaryTitle = NSLocalizedString("See All", comment: "Button in Plugin Directory letting users see more plugins")
        let query = PluginQuery.feed(type: .newest)

        if let new = newPlugins {
            return CollectionViewContainerRow(title: title,
                                                secondaryTitle: secondaryTitle,
                                                plugins: new,
                                                site: site,
                                                accessoryViewCallback: accessoryViewCallback,
                                                listViewQuery: query,
                                                presenter: presenter)
        } else if let noResults = noResultsView(for: query) {
            return CollectionViewContainerRow(title: title,
                                              secondaryTitle: secondaryTitle,
                                              site: site,
                                              listViewQuery: query,
                                              noResultsView: noResults,
                                              presenter: presenter)
        }

        return nil
    }

    private var accessoryViewCallback: ((PluginDirectoryEntry) -> UIView) {
        // We need to be able to map between a `PluginDirectoryEntry` and a potentially already installed `Plugin`,
        // but passing the entire `PluginStore` to the CollectionViewContainerRow isn't the best idea.
        // Instead, we allow the row to reach back to us and ask for the accessoryView.
        return { [weak self] (entry: PluginDirectoryEntry) -> UIView in
            guard let strongSelf = self else {
                return UIView()
            }
            return strongSelf.accessoryView(for: entry)
        }
    }

    func tableViewModel(presenter: PluginPresenter & PluginListPresenter) -> ImmuTable {
        return ImmuTable(optionalSections: [
            ImmuTableSection(optionalRows: [
                installedRow(presenter: presenter),
                featuredRow(presenter: presenter),
                popularRow(presenter: presenter),
                newRow(presenter: presenter),
                ]),
            ])
    }

    public func refresh() {
        allQueries
            .compactMap { refreshAction(for: $0) }
            .forEach { ActionDispatcher.dispatch($0) }
    }

    private var allQueries: [PluginQuery] {
        return [.all(site: site),
                .featured,
                .feed(type: .popular),
                .feed(type: .newest)]
    }

    private func refreshAction(`for` query: PluginQuery) -> PluginAction? {
        switch query {
        case .all(let site):
            return PluginAction.refreshPlugins(site: site)
        case .featured:
            return PluginAction.refreshFeaturedPlugins
        case .feed(let feedType):
            return PluginAction.refreshFeed(feed: feedType)
        case .directoryEntry:
            return nil
        }
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

private extension CollectionViewContainerRow where Item == Any, CollectionViewCellType == PluginDirectoryCollectionViewCell {
    init(title: String,
         secondaryTitle: String?,
         site: JetpackSiteRef,
         listViewQuery: PluginQuery?,
         noResultsView: NoResultsViewController,
         presenter: PluginPresenter & PluginListPresenter) {

        let actionClosure: ImmuTableAction = { [weak presenter] _ in
            guard let presenter = presenter, let query = listViewQuery else {
                return
            }

            presenter.present(site: site, query: query)
        }

        self.init(title: title,
                   secondaryTitle: secondaryTitle,
                   action: actionClosure,
                   noResultsView: noResultsView)
    }
}
