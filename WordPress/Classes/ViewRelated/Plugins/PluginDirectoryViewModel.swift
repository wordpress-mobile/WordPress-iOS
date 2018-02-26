import Foundation
import WordPressFlux
import Gridicons

protocol PluginListPresenter: class {
    func present(site: JetpackSiteRef, query: PluginQuery)
}

class PluginDirectoryViewModel: Observable {

    let site: JetpackSiteRef

    let changeDispatcher = Dispatcher<Void>()

    private let store: PluginStore
    private var storeReceipt: Receipt?

    private var installedReceipt: Receipt?
    private var featuredReceipt: Receipt?
    private var popularReceipt: Receipt?
    private var newReceipt: Receipt?

    public init(site: JetpackSiteRef, store: PluginStore = StoreContainer.shared.plugin) {
        self.store = store
        self.site = site

        installedReceipt = store.query(.all(site: site))
        featuredReceipt = store.query(.featured(site: site))
        popularReceipt = store.query(.feed(type: .popular))
        newReceipt = store.query(.feed(type: .newest))

        storeReceipt = store.onChange { [weak self] in
            self?.changeDispatcher.dispatch()
        }
    }

    func tableViewModel(presenter: PluginPresenter & PluginListPresenter) -> ImmuTable {

        let installedRow = CollectionViewContainerRow(title: NSLocalizedString("Installed", comment: "Header of section in Plugin Directory showing installed plugins"),
                                                      secondaryTitle: NSLocalizedString("Manage", comment: "Button leading to a screen where users can manage their installed plugins"),
                                                      sitePlugins: installedPlugins,
                                                      site: site,
                                                      listViewQuery: .all(site: site),
                                                      presenter: presenter)

        let accessoryViewCallback = { [weak self] (entry: PluginDirectoryEntry) -> UIView in
            guard let strongSelf = self else {
                return UIView()
            }
            return strongSelf.accessoryView(for: entry)
        }
        // We need to be able to map between a `PluginDirectoryEntry` and a potentially already installed `Plugin`,
        // but passing the entire `PluginStore` to the CollectionViewContainerRow isn't the best idea.
        // Instead, we allow the row to reach back to us and ask for the accessoryView.

        let featuredRow = CollectionViewContainerRow(title: NSLocalizedString("Featured", comment: "Header of section in Plugin Directory showing featured plugins"),
                                                     secondaryTitle: nil,
                                                     plugins: featuredPlugins,
                                                     site: site,
                                                     accessoryViewCallback: accessoryViewCallback,
                                                     listViewQuery: nil,
                                                     presenter: presenter)

        let popularRow = CollectionViewContainerRow(title: NSLocalizedString("Popular", comment: "Header of section in Plugin Directory showing popular plugins"),
                                                    secondaryTitle: NSLocalizedString("See All", comment: "Button in Plugin Directory letting users see more plugins"),
                                                    plugins: popularPlugins,
                                                    site: site,
                                                    accessoryViewCallback: accessoryViewCallback,
                                                    listViewQuery: .feed(type: .popular),
                                                    presenter: presenter)

        let newRow = CollectionViewContainerRow(title: NSLocalizedString("New", comment: "Header of section in Plugin Directory showing newest plugins"),
                                                secondaryTitle: NSLocalizedString("See All", comment: "Button in Plugin Directory letting users see more plugins"),
                                                plugins: newPlugins,
                                                site: site,
                                                accessoryViewCallback: accessoryViewCallback,
                                                listViewQuery: .feed(type: .newest),
                                                presenter: presenter)

        return ImmuTable(sections: [
            ImmuTableSection(rows: [
                installedRow,
                featuredRow,
                popularRow,
                newRow,
                ]),
            ])
    }

    private var installedPlugins: Plugins? {
        return store.getPlugins(site: site)
    }

    private var featuredPlugins: [PluginDirectoryEntry] {
        return store.getFeaturedPlugins(site: site) ?? []
    }

    private var popularPlugins: [PluginDirectoryEntry] {
        return Array(store.getPluginDirectoryFeedPlugins(from: .popular)?.prefix(6) ?? [])
    }

    private var newPlugins: [PluginDirectoryEntry] {
        return Array(store.getPluginDirectoryFeedPlugins(from: .newest)?.prefix(6) ?? [])
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
