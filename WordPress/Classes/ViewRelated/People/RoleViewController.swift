import Foundation
import UIKit
import WordPressShared

/// Displays a Person Role Picker
///
class RoleViewController: UITableViewController {

    /// RoleViewController operation modes
    ///
    enum Mode {
        /// Dynamic Mode: The list of available roles will be downloaded from the blog's remote endpoint.
        ///
        case dynamic(blog: Blog)

        /// Static Mode: The list of modes must be provided
        ///
        case `static`(roles: [Role])
    }

    /// Specifies the way RoleViewController behaves
    ///
    var mode: Mode? {
        didSet {
            guard let mode = mode else {
                return
            }

            switch mode {
            case .dynamic(let blog):
                self.blog = blog
            case .static(let list):
                self.roles = list
            }
        }
    }

    /// Optional Person Blog. When set, will be used to refresh the list of available roles.
    ///
    fileprivate var blog: Blog?

    /// Available Roles for the current blog.
    ///
    fileprivate var roles = [Role]()

    /// Currently Selected Role
    ///
    var selectedRole: Role!

    /// Closure to be executed whenever the selected role changes.
    ///
    var onChange: ((Role) -> Void)?

    /// Activity Spinner, to be animated during Backend Interaction
    ///
    fileprivate let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)



    // MARK: - View Lifecyle Methods
    override func viewDidLoad() {
        super.viewDidLoad()

        assert(mode != nil)
        title = NSLocalizedString("Role", comment: "User Roles Title")
        setupActivityIndicator()
        WPStyleGuide.configureColors(for: view, andTableView: tableView)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshAvailableRolesIfNeeded()
    }


    // MARK: - Private Helpers
    fileprivate func setupActivityIndicator() {
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(activityIndicator)
        view.pinSubviewAtCenter(activityIndicator)
    }

    fileprivate func refreshAvailableRolesIfNeeded() {
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
    override func numberOfSections(in tableView: UITableView) -> Int {
        return numberOfSections
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return roles.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reusableIdentifier, for: indexPath)
        let roleForCurrentRow = roleAtIndexPath(indexPath)

        cell.textLabel?.text = roleForCurrentRow.localizedName
        cell.accessoryType = (roleForCurrentRow == selectedRole) ? .checkmark : .none

        WPStyleGuide.configureTableViewCell(cell)

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
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
        _ = navigationController?.popViewController(animated: true)
    }


    // MARK: - Private Methods
    fileprivate func roleAtIndexPath(_ indexPath: IndexPath) -> Role {
        return roles[indexPath.row]
    }


    // MARK: - Private Constants
    fileprivate let numberOfSections = 1
    fileprivate let reusableIdentifier = "roleCell"
}
