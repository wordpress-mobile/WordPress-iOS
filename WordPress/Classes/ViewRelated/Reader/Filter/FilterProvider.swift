import WordPressFlux

class FilterProvider: Observable, FilterTabBarItem {

    enum State {
        case loading
        case ready([TableDataItem])
        case error(Error)

        var isReady: Bool {
            switch self {
            case .ready:
                return true
            case .error, .loading:
                return false
            }
        }
    }

    var title: String {
        return titleFunc(state)
    }

    var state: State = .loading {
        didSet {
            emitChange()
        }
    }

    var items: [TableDataItem] {
        switch state {
        case .loading, .error:
            return []
        case .ready(let items):
            return FilterProvider.filterItems(items, siteType: siteType)
        }
    }

    typealias Provider = (@escaping (Result<[TableDataItem], Error>) -> Void) -> Void

    let accessibilityIdentifier: String
    let cellClass: UITableViewCell.Type
    let reuseIdentifier: String
    let emptyTitle: String
    let emptyActionTitle: String
    let section: ReaderManageScenePresenter.TabbedSection
    let siteType: SiteOrganizationType?

    private let titleFunc: (State?) -> String
    private let provider: Provider

    let changeDispatcher = Dispatcher<Void>()

    init(title: @escaping (State?) -> String,
         accessibilityIdentifier: String,
         cellClass: UITableViewCell.Type,
         reuseIdentifier: String,
         emptyTitle: String,
         emptyActionTitle: String,
         section: ReaderManageScenePresenter.TabbedSection,
         provider: @escaping Provider,
         siteType: SiteOrganizationType? = nil) {

        titleFunc = title
        self.accessibilityIdentifier = accessibilityIdentifier
        self.cellClass = cellClass
        self.reuseIdentifier = reuseIdentifier
        self.emptyTitle = emptyTitle
        self.emptyActionTitle = emptyActionTitle
        self.section = section
        self.provider = provider
        self.siteType = siteType
    }

    func refresh() {
        state = .loading
        provider() { [weak self] result in
            switch result {
            case .success(let items):
                self?.state = .ready(items)
            case .failure(let error):
                self?.state = .error(error)
            }
        }
    }
}

extension FilterProvider {

    func showAdd(on presenterViewController: UIViewController, sceneDelegate: ScenePresenterDelegate?) {
        let presenter = ReaderManageScenePresenter(selected: section, sceneDelegate: sceneDelegate)
        presenter.present(on: presenterViewController, animated: true, completion: nil)
    }

    static func filterItems(_ items: [TableDataItem], siteType: SiteOrganizationType?) -> [TableDataItem] {
        // If a site type is specified, filter items by it.
        // Otherwise, just return all items.
        guard let siteType = siteType else {
            return items
        }

        var filteredItems = [TableDataItem]()

        for item in items {
            if let topic = item.topic as? ReaderSiteTopic,
               topic.organizationType == siteType {
                filteredItems.append(item)
            }
        }

        return filteredItems
    }

}

extension ReaderSiteTopic {

    static func filterProvider(for siteType: SiteOrganizationType?) -> FilterProvider {
        let titleFunction: (FilterProvider.State?) -> String = { state in
            switch state {
            case .loading, .error, .none:
                return NSLocalizedString("Sites", comment: "Sites Filter Tab Title")
            case .ready(let items):
                let filteredItems = FilterProvider.filterItems(items, siteType: siteType)
                return String(format: NSLocalizedString("Sites (%lu)", comment: "Sites Filter Tab Title with Count"), filteredItems.count)
            }
        }

        let emptyTitle = NSLocalizedString("Add a site", comment: "No Tags View Button Label")
        let emptyActionTitle = NSLocalizedString("You can follow posts on a specific site by following it.", comment: "No Sites View Label")

        return FilterProvider(title: titleFunction,
                              accessibilityIdentifier: "SitesFilterTab",
                              cellClass: SiteTableViewCell.self,
                              reuseIdentifier: "Sites",
                              emptyTitle: emptyTitle,
                              emptyActionTitle: emptyActionTitle,
                              section: .sites,
                              provider: tableProvider,
                              siteType: siteType)
    }

