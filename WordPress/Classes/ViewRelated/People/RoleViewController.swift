import Foundation
import UIKit
import WordPressShared

/// Displays a Person Role Picker
///
class RoleViewController: UITableViewController {

    /// List of available roles.
    ///
    var roles: [RemoteRole] = []

    /// Currently Selected Role
    ///
    @objc var selectedRole: String!

    /// Closure to be executed whenever the selected role changes.
    ///
    @objc var onChange: ((String) -> Void)?

    /// Activity Spinner, to be animated during Backend Interaction
    ///
    fileprivate let activityIndicator = UIActivityIndicatorView(style: .medium)

    // MARK: - View Lifecyle Methods
    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("Role", comment: "User Roles Title")
        setupActivityIndicator()
        WPStyleGuide.configureColors(view: view, tableView: tableView)
        WPStyleGuide.configureAutomaticHeightRows(for: tableView)
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
        onChange?(roleForSelectedRow.slug)
        _ = navigationController?.popViewController(animated: true)
    }


    // MARK: - Private Methods
    fileprivate func roleAtIndexPath(_ indexPath: IndexPath) -> RemoteRole {
        return roles[indexPath.row]
    }


    // MARK: - Private Constants
    fileprivate let numberOfSections = 1
    fileprivate let reusableIdentifier = "roleCell"
}
