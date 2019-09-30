import UIKit

import CocoaLumberjack
import WordPressShared

// MARK: - PeopleViewController

class PeopleViewController: UITableViewController, UIViewControllerRestoration {

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

    /// Core Data Context
    ///
    private lazy var context: NSManagedObjectContext = {
        return ContextManager.sharedInstance().newMainContextChildContext()
    }()

    /// Core Data FRC
    ///
    private lazy var resultsController: NSFetchedResultsController<NSFetchRequestResult> = {
        // FIXME(@koke, 2015-11-02): my user should be first
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Person")
        request.predicate = self.predicate
        request.sortDescriptors = self.sortDescriptors

        let frc = NSFetchedResultsController(fetchRequest: request, managedObjectContext: self.context, sectionNameKeyPath: nil, cacheName: nil)
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
        return resultsController.sections?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return resultsController.sections?[section].numberOfObjects ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "PeopleCell") as? PeopleCell else {
            fatalError()
        }

        let person = personAtIndexPath(indexPath)
        let role = self.role(person: person)
        let viewModel = PeopleCellViewModel(person: person, role: role)

        cell.bindViewModel(viewModel)

        return cell
    }

    // MARK: UITableViewDelegate

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return hasHorizontallyCompactView() ? CGFloat.leastNormalMagnitude : 0
    }

    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        // Refresh only when we reach the last 3 rows in the last section!
        let numberOfRowsInSection = self.tableView(tableView, numberOfRowsInSection: indexPath.section)
        guard (indexPath.row + PeopleViewController.refreshRowPadding) >= numberOfRowsInSection else {
            return
        }

        loadMorePeopleIfNeeded()
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
        WPAnalytics.track(.openedPeople)
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        tableView.reloadData()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let personViewController = segue.destination as? PersonViewController,
            let selectedIndexPath = tableView.indexPathForSelectedRow {
            personViewController.context = context
            personViewController.blog = blog
            personViewController.person = personAtIndexPath(selectedIndexPath)
            switch filter {
            case .followers:
                personViewController.screenMode = .Follower
            case .users:
                personViewController.screenMode = .User
            case .viewers:
                personViewController.screenMode = .Viewer
            }

        } else if let navController = segue.destination as? UINavigationController,
            let inviteViewController = navController.topViewController as? InvitePersonViewController {
            inviteViewController.blog = blog
        }
    }

    // MARK: - UIViewControllerRestoration

    class func viewController(withRestorationIdentifierPath identifierComponents: [String],
                              coder: NSCoder) -> UIViewController? {
        let context = ContextManager.sharedInstance().mainContext

        guard let blogID = coder.decodeObject(forKey: RestorationKeys.blog) as? String,
            let objectURL = URL(string: blogID),
            let objectID = context.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: objectURL),
            let restoredBlog = try? context.existingObject(with: objectID),
            let blog = restoredBlog  as? Blog else {
                return nil
        }

        return controllerWithBlog(blog)
    }

    override func encodeRestorableState(with coder: NSCoder) {
        let objectString = blog?.objectID.uriRepresentation().absoluteString
        coder.encode(objectString, forKey: RestorationKeys.blog)
        super.encodeRestorableState(with: coder)
    }

    // MARK: Action Handlers

    @IBAction
    func refresh() {
        resetManagedPeople()
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

// MARK: - Private behavior

private extension PeopleViewController {

    // MARK: Enums

    enum Filter: String, CaseIterable, FilterTabBarItem {

        case users      = "users"
        case followers  = "followers"
        case viewers    = "viewers"

        static var defaultFilters: [Filter] {
            return [.users, .followers]
        }

        var title: String {
            switch self {
            case .users:
                return NSLocalizedString("Users", comment: "Blog Users")
            case .followers:
                return NSLocalizedString("Followers", comment: "Blog Followers")
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
    }

    enum RestorationKeys {
        static let blog = "peopleBlogRestorationKey"
    }

    enum Storyboard {
        static let inviteSegueIdentifier = "invite"
    }

    // MARK: Interface Helpers

    func filtersAvailableForBlog(_ blog: Blog?) -> [Filter] {
        guard let blog = blog, blog.siteVisibility == .private else {
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

            // Failsafe:
            // This was causing a glitch after State Restoration. Top Section padding was being initially
            // set with an incorrect value, and subsequent reloads weren't picking up the right value.
            //
            if isHorizontalSizeClassUnspecified() {
                return
            }

            tableView.reloadData()
        } catch {
            DDLogError("Error fetching People: \(error)")
        }
    }

    // MARK: Sync Helpers

    func refreshPeople() {
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

        guard let blog = blog, let service = PeopleService(blog: blog, context: context) else {
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
        guard let blog = blog, let service = PeopleService(blog: blog, context: context) else {
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
            let peopleService = PeopleService(blog: blog, context: context),
            let roleService = RoleService(blog: blog, context: context) else {
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
        roleService.fetchRoles(success: {_ in
            group.leave()
        }, failure: { error in
            loadError = error
            group.leave()
        })

        group.notify(queue: DispatchQueue.main) { [weak self] in
            if let error = loadError {
                self?.handleLoadError(error)
            }

            if let result = result {
                success(result.retrieved, result.shouldLoadMore)
            }
        }
    }

    var blogInContext: Blog? {
        guard let objectID = blog?.objectID,
            let object = try? context.existingObject(with: objectID) else {
                return nil
        }

        return object as? Blog
    }

    // MARK: No Results Helpers

    func refreshNoResultsView() {
        noResultsViewController.removeFromView()

        if isInitialLoad {
            displayNoResultsView(forLoading: true)
            return
        }

        guard resultsController.fetchedObjects?.count == 0 else {
            return
        }

        displayNoResultsView()
    }

    func displayNoResultsView(forLoading: Bool = false) {
        let accessoryView = forLoading ? NoResultsViewController.loadingAccessoryView() : nil
        noResultsViewController.configure(title: noResultsTitle(), accessoryView: accessoryView)

        addChild(noResultsViewController)
        tableView.addSubview(withFadeAnimation: noResultsViewController.view)

        // Set the NRV top as the filterBar bottom so the NRV
        // adjusts correctly when refreshControl is active.
        let filterBarBottom = filterBar.frame.origin.y + filterBar.frame.size.height
        noResultsViewController.view.frame.origin.y = filterBarBottom

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
        guard let blog = blog,
            let service = RoleService(blog: blog, context: context) else {
                return nil
        }
        return service.getRole(slug: person.role)
    }

    func setupFilterBar() {
        WPStyleGuide.configureFilterTabBar(filterBar)

        filterBar.items = filtersAvailableForBlog(blog)
        filterBar.addTarget(self, action: #selector(selectedFilterDidChange(_:)), for: .valueChanged)

        // By default, let's display the Blog's Users
        filter = .users
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

        WPStyleGuide.configureColors(view: view, tableView: tableView)
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
        viewController.restorationClass = self

        return viewController
    }

    func selectedFilterDidChange(_ filterBar: FilterTabBar) {
        let selectedFilter = Filter.allCases[filterBar.selectedIndex]
        filter = selectedFilter
    }
}
