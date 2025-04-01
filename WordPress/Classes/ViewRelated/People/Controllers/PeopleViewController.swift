import UIKit
import Combine
import WordPressShared
import WordPressUI

// MARK: - PeopleViewController

class PeopleViewController: UITableViewController {

    // MARK: Properties

    private static let refreshRowPadding = 4

    /// Team's Blog
    ///
    private var blog: Blog?

    /// Mode: Users / Followers
    ///
    private var filter = Filter.users {
        didSet {
            refreshInterface()
            refreshResultsController()
            refreshPeople()
            refreshNoResultsView()
        }
    }

    /// Default Filter value when People loads
    ///
    fileprivate var defaultFilter = Filter.users

    /// NoResults Helper
    ///
    private let noResultsViewController = NoResultsViewController.controller()

    /// Indicates whether there are more results that can be retrieved, or not.
    ///
    private var shouldLoadMore = false {
        didSet {
            if shouldLoadMore {
                footerActivityIndicator.startAnimating()
            } else {
                footerActivityIndicator.stopAnimating()
            }
        }
    }

    /// Indicates whether there is a loadMore call in progress, or not.
    ///
    private var isLoadingMore = false

    /// Indicates when the People in Core Data have been refreshed.
    /// Used to display the loading view on initial view and refresh.
    ///
    private var isInitialLoad = true

    /// Number of records to skip in the next request
    ///
    private var nextRequestOffset = 0

    /// Filter Predicate
    ///
    private var predicate: NSPredicate {
        let predicate = NSPredicate(format: "siteID = %@ AND kind = %@", blog!.dotComID!, NSNumber(value: filter.personKind.rawValue as Int))
        return predicate
    }

    /// Sort Descriptor
    ///
    private var sortDescriptors: [NSSortDescriptor] {
        // Note:
        // Followers must be sorted out by creationDate!
        //
        switch filter {
        case .followers:
            return [NSSortDescriptor(key: "creationDate", ascending: true, selector: #selector(NSDate.compare(_:)))]
        default:
            return [NSSortDescriptor(key: "displayName", ascending: true, selector: #selector(NSString.localizedCaseInsensitiveCompare(_:)))]
        }
    }

    private var viewContext: NSManagedObjectContext {
        ContextManager.shared.mainContext
    }

    /// Core Data FRC
    ///
    private lazy var resultsController: NSFetchedResultsController<NSFetchRequestResult> = {
        // FIXME(@koke, 2015-11-02): my user should be first
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Person")
        request.predicate = self.predicate
        request.sortDescriptors = self.sortDescriptors

        let frc = NSFetchedResultsController(fetchRequest: request, managedObjectContext: viewContext, sectionNameKeyPath: nil, cacheName: nil)
        frc.delegate = self
        return frc
    }()

    /// Filtering Tab Bar
    ///
    @IBOutlet weak var filterBar: FilterTabBar!

    /// TableView Footer
    ///
    @IBOutlet
    private var footerView: UIView!

    /// TableView Footer Activity Indicator
    ///
    @IBOutlet
    private var footerActivityIndicator: UIActivityIndicatorView!

    // MARK: UITableViewDataSource

    override func numberOfSections(in tableView: UITableView) -> Int {
        guard !isInitialLoad else {
            // Until the initial load has been completed, no data should be rendered in the table.
            return 0
        }

        return resultsController.sections?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return resultsController.sections?[section].numberOfObjects ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "PeopleCell") as? PeopleCell else {
            fatalError()
        }

        guard let sections = resultsController.sections, sections[indexPath.section].numberOfObjects > indexPath.row else {
            DDLogError("Error: PeopleViewController table tried to render a cell that didn't exist in Core Data")
            cell.isHidden = true
            return cell
        }

        let person = personAtIndexPath(indexPath)
        let role = self.role(person: person)
        let viewModel = PeopleCellViewModel(person: person, role: role)

        cell.bindViewModel(viewModel)

        return cell
    }

    // MARK: UITableViewDelegate

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return .DS.Padding.single
    }

    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        // Refresh only when we reach the last 3 rows in the last section!
        let numberOfRowsInSection = self.tableView(tableView, numberOfRowsInSection: indexPath.section)
        guard (indexPath.row + PeopleViewController.refreshRowPadding) >= numberOfRowsInSection else {
            return
        }

        loadMorePeopleIfNeeded()
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        guard let blog, let blogId = blog.dotComID?.intValue else { return }

        switch filter {
        case .users, .viewers:
            guard let viewController = PersonViewController.controllerWithBlog(
                blog,
                context: viewContext,
                person: personAtIndexPath(indexPath),
                screenMode: filter.screenMode
            ) else {
                return
            }
            navigationController?.pushViewController(viewController, animated: true)
        case .followers:
            let url = URL(string: "https://wordpress.com/subscribers/\(blogId)/\(personAtIndexPath(indexPath).ID)")
            let configuration = WebViewControllerConfiguration(url: url)
            configuration.authenticateWithDefaultAccount()
            configuration.secureInteraction = true
            let viewController = WebKitViewController(configuration: configuration)
            let navWrapper = UINavigationController(rootViewController: viewController)
            navigationController?.present(navWrapper, animated: true)
        }
    }

    // MARK: UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        observeNetworkStatus()
        resetManagedPeople()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.deselectSelectedRowWithAnimation(true)
        refreshNoResultsView()

        guard let blog else {
            return
        }

        WPAppAnalytics.track(.openedPeople, blog: blog)
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        tableView.reloadData()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let navController = segue.destination as? UINavigationController,
            let inviteViewController = navController.topViewController as? InvitePersonViewController {
            inviteViewController.blog = blog
        }
    }

