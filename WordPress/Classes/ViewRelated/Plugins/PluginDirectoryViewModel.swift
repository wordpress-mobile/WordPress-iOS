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
    private var searchReceipt: Receipt?

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
    
    func tableViewModel(presenter: PluginPresenter, listPresenter: PluginListPresenter) -> ImmuTable {

        let installedRow = CollectionViewContainerRow<PluginDirectoryCollectionViewCell, Plugin>(
            data: installedPlugins,
            title: NSLocalizedString("Installed", comment: "Header of section in Plugin Directory showing installed plugins"),
            secondaryTitle: NSLocalizedString("Manage", comment: "Button leading to a screen where users can manage their installed plugins"),
            action: actionClosure(presenter: listPresenter, query: .all(site: site)),
            configureCollectionCell: { [weak self] cell, plugin in
                let iconPlaceholder = Gridicon.iconOfType(.plugins, withSize: CGSize(width: 98, height: 98))

                cell.nameLabel?.text = plugin.state.name
                cell.authorLabel.text = plugin.state.author
                cell.logoImageView?.downloadImage(plugin.directoryEntry?.icon, placeholderImage: iconPlaceholder)

                cell.accessoryView = self?.accessoryView(for: plugin)
            },
            collectionCellSelected: { [weak presenter, weak self] plugin in
                guard let capabilities = self?.siteCapabilities else { return }
                presenter?.present(plugin: plugin, capabilities: capabilities)
        })

        let commonRowType = CollectionViewContainerRow<PluginDirectoryCollectionViewCell, PluginDirectoryEntry>.self

        let configureCell: (PluginDirectoryCollectionViewCell, PluginDirectoryEntry) -> Void = { [weak self] cell, item in
            let iconPlaceholder = Gridicon.iconOfType(.plugins, withSize: CGSize(width: 98, height: 98))
            cell.logoImageView?.downloadImage(item.icon, placeholderImage: iconPlaceholder)
            cell.authorLabel?.text = item.author
            cell.nameLabel?.text = item.name

            cell.accessoryView = self?.accessoryView(for: item)
        }

        let cellSelected: (PluginDirectoryEntry) -> Void = { [weak presenter] entry in
            presenter?.present(directoryEntry: entry)
        }

        let featuredRow = commonRowType.init(data: featuredPlugins,
                                             title: NSLocalizedString("Featured", comment: "Header of section in Plugin Directory showing featured plugins"),
                                             secondaryTitle: nil,
                                             action: nil,
                                             configureCollectionCell: configureCell,
                                             collectionCellSelected: cellSelected)

        let popularRow = commonRowType.init(data: popularPlugins,
                                            title: NSLocalizedString("Popular", comment: "Header of section in Plugin Directory showing popular plugins"),
                                            secondaryTitle: NSLocalizedString("See All", comment: "Button in Plugin Directory letting users see more plugins"),
                                            action: actionClosure(presenter: listPresenter, query: .feed(type: .popular)),
                                            configureCollectionCell: configureCell,
                                            collectionCellSelected: cellSelected)

        let newRow = commonRowType.init(data: newPlugins,
                                        title: NSLocalizedString("New", comment: "Header of section in Plugin Directory showing newest plugins"),
                                        secondaryTitle: NSLocalizedString("See All", comment: "Button in Plugin Directory letting users see more plugins"),
                                        action: actionClosure(presenter: listPresenter, query: .feed(type: .newest)),
                                        configureCollectionCell: configureCell,
                                        collectionCellSelected: cellSelected)

        return ImmuTable(optionalSections: [
            ImmuTableSection(rows: [
                installedRow,
                featuredRow,
                popularRow,
                newRow,
                ]),
            ])
    }

    private func actionClosure(presenter: PluginListPresenter, query: PluginQuery) -> ImmuTableAction? {
        return { [weak presenter, weak self] _ in
            guard let site = self?.site else { return }
            presenter?.present(site: site, query: query)
        }
    }

    private var installedPlugins: [Plugin] {
        return store.getPlugins(site: site)?.plugins ?? []
    }

    private var featuredPlugins: [PluginDirectoryEntry] {
        return store.getFeaturedPlugins(site: site)
    }

    private var popularPlugins: [PluginDirectoryEntry] {
        return Array(store.getPluginDirectoryFeedPlugins(from: .popular).prefix(6))
    }

    private var newPlugins: [PluginDirectoryEntry] {
        return Array(store.getPluginDirectoryFeedPlugins(from: .newest).prefix(6))
    }

    private var siteCapabilities: SitePluginCapabilities? {
        return store.getPlugins(site: site)?.capabilities
    }

    private func accessoryView(`for` directoryEntry: PluginDirectoryEntry) -> UIView {
        if let plugin = store.getPlugin(slug: directoryEntry.slug, site: site) {
            return accessoryView(for: plugin)
        }

        return PluginDirectoryAccessoryView.accessoryView(plugin: directoryEntry)
    }

    private func accessoryView(`for` plugin: Plugin) -> UIView {
        return PluginDirectoryAccessoryView.accessoryView(pluginState: plugin.state)
    }

}
