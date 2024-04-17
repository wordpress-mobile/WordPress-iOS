import SwiftUI

final class BlogListViewModel: NSObject, ObservableObject {
    @Published var recentSites: [BlogListView.Site] = []
    @Published var pinnedSites: [BlogListView.Site] = []
    @Published var allRemainingSites: [BlogListView.Site] = []
    @Published var searchSites: [BlogListView.Site] = []
    var allBlogs: [Blog] = []

    private var pinnedSitesController: NSFetchedResultsController<Blog>?
    private var recentSitesController: NSFetchedResultsController<Blog>?
    private var allRemainingSitesController: NSFetchedResultsController<Blog>?
    private var allBlogsController: NSFetchedResultsController<Blog>?

    private let contextManager: ContextManager

    init(contextManager: ContextManager = ContextManager.sharedInstance()) {
        self.contextManager = contextManager
        super.init()
        setupFetchedResultsControllers()
    }

    func updateSearchText(_ newText: String) {
        if newText.isEmpty {
            searchSites = allBlogs.compactMap(BlogListView.Site.init)
        } else {
            searchSites = allBlogs
                .filter {
                    $0.url?.lowercased().contains(newText.lowercased()) == true
                    || $0.title?.lowercased().contains(newText.lowercased()) == true
                }
                .compactMap(BlogListView.Site.init)
        }
    }

    func togglePinnedSite(siteID: NSNumber?) {
        guard let blog = allBlogs.first(where: { $0.dotComID == siteID }) else {
            return
        }

        blog.pinnedDate = blog.pinnedDate == nil ? Date() : nil
        contextManager.save(contextManager.mainContext)
    }

    func siteSelected(siteID: NSNumber?) {
        guard let blog = allBlogs.first(where: { $0.dotComID == siteID }) else {
            return
        }

        blog.lastUsed = Date()
        contextManager.save(contextManager.mainContext)
    }
}

extension BlogListView.Site {
    init(blog: Blog) {
        self.init(
            id: blog.dotComID,
            title: blog.title ?? "",
            domain: blog.url ?? "",
            imageURL: blog.hasIcon ? URL(string: blog.icon!) : nil
        )
    }
}

extension BlogListViewModel: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        if controller == pinnedSitesController {
            pinnedSites = (controller.fetchedObjects as? [Blog] ?? []).compactMap(BlogListView.Site.init)
        } else if controller == recentSitesController {
            recentSites = (controller.fetchedObjects as? [Blog] ?? []).compactMap(BlogListView.Site.init)
        } else if controller == allRemainingSitesController {
            allRemainingSites = (controller.fetchedObjects as? [Blog] ?? []).compactMap(BlogListView.Site.init)
        } else if controller == allBlogsController {
            allBlogs = controller.fetchedObjects as? [Blog] ?? []
            searchSites = allBlogs.compactMap(BlogListView.Site.init)
        }
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
        allRemainingSitesController = createResultsController(
            with: NSPredicate(format: "lastUsed == nil AND pinnedDate == nil"),
            descriptor: NSSortDescriptor(key: "settings.name", ascending: true, selector: #selector(NSString.localizedCaseInsensitiveCompare(_:)))
        )
        allBlogsController = createResultsController(
            with: nil,
            descriptor: NSSortDescriptor(key: "accountForDefaultBlog.userID", ascending: false)
        )

        [
            pinnedSitesController,
            recentSitesController,
            allRemainingSitesController,
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
        allRemainingSites = filteredBlogs(resultsController: allRemainingSitesController).compactMap(
            BlogListView.Site.init
        )
        allBlogs = filteredBlogs(resultsController: allBlogsController)
        searchSites = allBlogs.compactMap(BlogListView.Site.init)
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
