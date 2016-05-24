import Foundation
import UIKit
import WordPressShared

/// Displays a Person Role Picker
///
class RoleViewController : UITableViewController {

    /// Person's Blog
    ///
    var blog : Blog!

    /// Currently Selected Role
    ///
    var selectedRole : Role!

    /// Closure to be executed whenever the selected role changes.
    ///
    var onChange : (Role -> Void)?

    /// Private collection of roles, available for the current blog.
    ///
    private var roles = [Role]()

    /// Activity Spinner, to be animated during Backend Interaction
    ///
    private let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .Gray)



    // MARK: - View Lifecyle Methods
    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("Role", comment: "User Roles Title")
        setupActivityIndicator()
        WPStyleGuide.configureColorsForView(view, andTableView: tableView)
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        refreshAvailableRoles()
    }


    // MARK: - Private Helpers
    private func setupActivityIndicator() {
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(activityIndicator)
        view.pinSubviewAtCenter(activityIndicator)
    }

    private func refreshAvailableRoles() {
        activityIndicator.startAnimating()

        let service = PeopleService(blog: blog)
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
