import SwiftUI

final class BlogListViewModel: NSObject, ObservableObject {
    @Published var recentSites: [BlogListView.Site] = []
    @Published var pinnedSites: [BlogListView.Site] = []
    @Published var allRemainingSites: [BlogListView.Site] = []
    @Published var searchSites: [BlogListView.Site] = []
    var allBlogs: [Blog] = []
    private var searchText: String = ""

    private var pinnedSitesController: NSFetchedResultsController<Blog>?
    private var recentSitesController: NSFetchedResultsController<Blog>?
    private var allBlogsController: NSFetchedResultsController<Blog>?

    private let contextManager: ContextManager
    private let eventTracker: EventTracker

    init(contextManager: ContextManager = ContextManager.sharedInstance(),
         eventTracker: EventTracker = DefaultEventTracker()
    ) {
        self.contextManager = contextManager
        self.eventTracker = eventTracker
        super.init()
        setupFetchedResultsControllers()
    }

    func searchQueryChanged(_ newText: String) {
        searchText = newText
        updateSearchResults()
    }

    func togglePinnedSite(siteID: NSNumber?) {
        guard let siteID, let blog = allBlogs.first(where: { $0.dotComID == siteID }) else {
            return
        }
        let isCurrentlyPinned = blog.pinnedDate != nil

        trackPinned(blog: blog)

        blog.pinnedDate = isCurrentlyPinned ? nil : Date()

        contextManager.saveContextAndWait(contextManager.mainContext)
    }

    func siteSelected(siteID: NSNumber?) {
        guard let siteID, let blog = allBlogs.first(where: { $0.dotComID == siteID }) else {
            return
        }

        trackSiteSelected(blog: blog)

        blog.lastUsed = Date()

        contextManager.saveContextAndWait(contextManager.mainContext)
    }

    private func trackPinned(blog: Blog) {
        eventTracker.track(
            .siteSwitcherPinUpdated,
            properties: [
                "blog_id": blog.dotComID ?? "",
                "pinned": blog.pinnedDate == nil
            ]
        )
    }

    private func trackSiteSelected(blog: Blog) {
        let sectionName: String

        if blog.pinnedDate != nil {
            sectionName = "pinned"
        } else if blog.lastUsed != nil {
            sectionName = "recent"
        } else {
            sectionName = "all"
        }

        eventTracker.track(
            .siteSwitcherSiteTapped,
            properties: [
                "section": sectionName,
            ]
        )
    }

    func viewAppeared() {
        if recentSites.isEmpty && pinnedSites.isEmpty {
            selectedBlog()?.lastUsed = Date()
        }

        contextManager.save(contextManager.mainContext)
    }

    private func selectedBlog() -> Blog? {
        return RootViewCoordinator.sharedPresenter.currentOrLastBlog()
    }
}

extension BlogListView.Site {
    init(blog: Blog) {
        self.init(
            id: blog.dotComID ?? 0,
            title: blog.title ?? "",
            domain: blog.url ?? "",
            imageURL: blog.hasIcon ? URL(string: blog.icon ?? "") : nil
        )
    }
}

extension BlogListViewModel: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        updatePublishedSitesFromControllers()
    }
}

extension BlogListViewModel {
    private func setupFetchedResultsControllers() {
        pinnedSitesController = createResultsController(
            with: NSPredicate(format: "pinnedDate != nil"),
            descriptor: NSSortDescriptor(key: "pinnedDate", ascending: false)
        )
        recentSitesController = createResultsController(
            with: NSPredicate(format: "lastUsed != nil AND pinnedDate == nil"),
            descriptor: NSSortDescriptor(key: "lastUsed", ascending: false),
            fetchLimit: 8
        )
        allBlogsController = createResultsController(
            with: nil,
            descriptor: NSSortDescriptor(key: "settings.name", ascending: true, selector: #selector(NSString.localizedCaseInsensitiveCompare(_:)))
        )

        [
            pinnedSitesController,
            recentSitesController,
            allBlogsController
        ].forEach { [weak self] controller in
            controller?.delegate = self
            try? controller?.performFetch()
        }
        self.updatePublishedSitesFromControllers()
    }

    private func updatePublishedSitesFromControllers() {
        pinnedSites = filteredBlogs(resultsController: pinnedSitesController).compactMap(
            BlogListView.Site.init
        )
        recentSites = filteredBlogs(resultsController: recentSitesController).compactMap(
            BlogListView.Site.init
        )
        allBlogs = filteredBlogs(resultsController: allBlogsController)
        allRemainingSites = allBlogs.compactMap(BlogListView.Site.init).filter({ site in
            return !pinnedSites.contains(site) && !recentSites.contains(site)
        })
        updateSearchResults()
    }

    private func filteredBlogs(resultsController: NSFetchedResultsController<Blog>?) -> [Blog] {
        guard var blogs = resultsController?.fetchedObjects else {
            return []
        }
        if BlogListConfiguration.defaultConfig.shouldHideSelfHostedSites {
            blogs = blogs.filter { $0.isAccessibleThroughWPCom() }
        }
        if BlogListConfiguration.defaultConfig.shouldHideBlogsNotSupportingDomains {
            blogs = blogs.filter { $0.supports(.domains) }
        }
        return blogs
    }

    private func updateSearchResults() {
        if searchText.isEmpty {
            searchSites = allBlogs.compactMap(BlogListView.Site.init)
        } else {
            searchSites = allBlogs
                .filter {
                    $0.url?.lowercased().contains(searchText.lowercased()) == true
                    || $0.title?.lowercased().contains(searchText.lowercased()) == true
                }
                .compactMap(BlogListView.Site.init)
        }
    }

    private func createResultsController(
        with predicate: NSPredicate?,
        descriptor: NSSortDescriptor,
        fetchLimit: Int? = nil
    ) -> NSFetchedResultsController<Blog> {
        let context = contextManager.mainContext
        let request = NSFetchRequest<Blog>(entityName: NSStringFromClass(Blog.self))
        request.predicate = predicate
        request.sortDescriptors = [descriptor]
        if let fetchLimit {
            request.fetchLimit = fetchLimit
        }
        let controller = NSFetchedResultsController(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
        do {
            try controller.performFetch()
        } catch {
            fatalError("Error fetching blogs list: \(error)")
        }
        return controller
    }
}
