import WordPressFlux

class FilterProvider: NSObject, Identifiable, Observable, FilterTabBarItem {

    let id: UUID = UUID()

    enum FilterProviderError: Error {
        case notAuthorized
    }

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

    /// Closure block that's responsible for populating the items for this `FilterProvider`.
    ///
    /// The `localOnly` parameter provides information for the closure on whether the fetch should happen
    /// locally or remotely, but whether this parameter is honored or not depends on the actual implementation.
    ///
    /// - Parameters:
    ///     - localOnly: Specifies whether the fetch process should happen locally or remotely.
    ///     - completion: The closure to be called once the fetching process completes.
    typealias Provider = (_ localOnly: Bool, _ completion: @escaping (Result<[TableDataItem], Error>) -> Void) -> Void

    let accessibilityIdentifier: String
    let cellClass: UITableViewCell.Type
    let reuseIdentifier: String
    let emptyTitle: String
    let section: ReaderManageScenePresenter.TabbedSection
    let siteType: SiteOrganizationType?

    /// Notifies when there are changes made to the `ReaderAbstractTopic` model depended by this provider.
    let observer: ReaderTopicObserving?

    private let titleFunc: (State?) -> String
    private let provider: Provider

    let changeDispatcher = Dispatcher<Void>()

    init(title: @escaping (State?) -> String,
         accessibilityIdentifier: String,
         cellClass: UITableViewCell.Type,
         reuseIdentifier: String,
         emptyTitle: String,
         section: ReaderManageScenePresenter.TabbedSection,
         provider: @escaping Provider,
         siteType: SiteOrganizationType? = nil,
         observer: ReaderTopicObserving? = nil) {

        titleFunc = title
        self.accessibilityIdentifier = accessibilityIdentifier
        self.cellClass = cellClass
        self.reuseIdentifier = reuseIdentifier
        self.emptyTitle = emptyTitle
        self.section = section
        self.provider = provider
        self.siteType = siteType
        self.observer = observer

        super.init()
        self.observer?.delegate = self
    }

    func refresh(localOnly: Bool = false) {
        state = .loading
        provider(localOnly) { [weak self] result in
            switch result {
            case .success(let items):
                self?.state = .ready(items)
            case .failure(let error):
                self?.state = .error(error)
            }
        }
    }

    struct ReuseIdentifiers {
        static let blogs = "blogs"
        static let tags = "tags"
    }
}

extension FilterProvider: ReaderTopicObserverDelegate {
    func readerTopicDidChange() {
        // TODO: Revisit and think of better approach.
        // IMPORTANT — This is a workaround. At this stage, we need to ensure that the data is *only* refreshed
        // from the local store, because pulling from remote will trigger the observer again and causing a loop!
        refresh(localOnly: true)
    }
}

extension FilterProvider {
    static func == (lhs: FilterProvider, rhs: FilterProvider) -> Bool {
        return lhs.title == rhs.title
    }
}