    private static func tableProvider(completion: @escaping (Result<[TableDataItem], Error>) -> Void) {
        let completionBlock: (Result<[ReaderSiteTopic], Error>) -> Void = { result in
            let itemResult = result.map { sites in
                sites.filter {!$0.isExternal}
                    .map { topic in
                    return TableDataItem(topic: topic, configure: { cell in
                        cell.textLabel?.text = topic.title
                        cell.detailTextLabel?.text = topic.siteURL
                    })
                }
            }
            completion(itemResult)
        }

        fetchStoredFollowedSites(completion: completionBlock)
        fetchFollowedSites(completion: completionBlock)
    }

    /// Fetch sites from remote service
    ///
    private static func fetchFollowedSites(completion: @escaping (Result<[ReaderSiteTopic], Error>) -> Void) {
        let siteService = ReaderTopicService(managedObjectContext: ContextManager.sharedInstance().mainContext)

        siteService.fetchFollowedSites(success: {
            completion(.success(siteService.allSiteTopics()))
        }, failure: { error in
            DDLogError("Could not sync sites: \(String(describing: error))")
            let remoteServiceError = NSError(domain: WordPressComRestApiErrorDomain, code: -1, userInfo: nil)
            completion(.failure(error ?? remoteServiceError))
        })
    }

    /// Fetch sites from Core Data
    ///
    private static func fetchStoredFollowedSites(completion: @escaping (Result<[ReaderSiteTopic], Error>) -> Void) {
        let siteService = ReaderTopicService(managedObjectContext: ContextManager.sharedInstance().mainContext)
        let sites = siteService.allSiteTopics() ?? []
        completion(.success(sites))
    }

}

extension ReaderTagTopic {

    static func filterProvider() -> FilterProvider {
        let titleFunction: (FilterProvider.State?) -> String = { state in
            switch state {
            case .loading, .error, .none:
                return NSLocalizedString("Topics", comment: "Topics Filter Tab Title")
            case .ready(let items):
                return String(format: NSLocalizedString("Topics (%lu)", comment: "Topics Filter Tab Title with Count"), items.count)
            }
        }

        let emptyTitle = NSLocalizedString("Add a topic", comment: "No Topics View Button Label")
        let emptyActionTitle = NSLocalizedString("You can follow posts on a specific subject by adding a topic.", comment: "No Topics View Label")

        return FilterProvider(title: titleFunction,
                              accessibilityIdentifier: "TagsFilterTab",
                              cellClass: UITableViewCell.self,
                              reuseIdentifier: "Tags",
                              emptyTitle: emptyTitle,
                              emptyActionTitle: emptyActionTitle,
                              section: .tags,
                              provider: tableProvider)
    }

    private static func tableProvider(completion: @escaping (Result<[TableDataItem], Error>) -> Void) {
        fetchFollowedTags(completion: { result in
            let itemResult = result.map { tags in
                tags.map { topic in
                    return TableDataItem(topic: topic, configure: { (cell) in
                        cell.textLabel?.text = topic.slug
                    })
                }
            }
            completion(itemResult)
        })
    }

    static var tagsFetchRequest: NSFetchRequest<NSFetchRequestResult> {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "ReaderTagTopic")
        // Only show following tags, even if the user is logged out
        fetchRequest.predicate = NSPredicate(format: "following == YES AND showInMenu == YES AND type == 'tag'")

        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true, selector: #selector(NSString.localizedCaseInsensitiveCompare))]
        return fetchRequest
    }

    private static func fetchFollowedTags(completion: @escaping (Result<[ReaderTagTopic], Error>) -> Void) {
        do {
            guard let topics = try ContextManager.sharedInstance().mainContext.fetch(tagsFetchRequest) as? [ReaderTagTopic] else {
                return
            }
            completion(.success(topics))
        } catch {
            DDLogError("There was a problem fetching followed tags." + error.localizedDescription)
            completion(.failure(error))
        }
    }
}
