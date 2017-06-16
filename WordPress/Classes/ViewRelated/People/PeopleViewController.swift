import UIKit
import CocoaLumberjack
import WordPressShared
import WordPressComAnalytics

open class PeopleViewController: UITableViewController, NSFetchedResultsControllerDelegate, UIViewControllerRestoration {

    // MARK: - Properties

    /// Team's Blog
    ///
    open var blog: Blog?

    /// Mode: Users / Followers
    ///
    fileprivate var filter = Filter.Users {
        didSet {
            refreshInterface()
            refreshResultsController()
            refreshPeople()
            refreshNoResultsView()
        }
    }

    /// NoResults Helper
    ///
    fileprivate let noResultsView = WPNoResultsView()

    /// Indicates whether there are more results that can be retrieved, or not.
    ///
    fileprivate var shouldLoadMore = false {
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
    fileprivate var isLoadingMore = false

    /// Number of records to skip in the next request
    ///
    fileprivate var nextRequestOffset = 0

    /// Filter Predicate
    ///
    fileprivate var predicate: NSPredicate {
        let predicate = NSPredicate(format: "siteID = %@ AND kind = %@", blog!.dotComID!, NSNumber(value: filter.personKind.rawValue as Int))
        return predicate
    }

    /// Sort Descriptor
    ///
    fileprivate var sortDescriptors: [NSSortDescriptor] {
        // Note:
        // Followers must be sorted out by creationDate!
        //
        switch filter {
        case .Followers:
            return [NSSortDescriptor(key: "creationDate", ascending: true, selector: #selector(NSDate.compare(_:)))]
        default:
            return [NSSortDescriptor(key: "displayName", ascending: true, selector: #selector(NSString.localizedCaseInsensitiveCompare(_:)))]
        }
    }

    /// Core Data Context
    ///
    fileprivate lazy var context: NSManagedObjectContext = {
        return ContextManager.sharedInstance().newMainContextChildContext()
    }()

    /// Core Data FRC
    ///
    fileprivate lazy var resultsController: NSFetchedResultsController<NSFetchRequestResult> = {
        // FIXME(@koke, 2015-11-02): my user should be first
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Person")
        request.predicate = self.predicate
        request.sortDescriptors = self.sortDescriptors

        let frc = NSFetchedResultsController(fetchRequest: request, managedObjectContext: self.context, sectionNameKeyPath: nil, cacheName: nil)
        frc.delegate = self
        return frc
    }()

    /// Navigation Bar Custom Title
    ///
    @IBOutlet fileprivate var titleButton: NavBarTitleDropdownButton!

    /// TableView Footer
    ///
    @IBOutlet fileprivate var footerView: UIView!

    /// TableView Footer Activity Indicator
    ///
    @IBOutlet fileprivate var footerActivityIndicator: UIActivityIndicatorView!



    // MARK: - UITableView Methods

    open override func numberOfSections(in tableView: UITableView) -> Int {
        return resultsController.sections?.count ?? 0
    }

    open override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return resultsController.sections?[section].numberOfObjects ?? 0
    }

    open override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "PeopleCell") as? PeopleCell else {
            fatalError()
        }

        let person = personAtIndexPath(indexPath)
        let viewModel = PeopleCellViewModel(person: person)

        cell.bindViewModel(viewModel)

        return cell
    }

    open override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return hasHorizontallyCompactView() ? CGFloat.leastNormalMagnitude : 0
    }

    open override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        // Refresh only when we reach the last 3 rows in the last section!
        let numberOfRowsInSection = self.tableView(tableView, numberOfRowsInSection: indexPath.section)
        guard (indexPath.row + refreshRowPadding) >= numberOfRowsInSection else {
            return
        }

        loadMorePeopleIfNeeded()
    }


    // MARK: - NSFetchedResultsController Methods

