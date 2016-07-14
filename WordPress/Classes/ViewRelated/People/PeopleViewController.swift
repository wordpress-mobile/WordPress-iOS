import UIKit
import WordPressShared
import WordPressComAnalytics

public class PeopleViewController: UITableViewController, NSFetchedResultsControllerDelegate, UIViewControllerRestoration {

    // MARK: - Properties

    /// Team's Blog
    ///
    public var blog: Blog?

    /// Mode: Users / Followers
    ///
    private var filter = Filter.Users {
        didSet {
            refreshInterface()
            refreshResultsController()
            refreshPeople()
            refreshNoResultsView()
        }
    }

    /// NoResults Helper
    ///
    private let noResultsView = WPNoResultsView()

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

    /// Number of records to skip in the next request
    ///
    private var nextRequestOffset = 0

    /// Filter Predicate
    ///
    private var predicate: NSPredicate {
        let predicate = NSPredicate(format: "siteID = %@ AND kind = %@", blog!.dotComID!, NSNumber(integer: filter.personKind.rawValue))
        return predicate
    }

    /// Sort Descriptor
    ///
    private var sortDescriptors: [NSSortDescriptor] {
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
    private lazy var context: NSManagedObjectContext = {
        return ContextManager.sharedInstance().newMainContextChildContext()
    }()

    /// Core Data FRC
    ///
    private lazy var resultsController: NSFetchedResultsController = {
        // FIXME(@koke, 2015-11-02): my user should be first
        let request = NSFetchRequest(entityName: "Person")
        request.predicate = self.predicate
        request.sortDescriptors = self.sortDescriptors

        let frc = NSFetchedResultsController(fetchRequest: request, managedObjectContext: self.context, sectionNameKeyPath: nil, cacheName: nil)
        frc.delegate = self
        return frc
    }()

    /// Navigation Bar Custom Title
    ///
    @IBOutlet private var titleButton: NavBarTitleDropdownButton!

    /// TableView Footer
    ///
    @IBOutlet private var footerView: UIView!

    /// TableView Footer Activity Indicator
    ///
    @IBOutlet private var footerActivityIndicator: UIActivityIndicatorView!



    // MARK: - UITableView Methods

    public override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return resultsController.sections?.count ?? 0
    }

