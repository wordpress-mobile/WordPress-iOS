import UIKit
import WordPressShared

public class PeopleViewController: UITableViewController, NSFetchedResultsControllerDelegate, UIViewControllerRestoration {

    // MARK: - Properties

    public var blog: Blog?

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

    private let noResultsView = WPNoResultsView()


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

        WPStyleGuide.configureColorsForView(view, andTableView: tableView)
    }

    public override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        tableView.deselectSelectedRowWithAnimation(true)

        displayNoResultsIfNeeded()
        refresh()
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


    // MARK: - UIStateRestoring

    public override func encodeRestorableStateWithCoder(coder: NSCoder) {
        let objectString = blog?.objectID.URIRepresentation().absoluteString
        coder.encodeObject(objectString, forKey: RestorationKeys.blog)
        super.encodeRestorableStateWithCoder(coder)
    }


    // MARK: - Refresh Helpers

    @IBAction public func refresh() {
        guard let blog = blog, service = PeopleService(blog: blog) else {
            return
        }

        service.refreshTeam { [weak self] _ in
            self?.refreshControl?.endRefreshing()
            self?.hideNoResultsIfNeeded()
        }
    }


    // MARK: - Private Helpers

    private func personAtIndexPath(indexPath: NSIndexPath) -> Person {
        let managedPerson = resultsController.objectAtIndexPath(indexPath) as! ManagedPerson
        let person = Person(managedPerson: managedPerson)
        return person
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


    // MARK: - UIViewControllerRestoration

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

        return self.controllerWithBlog(blog)
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



    // MARK: - Constants

    private struct RestorationKeys {
        static let blog = "peopleBlogRestorationKey"
    }
}
