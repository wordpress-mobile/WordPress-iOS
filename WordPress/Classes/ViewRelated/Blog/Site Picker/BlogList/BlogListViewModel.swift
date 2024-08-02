import CoreData
import SwiftUI

final class BlogListViewModel: NSObject, ObservableObject {
    @Published var searchText = "" {
        didSet { updateSearchResults() }
    }

    @Published private(set) var recentSites: [BlogListSiteViewModel] = []
    @Published private(set) var allSites: [BlogListSiteViewModel] = []
    @Published private(set) var searchResults: [BlogListSiteViewModel] = []

    private let configuration: BlogListConfiguration
    private var rawSites: [Blog] = []
    private let fetchedResultsController: NSFetchedResultsController<Blog>
    private let contextManager: ContextManager
    private let blogService: BlogService
    private let eventTracker: EventTracker
    private var syncBlogsTask: Task<Void, Error>?

    init(configuration: BlogListConfiguration = .defaultConfig,
         contextManager: ContextManager = ContextManager.sharedInstance(),
         eventTracker: EventTracker = DefaultEventTracker()) {
        self.configuration = configuration
        self.contextManager = contextManager
        self.blogService = BlogService(coreDataStack: contextManager)
        self.eventTracker = eventTracker
        self.fetchedResultsController = createFetchedResultsController(in: contextManager.mainContext)
        super.init()
        setupFetchedResultsController()
    }

    func didSelectSite(withID objectID: NSManagedObjectID) -> Blog? {
        guard let blog = rawSites.first(where: { $0.objectID == objectID }) else {
            return nil
        }
        if selectedBlog() != blog {
            PushNotificationsManager.shared.deletePendingLocalNotifications()
        }
        eventTracker.track(.siteSwitcherSiteTapped, properties: [
            "section": blog.lastUsed != nil ? "recent" : "all"
        ])
        blog.lastUsed = Date()
        contextManager.saveContextAndWait(contextManager.mainContext)
        return blog
    }

    func onAppear() {
        if recentSites.isEmpty {
            selectedBlog()?.lastUsed = Date()
        }
        contextManager.save(contextManager.mainContext)

        Task {
            try? await refresh()
        }
    }

    func onDisappear() {
        syncBlogsTask?.cancel()
        syncBlogsTask = nil
    }

    // MARK: - Data Source

    private func selectedBlog() -> Blog? {
        RootViewCoordinator.sharedPresenter.currentOrLastBlog()
    }

    private func setupFetchedResultsController() {
        fetchedResultsController.delegate = self
        do {
            try fetchedResultsController.performFetch()
        } catch {
            wpAssertionFailure("sites-fetch-failed", userInfo: ["error": "\(error)"])
        }
        updateDisplayedSites()
    }

    private func updateDisplayedSites() {
        rawSites = getFilteredSites(from: fetchedResultsController)

        recentSites = rawSites
            .filter { $0.lastUsed != nil }
            .sorted { ($0.lastUsed ?? .distantPast) > ($1.lastUsed ?? .distantPast) }
            .prefix(5)
            .map(BlogListSiteViewModel.init)
            .sorted {
                $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
            }

        allSites = rawSites.map(BlogListSiteViewModel.init)
            .sorted {
                $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
            }

        updateSearchResults()
    }

    private func updateSearchResults() {
        if searchText.isEmpty {
            searchResults = []
        } else {
            let searchText = searchText
            Task { @MainActor in
                let searchResults = await search(searchTerm: searchText, sites: allSites)
                if searchText == self.searchText {
                    self.searchResults = searchResults
                }
            }
        }
    }

    // MARK: - Sync

    func refresh() async throws {
        if let task = syncBlogsTask {
            return try await task.value
        }
        let task = Task {
            defer { syncBlogsTask = nil }
            try await syncBlogs()
        }
        syncBlogsTask = task
        return try await task.value
    }

    @MainActor
    private func syncBlogs() async throws {
        guard let account = try WPAccount.lookupDefaultWordPressComAccount(in: contextManager.mainContext) else {
            return
        }
        try await withUnsafeThrowingContinuation { continuation in
            blogService.syncBlogs(for: account, success: continuation.resume, failure: continuation.resume(throwing:))
        }
        StoreContainer.shared.statsWidgets.refreshStatsWidgetsSiteList()
    }

    // MARK: - Helpers

    private func getFilteredSites(from fetchedResultsController: NSFetchedResultsController<Blog>) -> [Blog] {
        var blogs = fetchedResultsController.fetchedObjects ?? []
        if configuration.shouldHideSelfHostedSites {
            blogs = blogs.filter { $0.isAccessibleThroughWPCom() }
        }
        if configuration.shouldHideBlogsNotSupportingDomains {
            blogs = blogs.filter { $0.supports(.domains) }
        }
        return blogs
    }

}

extension BlogListViewModel: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        updateDisplayedSites()
    }
}

private func createFetchedResultsController(in context: NSManagedObjectContext) -> NSFetchedResultsController<Blog> {
    let request = NSFetchRequest<Blog>(entityName: NSStringFromClass(Blog.self))
    /// - warning: sorting happens in the ViewModel. It's irrelevant what descriptor
    /// is provided here, but Core Data requires one.
    request.sortDescriptors = [NSSortDescriptor(keyPath: \Blog.lastUsed, ascending: true)]
    return NSFetchedResultsController(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
}

private func search(searchTerm: String, sites: [BlogListSiteViewModel]) async -> [BlogListSiteViewModel] {
    let ranking = StringRankedSearch(searchTerm: searchTerm)
    return ranking.search(in: sites, input: \.searchTags)
}