    // MARK: Action Handlers

    @IBAction
    func refresh() {
        refreshPeople()
    }

    @IBAction
    func invitePersonWasPressed() {
        performSegue(withIdentifier: Storyboard.inviteSegueIdentifier, sender: self)
    }
}

// MARK: - NSFetchedResultsControllerDelegate

extension PeopleViewController: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        refreshNoResultsView()
        tableView.reloadData()
    }
}

// MARK: - NetworkAwareUI

extension PeopleViewController: NetworkAwareUI {
    func contentIsEmpty() -> Bool {
        return resultsController.isEmpty()
    }
}

// MARK: - NetworkStatusDelegate

extension PeopleViewController: NetworkStatusDelegate {
    func networkStatusDidChange(active: Bool) {
        refresh()
    }
}

// MARK: - Enum

extension PeopleViewController {
    enum Filter: String, CaseIterable, FilterTabBarItem {

        case users = "users"
        case followers = "followers"
        case viewers = "viewers"

        static var defaultFilters: [Filter] {
            return [.users, .followers]
        }

        var title: String {
            switch self {
            case .users:
                return NSLocalizedString("Users", comment: "Blog Users")
            case .followers:
                return NSLocalizedString("users.list.title.subscribers", value: "Subscribers", comment: "Site Subscribers")
            case .viewers:
                return NSLocalizedString("Viewers", comment: "Blog Viewers")
            }
        }

        var personKind: PersonKind {
            switch self {
            case .users:
                return .user
            case .followers:
                return .follower
            case .viewers:
                return .viewer
            }
        }

        var screenMode: PersonViewController.ScreenMode {
            switch self {
            case .users:
                return .User
            case .followers:
                return .Follower
            case .viewers:
                return .Viewer
            }
        }
    }
}

// MARK: - Private behavior

private extension PeopleViewController {

    enum Storyboard {
        static let inviteSegueIdentifier = "invite"
    }

    // MARK: Interface Helpers

    func filtersAvailableForBlog(_ blog: Blog?) -> [Filter] {
        guard let blog, blog.siteVisibility == .private else {
            return Filter.defaultFilters
        }

        return Filter.allCases
    }

