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


    func tableViewModel(presenter: PluginPresenter) -> ImmuTable {

        let configureCell: (PluginDirectoryCollectionViewCell, PluginDirectoryEntry) -> Void = { cell, item in
            let iconPlaceholder = Gridicon.iconOfType(.plugins, withSize: CGSize(width: 98, height: 98))
            cell.logoImageView?.downloadImage(item.icon, placeholderImage: iconPlaceholder)
            cell.authorLabel?.text = item.author
            cell.nameLabel?.text = item.name
        }

        let cellSelected: (PluginDirectoryEntry) -> Void = { [weak self] entry in
            presenter.present(directoryEntry: entry)
        }


        let installed = CollectionViewContainerRow<PluginDirectoryCollectionViewCell, Plugin>(data: self.installed(),
                                                                                              title: "Installed",
                                                                                              configureCollectionCell:
            { cell, plugin in


                let iconPlaceholder = Gridicon.iconOfType(.plugins, withSize: CGSize(width: 98, height: 98))

                cell.nameLabel?.text = plugin.state.name
                cell.authorLabel.text = plugin.state.author
                cell.logoImageView?.downloadImage(plugin.directoryEntry?.icon, placeholderImage: iconPlaceholder)

        },
                                                                                              collectionCellSelected:
            {  plugin in
                presenter.present(directoryEntry: plugin.directoryEntry!)
            }
        )

        let featured =  CollectionViewContainerRow<PluginDirectoryCollectionViewCell, PluginDirectoryEntry>(data: self.featured(),
                                                                                                            title: "Featured",
                                                                                                            configureCollectionCell: configureCell,
                                                                                                            collectionCellSelected: cellSelected)




        let popular = CollectionViewContainerRow<PluginDirectoryCollectionViewCell, PluginDirectoryEntry>(data: self.popular(),
                                                                                                          title: "Popular",
                                                                                                          configureCollectionCell: configureCell,
                                                                                                          collectionCellSelected: cellSelected)



        let new = CollectionViewContainerRow<PluginDirectoryCollectionViewCell, PluginDirectoryEntry>(data: newest(),
                                                                                                             title: "Newest",
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


