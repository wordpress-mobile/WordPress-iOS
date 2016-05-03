import Foundation
import UIKit
import WordPressShared

/// Displays a Person Role Picker
///
class RoleViewController : UITableViewController {
    
    typealias Role = Person.Role
    
    var role        : Role!
    var onChange    : ((role: Role) -> Void)?
    
    
    // MARK: - View Lifecyle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = NSLocalizedString("Role", comment: "User Roles Title")
        WPStyleGuide.configureColorsForView(view, andTableView: tableView)
    }
    
    
    // MARK: - UITableView Methods
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return numberOfSections
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Role.roles.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(reusableIdentifier, forIndexPath: indexPath)
        let roleForCurrentRow = roleAtIndexPath(indexPath)
        
        cell.textLabel?.text = roleForCurrentRow.localizedName()
        cell.accessoryType = (roleForCurrentRow == role) ? .Checkmark : .None
        
        WPStyleGuide.configureTableViewCell(cell)
        
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectSelectedRowWithAnimationAfterDelay(true)
        
        let roleForSelectedRow = roleAtIndexPath(indexPath)
        guard role != roleForSelectedRow else {
            return
        }
        
        // Refresh Interface
        role = roleForSelectedRow
        tableView.reloadDataPreservingSelection()
        
        // Callback
        onChange?(role: role)
        navigationController?.popViewControllerAnimated(true)
    }
    
    
    // MARK: - Private Methods
    private func roleAtIndexPath(indexPath: NSIndexPath) -> Role {
        return Role.roles[indexPath.row]
    }
    
    
    // MARK: - Private Constants
    private let numberOfSections = 1
    private let reusableIdentifier = "roleCell"
}