    func refreshInterface() {
        shouldLoadMore = false
    }

    func refreshResultsController() {
        resultsController.fetchRequest.predicate = predicate
        resultsController.fetchRequest.sortDescriptors = sortDescriptors

        do {
            try resultsController.performFetch()
            tableView.reloadData()
        } catch {
            DDLogError("Error fetching People: \(error)")
        }
    }

    // MARK: Sync Helpers

    func refreshPeople() {
        self.isInitialLoad = true
        self.refreshNoResultsView()
        loadPeoplePage() { [weak self] (retrieved, shouldLoadMore) in
            self?.isInitialLoad = false
            self?.refreshNoResultsView()
            self?.tableView.reloadData()
            self?.nextRequestOffset = retrieved
            self?.shouldLoadMore = shouldLoadMore
            self?.refreshControl?.endRefreshing()
        }
    }

    func resetManagedPeople() {
        isInitialLoad = true

        guard let blog, let service = PeopleService(blog: blog, coreDataStack: ContextManager.shared) else {
            return
        }

        service.removeManagedPeople()
    }

    func loadMorePeopleIfNeeded() {
        guard shouldLoadMore == true && isLoadingMore == false else {
            return
        }

        isLoadingMore = true

        loadPeoplePage(nextRequestOffset) { [weak self] (retrieved, shouldLoadMore) in
            self?.nextRequestOffset += retrieved
            self?.shouldLoadMore = shouldLoadMore
            self?.isLoadingMore = false
        }
    }

    func loadPeoplePage(_ offset: Int = 0, success: @escaping ((_ retrieved: Int, _ shouldLoadMore: Bool) -> Void)) {
        guard let blog, let service = PeopleService(blog: blog, coreDataStack: ContextManager.shared) else {
            return
        }

        switch filter {
        case .followers:
            service.loadFollowersPage(offset, success: success)
        case .users:
            loadUsersPage(offset, success: success)
        case .viewers:
            service.loadViewersPage(offset, success: success)
        }
    }

    func loadUsersPage(_ offset: Int = 0, success: @escaping ((_ retrieved: Int, _ shouldLoadMore: Bool) -> Void)) {
        guard let blog = blogInContext,
            let peopleService = PeopleService(blog: blog, coreDataStack: ContextManager.shared),
            let roleService = RoleService(blog: blog, coreDataStack: ContextManager.shared) else {
                return
        }

        var result: (retrieved: Int, shouldLoadMore: Bool)?
        var loadError: Error?

        let group = DispatchGroup()
        group.enter()
        peopleService.loadUsersPage(offset, success: { (retrieved, shouldLoadMore) in
            result = (retrieved, shouldLoadMore)
            group.leave()
        }, failure: { error in
            loadError = error
            group.leave()
        })

        group.enter()
        roleService.fetchRoles(success: {
            group.leave()
        }, failure: { error in
            loadError = error
            group.leave()
        })

        group.notify(queue: DispatchQueue.main) { [weak self] in
            if let error = loadError {
                self?.handleLoadError(error)
            }

            if let result {
                success(result.retrieved, result.shouldLoadMore)
            }
        }
    }

    var blogInContext: Blog? {
        guard let objectID = blog?.objectID,
            let object = try? viewContext.existingObject(with: objectID) else {
                return nil
        }

        return object as? Blog
    }

    // MARK: No Results Helpers

    func refreshNoResultsView() {
        guard resultsController.fetchedObjects?.count == 0 else {
            noResultsViewController.removeFromView()
            return
        }

        displayNoResultsView(isLoading: isInitialLoad)
    }