extension FilterProvider {

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
                return Strings.unnumberedFilterTitle
            case .ready(let items):
                let filteredItems = FilterProvider.filterItems(items, siteType: siteType)
                return String(format: filteredItems.count == 1 ? Strings.singularFilterTitle : Strings.pluralFilterTitle, filteredItems.count)
            }
        }

        let emptyTitle = NSLocalizedString(
            "reader.no.blog.title",
            value: "Add a blog",
            comment: "No Tags View Button Label"
        )

        return FilterProvider(title: titleFunction,
                              accessibilityIdentifier: "SitesFilterTab",
                              cellClass: SiteTableViewCell.self,
                              reuseIdentifier: FilterProvider.ReuseIdentifiers.blogs,
                              emptyTitle: emptyTitle,
                              section: .sites,
                              provider: tableProvider,
                              siteType: siteType,
                              observer: ReaderTopicChangeObserver<ReaderSiteTopic>())
    }

    private static func tableProvider(localOnly: Bool = false,
                                      completion: @escaping (Result<[TableDataItem], Error>) -> Void) {
        let completionBlock: (Result<[ReaderSiteTopic], Error>) -> Void = { result in
            let itemResult = result.map { sites in
                sites.map { topic in
                    return TableDataItem(topic: topic, configure: { cell in
                        cell.imageView?.downloadSiteIcon(at: topic.siteBlavatar)
                        cell.textLabel?.text = topic.title
                        cell.detailTextLabel?.text = topic.siteURL
                        addUnseenPostCount(topic, with: cell)
                    })
                }
            }
            completion(itemResult)
        }

        // User needs to be logged in to follow sites.
        guard ReaderHelpers.isLoggedIn() else {
            completionBlock(.failure(FilterProvider.FilterProviderError.notAuthorized))
            return
        }

        fetchStoredFollowedSites(completion: completionBlock)

        if !localOnly {
            fetchFollowedSites(completion: completionBlock)
        }
    }

    /// Fetch sites from remote service
    ///
    private static func fetchFollowedSites(completion: @escaping (Result<[ReaderSiteTopic], Error>) -> Void) {
        let siteService = ReaderTopicService(coreDataStack: ContextManager.shared)

        siteService.fetchAllFollowedSites(success: {
            let sites = (try? ReaderAbstractTopic.lookupAllSites(in: ContextManager.shared.mainContext)) ?? []
            completion(.success(sites))
        }, failure: { error in
            DDLogError("Could not sync sites: \(String(describing: error))")
            let remoteServiceError = NSError(domain: WordPressComRestApiErrorDomain, code: -1, userInfo: nil)
            completion(.failure(error ?? remoteServiceError))
        })
    }

    /// Fetch sites from Core Data
    ///
    private static func fetchStoredFollowedSites(completion: @escaping (Result<[ReaderSiteTopic], Error>) -> Void) {
        let sites = (try? ReaderAbstractTopic.lookupAllSites(in: ContextManager.shared.mainContext)) ?? []
        completion(.success(sites))
    }

    /// Adds a custom accessory view displaying the unseen post count.
    ///
    private static func addUnseenPostCount(_ topic: ReaderSiteTopic, with cell: UITableViewCell) {

        // Always reset first.
        cell.accessoryView = nil

        guard topic.unseenCount > 0 else {
            return
        }

        // Create background view
        let unseenCountView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: UnseenCountConstants.viewSize))
        unseenCountView.layer.cornerRadius = UnseenCountConstants.cornerRadius
        unseenCountView.backgroundColor =  .tertiaryFill

        // Create count label
        let countLabel = UILabel()
        countLabel.font = WPStyleGuide.subtitleFont()
        countLabel.textColor = .text
        countLabel.backgroundColor = .clear
        countLabel.text = topic.unseenCount.abbreviatedString()

        let accessibilityFormat = topic.unseenCount == 1 ? UnseenCountConstants.singularUnseen : UnseenCountConstants.pluralUnseen
        countLabel.accessibilityLabel = String(format: accessibilityFormat, topic.unseenCount)

        countLabel.sizeToFit()

        // Resize views
        unseenCountView.frame.size.width = max(countLabel.frame.width + UnseenCountConstants.labelPadding, UnseenCountConstants.viewSize)
        countLabel.center = unseenCountView.center

        // Display in cell's accessory view
        unseenCountView.addSubview(countLabel)
        cell.accessoryView = unseenCountView
    }

    private struct UnseenCountConstants {
        static let cornerRadius: CGFloat = 15
        static let viewSize: CGFloat = 30
        static let labelPadding: CGFloat = 20
        static let singularUnseen = NSLocalizedString("%1$d unseen post", comment: "Format string for single unseen post count. The %1$d is a placeholder for the count.")
        static let pluralUnseen = NSLocalizedString("%1$d unseen posts", comment: "Format string for plural unseen posts count. The %1$d is a placeholder for the count.")
    }

    private struct Strings {
        static let unnumberedFilterTitle = NSLocalizedString(
            "reader.navigation.filter.blog.unspecified",
            value: "Blogs",
            comment: """
                Button title to filter the Reader stream by blog.
                This is displayed when we don't know the number of blogs yet.
                """
        )

        static let singularFilterTitle = NSLocalizedString(
            "reader.navigation.filter.blog.singular",
            value: "%1$d Blog",
            comment: """
                Singular button title to filter the Reader stream by blog.
                %1$d is a placeholder for the number of blogs.
                """
        )

        static let pluralFilterTitle = NSLocalizedString(
            "reader.navigation.filter.blog.plural",
            value: "%1$d Blogs",
            comment: """
                Plural button title to filter the Reader stream by blog.
                %1$d is a placeholder for the number of blogs.
                """
        )
    }

}

extension ReaderTagTopic {

    static func filterProvider() -> FilterProvider {
        let titleFunction: (FilterProvider.State?) -> String = { state in
            switch state {
            case .loading, .error, .none:
                return Strings.unnumberedFilterTitle
            case .ready(let items):
                return String(format: items.count == 1 ? Strings.singularFilterTitle : Strings.pluralFilterTitle, items.count)
            }
        }

        let emptyTitle = NSLocalizedString(
            "reader.no.tags.title",
            value: "Add a tag",
            comment: "No Tags View Button Label"
        )

        return FilterProvider(title: titleFunction,
                              accessibilityIdentifier: "TagsFilterTab",
                              cellClass: UITableViewCell.self,
                              reuseIdentifier: FilterProvider.ReuseIdentifiers.tags,
                              emptyTitle: emptyTitle,
                              section: .tags,
                              provider: tableProvider,
                              observer: ReaderTopicChangeObserver<ReaderTagTopic>())
    }

    private static func tableProvider(localOnly: Bool = false,
                                      completion: @escaping (Result<[TableDataItem], Error>) -> Void) {
        fetchFollowedTags(completion: { result in
            let itemResult = result.map { tags in
                tags.map { topic in
                    return TableDataItem(topic: topic, configure: { (cell) in
                        cell.textLabel?.text = topic.slugForDisplay
                        cell.textLabel?.font = UIFont.preferredFont(forTextStyle: .callout)
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

    private struct Strings {
        static let unnumberedFilterTitle = NSLocalizedString(
            "reader.navigation.filter.tag.unnumbered",
            value: "Tags",
            comment: """
                Button title to filter the Reader stream by tag.
                This is displayed when we don't know the number of tags yet.
                """
        )

        static let singularFilterTitle = NSLocalizedString(
            "reader.navigation.filter.tag.singular",
            value: "%1$d Tag",
            comment: """
                Singular button title to filter the Reader stream by tag.
                %1$d is a placeholder for the number of tags.
                """
        )

        static let pluralFilterTitle = NSLocalizedString(
            "reader.navigation.filter.tag.plural",
            value: "%1$d Tags",
            comment: """
                Plural button title to filter the Reader stream by tag.
                %1$d is a placeholder for the number of tags.
                """
        )
    }
}
