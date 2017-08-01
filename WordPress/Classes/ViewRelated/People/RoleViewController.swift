import Foundation
import UIKit
import WordPressShared

/// Displays a Person Role Picker
///
class RoleViewController: UITableViewController {

    /// Optional Person Blog. When set, will be used to refresh the list of available roles.
    ///
    var blog: Blog?

    /// Currently Selected Role
    ///
    var selectedRole: String!

    /// Closure to be executed whenever the selected role changes.
    ///
    var onChange: ((Role) -> Void)?

    /// Activity Spinner, to be animated during Backend Interaction
    ///
    fileprivate let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)

    fileprivate var roles: [Role] {
        return blog?.roles.map(Array<Role>.init) ?? []
    }

    // MARK: - View Lifecyle Methods
    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("Role", comment: "User Roles Title")
        setupActivityIndicator()
        WPStyleGuide.configureColors(for: view, andTableView: tableView)
    }

    // MARK: - Private Helpers
    fileprivate func setupActivityIndicator() {
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(activityIndicator)
        view.pinSubviewAtCenter(activityIndicator)
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

        cell.textLabel?.text = roleForCurrentRow.name
        cell.accessoryType = (roleForCurrentRow.slug == selectedRole) ? .checkmark : .none

        WPStyleGuide.configureTableViewCell(cell)

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectSelectedRowWithAnimationAfterDelay(true)

        let roleForSelectedRow = roleAtIndexPath(indexPath)
        guard selectedRole != roleForSelectedRow.slug else {
            return
        }

        // Refresh Interface
        selectedRole = roleForSelectedRow.slug
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