    func displayNoResultsView(isLoading: Bool = false) {
        let accessoryView = isLoading ? NoResultsViewController.loadingAccessoryView() : nil
        noResultsViewController.configure(title: noResultsTitle(), accessoryView: accessoryView)

        guard noResultsViewController.parent == nil else {
            noResultsViewController.updateView()
            return
        }
        addChild(noResultsViewController)
        tableView.addSubview(withFadeAnimation: noResultsViewController.view)
        noResultsViewController.view.translatesAutoresizingMaskIntoConstraints = false
        view.pinSubviewToSafeArea(noResultsViewController.view)

        noResultsViewController.didMove(toParent: self)
    }

    func noResultsTitle() -> String {
        if isInitialLoad {
            return NSLocalizedString("Loading People...", comment: "Text displayed while loading site People.")
        }

        let noPeopleFormat = NSLocalizedString("No %@ yet", comment: "Empty state message (People Management). %@ can be 'users' or 'followers'")
        let noPeople = String(format: noPeopleFormat, filter.title.lowercased())

        return connectionAvailable() ? noPeople : noConnectionMessage()
    }

    func handleLoadError(_ forError: Error) {
        let _ = DispatchDelayedAction(delay: .milliseconds(250)) { [weak self] in
            self?.refreshControl?.endRefreshing()
        }

        handleConnectionError()
    }

    // MARK: Private Helpers

    func personAtIndexPath(_ indexPath: IndexPath) -> Person {
        let managedPerson = resultsController.object(at: indexPath) as! ManagedPerson
        return managedPerson.toUnmanaged()
    }

    func role(person: Person) -> Role? {
        guard let blog else {
            return nil
        }
        return try? Role.lookup(withBlogID: blog.objectID, slug: person.role, in: viewContext)
    }

    func setupFilterBar() {
        WPStyleGuide.configureFilterTabBar(filterBar)
        filterBar.backgroundColor = .clear

        filterBar.items = filtersAvailableForBlog(blog)
        filterBar.addTarget(self, action: #selector(selectedFilterDidChange(_:)), for: .valueChanged)

        let indexToSet = Filter.allCases.firstIndex(where: { $0 == defaultFilter }) ?? 0
        filterBar.setSelectedIndex(indexToSet)
        filter = defaultFilter
    }

    func setupTableView() {
        filterBar.translatesAutoresizingMaskIntoConstraints = false

        tableView.tableHeaderView = filterBar

        NSLayoutConstraint.activate([
            filterBar.centerXAnchor.constraint(equalTo: tableView.centerXAnchor),
            filterBar.topAnchor.constraint(equalTo: tableView.topAnchor),
            filterBar.widthAnchor.constraint(equalTo: tableView.widthAnchor),
        ])
    }

    func setupView() {
        title = NSLocalizedString("People", comment: "Noun. Title of the people management feature.")

        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add,
                                                            target: self,
                                                            action: #selector(invitePersonWasPressed))

        WPStyleGuide.configureAutomaticHeightRows(for: tableView)

        setupFilterBar()
        setupTableView()
    }
}

// MARK: - Objective-C support

@objc
extension PeopleViewController {
    class func controllerWithBlog(_ blog: Blog) -> PeopleViewController? {
        let storyboard = UIStoryboard(name: "People", bundle: nil)
        guard let viewController = storyboard.instantiateInitialViewController() as? PeopleViewController else {
            return nil
        }

        viewController.blog = blog

        return viewController
    }

    func selectedFilterDidChange(_ filterBar: FilterTabBar) {
        let selectedFilter = Filter.allCases[filterBar.selectedIndex]
        filter = selectedFilter

        guard let blog else {
            return
        }
        WPAnalytics.track(.peopleFilterChanged, properties: [:], blog: blog)
    }
}

extension PeopleViewController {
    class func controllerWithBlog(_ blog: Blog, selectedFilter: Filter) -> PeopleViewController? {
        let storyboard = UIStoryboard(name: "People", bundle: nil)
        guard let viewController = storyboard.instantiateInitialViewController() as? PeopleViewController else {
            return nil
        }

        viewController.defaultFilter = selectedFilter
        viewController.blog = blog

        return viewController
    }
}