    public override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return resultsController.sections?[section].numberOfObjects ?? 0
    }

    public override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCellWithIdentifier("PeopleCell") as? PeopleCell else {
            fatalError()
        }

        let person = personAtIndexPath(indexPath)
        let viewModel = PeopleCellViewModel(person: person)

        cell.bindViewModel(viewModel)

        return cell
    }

    public override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return hasHorizontallyCompactView() ? CGFloat.min : 0
    }

    public override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        // Refresh only when we reach the last 3 rows in the last section!
        let numberOfRowsInSection = self.tableView(tableView, numberOfRowsInSection: indexPath.section)
        guard (indexPath.row + refreshRowPadding) >= numberOfRowsInSection else {
            return
        }

        loadMorePeopleIfNeeded()
    }


    // MARK: - NSFetchedResultsController Methods

    public func controllerDidChangeContent(controller: NSFetchedResultsController) {
        refreshNoResultsView()
        tableView.reloadData()
    }


    // MARK: - View Lifecycle Methods

    public override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.titleView = titleButton
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Add,
                                                            target: self,
                                                            action: #selector(invitePersonWasPressed))
        WPStyleGuide.configureColorsForView(view, andTableView: tableView)

        // By default, let's display the Blog's Users
        filter = .Users
    }

    public override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        tableView.deselectSelectedRowWithAnimation(true)
        refreshNoResultsView()
        WPAnalytics.track(.OpenedPeople)
    }

    public override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        tableView.reloadData()
    }

    public override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let personViewController = segue.destinationViewController as? PersonViewController,
            let selectedIndexPath = tableView.indexPathForSelectedRow
        {
            personViewController.context = context
            personViewController.blog = blog
            personViewController.person = personAtIndexPath(selectedIndexPath)

        } else if let navController = segue.destinationViewController as? UINavigationController,
            let inviteViewController = navController.topViewController as? InvitePersonViewController
        {
            inviteViewController.blog = blog
        }
    }


    // MARK: - Action Handlers

    @IBAction public func refresh() {
        refreshPeople()
    }

    @IBAction public func titleWasPressed() {
        displayModePicker()
    }

    @IBAction public func invitePersonWasPressed() {
        performSegueWithIdentifier(Storyboard.inviteSegueIdentifier, sender: self)
    }


    // MARK: - Interface Helpers

    private func refreshInterface() {
        // Note:
        // We also set the title on purpose, so that whatever VC we push, the back button spells the right title.
        //
        title = filter.title
        titleButton.setAttributedTitleForTitle(filter.title)
        shouldLoadMore = false
    }

    private func refreshResultsController() {
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
            DDLogSwift.logError("Error fetching People: \(error)")
        }
    }


    // MARK: - Sync Helpers

    private func refreshPeople() {
        loadPeoplePage() { [weak self] (retrieved, shouldLoadMore) in
            self?.nextRequestOffset = retrieved
            self?.shouldLoadMore = shouldLoadMore
            self?.refreshControl?.endRefreshing()
        }
    }

    private func loadMorePeopleIfNeeded() {
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

    private func loadPeoplePage(offset: Int = 0, success: ((retrieved: Int, shouldLoadMore: Bool) -> Void)) {
        guard let blog = blog, service = PeopleService(blog: blog, context: context) else {
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

    private func refreshNoResultsView() {
        guard resultsController.fetchedObjects?.count == 0 else {
            noResultsView.removeFromSuperview()
            return
        }

        noResultsView.titleText = NSLocalizedString("No \(filter.title) Yet",
            comment: "Empty state message (People Management). Please, do not translate the \\(filter.title) part!")

        if noResultsView.superview == nil {
            tableView.addSubviewWithFadeAnimation(noResultsView)
        }
    }


    // MARK: - Private Helpers

    private func personAtIndexPath(indexPath: NSIndexPath) -> Person {
        let managedPerson = resultsController.objectAtIndexPath(indexPath) as! ManagedPerson
        return managedPerson.toUnmanaged()
    }

    private func displayModePicker() {
        guard let blog = blog else {
            fatalError()
        }

        let filters                 = filtersAvailableForBlog(blog)

        let controller              = SettingsSelectionViewController(style: .Plain)
        controller.title            = NSLocalizedString("Filters", comment: "Title of the list of People Filters")
        controller.titles           = filters.map { $0.title }
        controller.values           = filters.map { $0.rawValue }
        controller.currentValue     = filter.rawValue
        controller.onItemSelected   = { [weak self] selectedValue in
            guard let rawFilter = selectedValue as? String, let filter = Filter(rawValue: rawFilter) else {
                fatalError()
            }

            self?.filter = filter
            self?.dismissViewControllerAnimated(true, completion: nil)
        }

        controller.tableView.scrollEnabled = false

        ForcePopoverPresenter.configurePresentationControllerForViewController(controller,
                                                                                                           presentingFromView: titleButton)

        presentViewController(controller, animated: true, completion: nil)
    }

    private func filtersAvailableForBlog(blog: Blog) -> [Filter] {
        var available: [Filter] = [.Users, .Followers]
        if blog.siteVisibility == .Private {
            available.append(.Viewers)
        }

        return available
    }


    // MARK: - UIViewControllerRestoration

    public override func encodeRestorableStateWithCoder(coder: NSCoder) {
        let objectString = blog?.objectID.URIRepresentation().absoluteString
        coder.encodeObject(objectString, forKey: RestorationKeys.blog)
        super.encodeRestorableStateWithCoder(coder)
    }

    public class func viewControllerWithRestorationIdentifierPath(identifierComponents: [AnyObject], coder: NSCoder) -> UIViewController? {
        let context = ContextManager.sharedInstance().mainContext

        guard let blogID = coder.decodeObjectForKey(RestorationKeys.blog) as? String,
            let objectURL = NSURL(string: blogID),
            let objectID = context.persistentStoreCoordinator?.managedObjectIDForURIRepresentation(objectURL),
            let restoredBlog = try? context.existingObjectWithID(objectID),
            let blog = restoredBlog  as? Blog else
        {
            return nil
        }

        return controllerWithBlog(blog)
    }


    // MARK: - Static Helpers

    public class func controllerWithBlog(blog: Blog) -> PeopleViewController? {
        let storyboard = UIStoryboard(name: "People", bundle: nil)
        guard let viewController = storyboard.instantiateInitialViewController() as? PeopleViewController else {
            return nil
        }

        viewController.blog = blog
        viewController.restorationClass = self

        return viewController
    }



    // MARK: - Private Enums

    private enum Filter : String {
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
                return .User
            case .Followers:
                return .Follower
            case .Viewers:
                return .Viewer
            }
        }
    }

    private enum RestorationKeys {
        static let blog = "peopleBlogRestorationKey"
    }

    private enum Storyboard {
        static let inviteSegueIdentifier = "invite"
    }

    private let refreshRowPadding = 4
}
