import Foundation
import WordPressFlux
import Gridicons

class PluginDirectoryViewModel: Observable {
    var searchTerm: String? = nil {
        didSet {
            changeDispatcher.dispatch()
        }
    }

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

        if let term = searchTerm {
            searchReceipt = store.query(.feed(type: .search(term: term)))
        }

        storeReceipt = store.onChange { [weak self] in
            self?.changeDispatcher.dispatch()
            return
        }
    }

    func popular() -> [PluginDirectoryEntry] {
        return Array(store.getPluginDirectoryFeedPlugins(from: .popular).prefix(6))
    }

    func newest() -> [PluginDirectoryEntry] {
        return Array(store.getPluginDirectoryFeedPlugins(from: .newest).prefix(6))
    }

    func featured() -> [PluginDirectoryEntry] {
        return store.getFeaturedPlugins(site: site)
    }

    func installed() -> [Plugin] {
        return store.getPlugins(site: site)?.plugins ?? []
    }

    private func accessoryView(`for` directoryEntry: PluginDirectoryEntry) -> UIView {
        if let plugin = store.getPlugin(slug: directoryEntry.slug, site: site) {
            return accessoryView(for: plugin)
        }

        return PluginDirectoryAccessoryView.stars(count: directoryEntry.starRating)
    }

    private func accessoryView(`for` plugin: Plugin) -> UIView {

        guard plugin.state.active else {
            return PluginDirectoryAccessoryView.inactive()
        }

        switch plugin.state.updateState {
        case .available:
            return PluginDirectoryAccessoryView.needsUpdate()
        case .updating:
            return PluginDirectoryAccessoryView.updating()
        case .updated:
            return PluginDirectoryAccessoryView.active()
        }
    }

    func tableViewModel(presenter: PluginPresenter) -> ImmuTable {

        let configureCell: (PluginDirectoryCollectionViewCell, PluginDirectoryEntry) -> Void = { [weak self] cell, item in
            let iconPlaceholder = Gridicon.iconOfType(.plugins, withSize: CGSize(width: 98, height: 98))
            cell.logoImageView?.downloadImage(item.icon, placeholderImage: iconPlaceholder)
            cell.authorLabel?.text = item.author
            cell.nameLabel?.text = item.name

            cell.accessoryView = self?.accessoryView(for: item)
        }

        let cellSelected: (PluginDirectoryEntry) -> Void = { [weak self] entry in
            presenter.present(directoryEntry: entry)
        }


        let installed = CollectionViewContainerRow<PluginDirectoryCollectionViewCell, Plugin>(data: self.installed(),
                                                                                              title: NSLocalizedString("Installed", comment: "Header of section in Plugin Directory showing installed plugins"),
                                                                                              secondaryTitle: NSLocalizedString("Manage", comment: "Button leading to a screen where users can manage their installed plugins"),
                                                                                              action: { _ in dump("installed"); return },
                                                                                              configureCollectionCell:
            { [weak self] cell, plugin in


                let iconPlaceholder = Gridicon.iconOfType(.plugins, withSize: CGSize(width: 98, height: 98))

                cell.nameLabel?.text = plugin.state.name
                cell.authorLabel.text = plugin.state.author
                cell.logoImageView?.downloadImage(plugin.directoryEntry?.icon, placeholderImage: iconPlaceholder)

                cell.accessoryView = self?.accessoryView(for: plugin)


        },
                                                                                              collectionCellSelected:
            {  plugin in
                presenter.present(directoryEntry: plugin.directoryEntry!)
            }
        )

        let commonRowType = CollectionViewContainerRow<PluginDirectoryCollectionViewCell, PluginDirectoryEntry>.self

        let featured = commonRowType.init(data: self.featured(),
                                          title: NSLocalizedString("Featured", comment: "Header of section in Plugin Directory showing featured plugins"),
                                           secondaryTitle: nil,
                                           action: nil,
                                           configureCollectionCell: configureCell,
                                           collectionCellSelected: cellSelected)

        let popular = commonRowType.init(data: self.popular(),
                                         title: NSLocalizedString("Popular", comment: "Header of section in Plugin Directory showing popular plugins"),
                                         secondaryTitle: NSLocalizedString("See All", comment: "Button in Plugin Directory letting users see more plugins"),
                                         action: { _ in dump("pop"); return },
                                         configureCollectionCell: configureCell,
                                         collectionCellSelected: cellSelected)

        let new = commonRowType.init(data: newest(),
                                     title: NSLocalizedString("New", comment: "Header of section in Plugin Directory showing newest plugins"),
                                     secondaryTitle: NSLocalizedString("See All", comment: "Button in Plugin Directory letting users see more plugins"),
                                     action: { _ in dump("new"); return},
                                     configureCollectionCell: configureCell,
                                     collectionCellSelected: cellSelected)

        return ImmuTable(optionalSections: [
            ImmuTableSection(rows: [
                installed,
                featured,
                popular,
                new,
            ]),
        ])
    }
}


