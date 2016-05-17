import UIKit
import WordPressShared

public class PeopleViewController: UITableViewController, NSFetchedResultsControllerDelegate, UIViewControllerRestoration {

    // MARK: - Properties

    /// Team's Blog
    ///
    public var blog: Blog?

    /// Mode: Team / Followers
    ///
    private var mode : Mode! {
        didSet {
            refreshInterface()
            refreshTeam()
        }
    }

    /// NoResults Helper
    ///
    private let noResultsView = WPNoResultsView()

    /// Core Data FRC
    ///
    private lazy var resultsController: NSFetchedResultsController = {
        let request = NSFetchRequest(entityName: "Person")
        request.predicate = NSPredicate(format: "siteID = %@", self.blog!.dotComID!)
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
        tableView.reloadData()
    }


    // MARK: - View Lifecycle Methods

    public override func viewDidLoad() {
        super.viewDidLoad()

        do {
            try resultsController.performFetch()
        } catch {
            DDLogSwift.logError("Error fetching People: \(error)")
        }

        navigationItem.titleView = titleButton
        WPStyleGuide.configureColorsForView(view, andTableView: tableView)
    }

    public override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        tableView.deselectSelectedRowWithAnimation(true)

        // By default, let's display the Blog's Users
        mode = .Team
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



    // MARK: - Refresh Helpers

    @IBAction public func refresh() {
        guard let blog = blog, service = PeopleService(blog: blog) else {
            return
        }

        service.refreshUsers { [weak self] _ in
            self?.refreshControl?.endRefreshing()
            self?.hideNoResultsIfNeeded()
        }
    }

    @IBAction public func titleWasPressed() {
        displayModePicker()
    }


    }

    private func displayNoResultsIfNeeded() {
        if resultsController.fetchedObjects?.count > 0 {
            return
        }

        noResultsView.titleText = NSLocalizedString("Loading...", comment: "")
        tableView.addSubviewWithFadeAnimation(noResultsView)
    }

    private func hideNoResultsIfNeeded() {
        noResultsView.removeFromSuperview()
    }

    // MARK: - Private Helpers

    private func personAtIndexPath(indexPath: NSIndexPath) -> Person {
        let managedPerson = resultsController.objectAtIndexPath(indexPath) as! ManagedPerson
        let person = Person(managedPerson: managedPerson)
        return person
    }

    private func displayModePicker() {
        let controller              = SettingsSelectionViewController(style: .Plain)
        controller.title            = NSLocalizedString("Filters", comment: "Title of the list of People Filters")
        controller.titles           = Mode.allModes.map { $0.title }
        controller.values           = Mode.allModes.map { $0.rawValue }
        controller.currentValue     = mode.rawValue
        controller.onItemSelected   = { [weak self] selectedValue in
            guard let rawMode = selectedValue as? String, let mode = Mode(rawValue: rawMode) else {
                fatalError()
            }

            self?.mode = mode
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

    private enum Mode : String {
        case Team       = "team"
        case Followers  = "followers"

        var title: String {
            switch self {
            case .Team:
                return NSLocalizedString("Team", comment: "Blog Users")
            case .Followers:
                return NSLocalizedString("Followers", comment: "Blog Followers")
            }
        }

        static let allModes = [Mode.Team, .Followers]
    }


    // MARK: - Constants

    private struct RestorationKeys {
        static let blog = "peopleBlogRestorationKey"
    }
}