    open func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        refreshNoResultsView()
        tableView.reloadData()
    }


    // MARK: - View Lifecycle Methods

    open override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.titleView = titleButton
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add,
                                                            target: self,
                                                            action: #selector(invitePersonWasPressed))

        WPStyleGuide.configureColors(for: view, andTableView: tableView)

        // By default, let's display the Blog's Users
        filter = .Users
    }

    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.deselectSelectedRowWithAnimation(true)
        refreshNoResultsView()
        WPAnalytics.track(.openedPeople)
    }

    open override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        tableView.reloadData()
    }

    open override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let personViewController = segue.destination as? PersonViewController,
            let selectedIndexPath = tableView.indexPathForSelectedRow {
            personViewController.context = context
            personViewController.blog = blog
            personViewController.person = personAtIndexPath(selectedIndexPath)
            switch filter {
            case .Followers:
                personViewController.screenMode = .Follower
            case .Users:
                personViewController.screenMode = .User
            case .Viewers:
                personViewController.screenMode = .Viewer
            }

        } else if let navController = segue.destination as? UINavigationController,
            let inviteViewController = navController.topViewController as? InvitePersonViewController {
            inviteViewController.blog = blog
        }
    }


    // MARK: - Action Handlers

    @IBAction open func refresh() {
        refreshPeople()
    }

    @IBAction open func titleWasPressed() {
        displayModePicker()
    }

    @IBAction open func invitePersonWasPressed() {
        performSegue(withIdentifier: Storyboard.inviteSegueIdentifier, sender: self)
    }


    // MARK: - Interface Helpers

    fileprivate func refreshInterface() {
        // Note:
        // We also set the title on purpose, so that whatever VC we push, the back button spells the right title.
        //
        title = filter.title
        titleButton.setAttributedTitleForTitle(filter.title)
        shouldLoadMore = false
    }

    fileprivate func refreshResultsController() {
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


    // MARK: - Sync Helpers

    fileprivate func refreshPeople() {
        loadPeoplePage() { [weak self] (retrieved, shouldLoadMore) in
            self?.nextRequestOffset = retrieved
            self?.shouldLoadMore = shouldLoadMore
            self?.refreshControl?.endRefreshing()
        }
    }

    fileprivate func loadMorePeopleIfNeeded() {
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

    fileprivate func loadPeoplePage(_ offset: Int = 0, success: @escaping ((_ retrieved: Int, _ shouldLoadMore: Bool) -> Void)) {
        guard let blog = blog, let service = PeopleService(blog: blog, context: context) else {
            return
        }

        switch filter {
        case .Followers:
            service.loadFollowersPage(offset, success: success)
        case .Users:
            service.loadUsersPage(offset, success: success)
        case .Viewers:
            service.loadViewersPage(offset, success: success)
        }
    }


    // MARK: - No Results Helpers

    fileprivate func refreshNoResultsView() {
        guard resultsController.fetchedObjects?.count == 0 else {
            noResultsView.removeFromSuperview()
            return
        }

        noResultsView.titleText = NSLocalizedString("No \(filter.title) Yet",
            comment: "Empty state message (People Management). Please, do not translate the \\(filter.title) part!")

        if noResultsView.superview == nil {
            tableView.addSubview(withFadeAnimation: noResultsView)
        }
    }


    // MARK: - Private Helpers

    fileprivate func personAtIndexPath(_ indexPath: IndexPath) -> Person {
        let managedPerson = resultsController.object(at: indexPath) as! ManagedPerson
        return managedPerson.toUnmanaged()
    }

    fileprivate func displayModePicker() {
        guard let blog = blog else {
            fatalError()
        }

        let filters                 = filtersAvailableForBlog(blog)

        let controller              = SettingsSelectionViewController(style: .plain)
        controller.title            = NSLocalizedString("Filters", comment: "Title of the list of People Filters")
        controller.titles           = filters.map { $0.title }
        controller.values           = filters.map { $0.rawValue }
        controller.currentValue     = filter.rawValue as NSObject!
        controller.onItemSelected   = { [weak self] selectedValue in
            guard let rawFilter = selectedValue as? String, let filter = Filter(rawValue: rawFilter) else {
                fatalError()
            }

            self?.filter = filter
            self?.dismiss(animated: true, completion: nil)
        }

        controller.tableView.isScrollEnabled = false

        ForcePopoverPresenter.configurePresentationControllerForViewController(controller,
                                                                                                           presentingFromView: titleButton)

        present(controller, animated: true, completion: nil)
    }

    fileprivate func filtersAvailableForBlog(_ blog: Blog) -> [Filter] {
        var available: [Filter] = [.Users, .Followers]
        if blog.siteVisibility == .private {
            available.append(.Viewers)
        }

        return available
    }


    // MARK: - UIViewControllerRestoration

    open override func encodeRestorableState(with coder: NSCoder) {
        let objectString = blog?.objectID.uriRepresentation().absoluteString
        coder.encode(objectString, forKey: RestorationKeys.blog)
        super.encodeRestorableState(with: coder)
    }

    open class func viewController(withRestorationIdentifierPath identifierComponents: [Any], coder: NSCoder) -> UIViewController? {
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


    // MARK: - Static Helpers

    open class func controllerWithBlog(_ blog: Blog) -> PeopleViewController? {
        let storyboard = UIStoryboard(name: "People", bundle: nil)
        guard let viewController = storyboard.instantiateInitialViewController() as? PeopleViewController else {
            return nil
        }

        viewController.blog = blog
        viewController.restorationClass = self

        return viewController
    }



    // MARK: - Private Enums

    fileprivate enum Filter: String {
        case Users      = "users"
        case Followers  = "followers"
        case Viewers    = "viewers"

        var title: String {
            switch self {
            case .Users:
                return NSLocalizedString("Users", comment: "Blog Users")
            case .Followers:
                return NSLocalizedString("Followers", comment: "Blog Followers")
            case .Viewers:
                return NSLocalizedString("Viewers", comment: "Blog Viewers")
            }
        }

        var personKind: PersonKind {
            switch self {
            case .Users:
                return .user
            case .Followers:
                return .follower
            case .Viewers:
                return .viewer
            }
        }
    }

    fileprivate enum RestorationKeys {
        static let blog = "peopleBlogRestorationKey"
    }

    fileprivate enum Storyboard {
        static let inviteSegueIdentifier = "invite"
    }

    fileprivate let refreshRowPadding = 4
}
