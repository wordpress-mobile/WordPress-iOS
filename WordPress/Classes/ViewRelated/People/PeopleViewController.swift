import UIKit
import WordPressShared

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
            refreshResults()
            refreshPeople()
        }
    }

    /// NoResults Helper
    ///
    private let noResultsView = WPNoResultsView()

    /// Filter Predicate
    ///
    private var predicate: NSPredicate {
        let follower = self.filter == .Followers
        let predicate = NSPredicate(format: "siteID = %@ AND isFollower = %@", self.blog!.dotComID!, follower)
        return predicate
    }

    /// Core Data FRC
    ///
    private lazy var resultsController: NSFetchedResultsController = {
        let request = NSFetchRequest(entityName: "Person")
        request.predicate = self.predicate

        // FIXME(@koke, 2015-11-02): my user should be first
        request.sortDescriptors = [NSSortDescriptor(key: "displayName", ascending: true, selector: #selector(NSString.localizedCaseInsensitiveCompare(_:)))]
        let context = ContextManager.sharedInstance().mainContext
        let frc = NSFetchedResultsController(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
        frc.delegate = self
        return frc
    }()

    /// Navigation Bar Custom Title
    ///
    @IBOutlet private var titleButton : NavBarTitleDropdownButton!



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


    // MARK: - NSFetchedResultsController Methods

    public func controllerDidChangeContent(controller: NSFetchedResultsController) {
        refreshNoResultsView()
        tableView.reloadData()
    }


    // MARK: - View Lifecycle Methods

    public override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.titleView = titleButton
        WPStyleGuide.configureColorsForView(view, andTableView: tableView)

        // By default, let's display the Blog's Users
        filter = .Users
    }

    public override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        tableView.deselectSelectedRowWithAnimation(true)
    }

    public override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        tableView.reloadData()
    }

    public override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let personViewController = segue.destinationViewController as? PersonViewController,
            let selectedIndexPath = tableView.indexPathForSelectedRow
        {
            personViewController.blog = blog
            personViewController.person = personAtIndexPath(selectedIndexPath)
        }
    }


    // MARK: - Action Handlers
    @IBAction public func refresh() {
        refreshPeople()
    }

    @IBAction public func titleWasPressed() {
        displayModePicker()
    }


    // MARK: - Interface Helpers

    private func refreshInterface() {
        // Note:
        // We also set the title on purpose, so that whatever VC we push, the back button spells the right title.
        //
        title = filter.title
        titleButton.setAttributedTitleForTitle(filter.title)
    }

    private func refreshResults() {
        resultsController.fetchRequest.predicate = predicate

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

    private func refreshPeople() {
        guard let blog = blog, service = PeopleService(blog: blog) else {
            return
        }

        refreshNoResultsView()

        service.refreshPeople { [weak self] _ in
            self?.refreshNoResultsView()
            self?.refreshControl?.endRefreshing()
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
        let controller              = SettingsSelectionViewController(style: .Grouped)
        controller.title            = NSLocalizedString("Filters", comment: "Title of the list of People Filters")
        controller.titles           = Filter.allFilters.map { $0.title }
        controller.values           = Filter.allFilters.map { $0.rawValue }
        controller.currentValue     = filter.rawValue
        controller.onItemSelected   = { [weak self] selectedValue in
            guard let rawFilter = selectedValue as? String, let filter = Filter(rawValue: rawFilter) else {
                fatalError()
            }

            self?.filter = filter
            self?.dismissViewControllerAnimated(true, completion: nil)
        }

        let navController = UINavigationController(rootViewController: controller)
        presentViewController(navController, animated: true, completion: nil)
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



    // MARK: - Private Helpers

    private enum Filter : String {
        case Users      = "team"
        case Followers  = "followers"

        var title: String {
            switch self {
            case .Users:
                return NSLocalizedString("Users", comment: "Blog Users")
            case .Followers:
                return NSLocalizedString("Followers", comment: "Blog Followers")
            }
        }

        static let allFilters = [Filter.Users, .Followers]
    }


    // MARK: - Constants

    private struct RestorationKeys {
        static let blog = "peopleBlogRestorationKey"
    }
}
