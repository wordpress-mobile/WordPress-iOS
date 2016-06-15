import Foundation
import UIKit
import WordPressShared

/// Displays a Person Role Picker
///
class RoleViewController : UITableViewController {

    /// RoleViewController operation modes
    ///
    enum Mode {
        /// Dynamic Mode: The list of available roles will be downloaded from the blog's remote endpoint.
        ///
        case Dynamic(blog: Blog)

        /// Static Mode: The list of modes must be provided
        ///
        case Static(roles: [Role])
    }

    /// Specifies the way RoleViewController behaves
    ///
    var mode : Mode? {
        didSet {
            guard let mode = mode else {
                return
            }

            switch mode {
            case .Dynamic(let blog):
                self.blog = blog
            case .Static(let list):
                self.roles = list
            }
        }
    }

    /// Optional Person Blog. When set, will be used to refresh the list of available roles.
    ///
    private var blog : Blog?

    /// Available Roles for the current blog.
    ///
    private var roles = [Role]()

    /// Currently Selected Role
    ///
    var selectedRole : Role!

    /// Closure to be executed whenever the selected role changes.
    ///
    var onChange : (Role -> Void)?

    /// Activity Spinner, to be animated during Backend Interaction
    ///
    private let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .Gray)



    // MARK: - View Lifecyle Methods
    override func viewDidLoad() {
        super.viewDidLoad()

        assert(mode != nil)
        title = NSLocalizedString("Role", comment: "User Roles Title")
        setupActivityIndicator()
        WPStyleGuide.configureColorsForView(view, andTableView: tableView)
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        refreshAvailableRolesIfNeeded()
    }


    // MARK: - Private Helpers
    private func setupActivityIndicator() {
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(activityIndicator)
        view.pinSubviewAtCenter(activityIndicator)
    }

    private func refreshAvailableRolesIfNeeded() {
        guard let blog = blog else {
            return
        }

        activityIndicator.startAnimating()

        let context = ContextManager.sharedInstance().mainContext
        let service = PeopleService(blog: blog, context: context)
        service?.loadAvailableRoles({ roles in
            self.roles = roles
            self.tableView.reloadData()
            self.activityIndicator.stopAnimating()
        }, failure: { error in
            self.activityIndicator.stopAnimating()
        })
    }


    // MARK: - UITableView Methods
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return numberOfSections
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return roles.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(reusableIdentifier, forIndexPath: indexPath)
        let roleForCurrentRow = roleAtIndexPath(indexPath)

        cell.textLabel?.text = roleForCurrentRow.localizedName
        cell.accessoryType = (roleForCurrentRow == selectedRole) ? .Checkmark : .None

        WPStyleGuide.configureTableViewCell(cell)

        return cell
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectSelectedRowWithAnimationAfterDelay(true)

        let roleForSelectedRow = roleAtIndexPath(indexPath)
        guard selectedRole != roleForSelectedRow else {
            return
        }

        // Refresh Interface
        selectedRole = roleForSelectedRow
        tableView.reloadDataPreservingSelection()

        // Callback
        onChange?(roleForSelectedRow)
        navigationController?.popViewControllerAnimated(true)
    }


    // MARK: - Private Methods
    private func roleAtIndexPath(indexPath: NSIndexPath) -> Role {
        return roles[indexPath.row]
    }


    // MARK: - Private Constants
    private let numberOfSections = 1
    private let reusableIdentifier = "roleCell"
}
