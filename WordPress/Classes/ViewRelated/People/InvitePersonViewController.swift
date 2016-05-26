import Foundation
import UIKit
import WordPressShared

/// Allows the user to Invite Followers / Users
///
class InvitePersonViewController : UITableViewController {

    // MARK: - Public Properties

    /// Person's Username
    ///
    @IBOutlet var usernameCell : UITableViewCell! {
        didSet {
            setupUsernameCell()
            refreshUsernameCell()
        }
    }

    /// Person's Role
    ///
    @IBOutlet var roleCell : UITableViewCell! {
        didSet {
            setupRoleCell()
            refreshRoleCell()
        }
    }

    /// Invite Message
    ///
    @IBOutlet var messageCell : UITableViewCell! {
        didSet {
            setupMessageCell()
            refreshMessageCell()
        }
    }


    // MARK: - View Lifecyle Methods

    override func viewDidLoad() {
        super.viewDidLoad()

        setupNavigationBar()
        WPStyleGuide.configureColorsForView(view, andTableView: tableView)
    }


    // MARK: - UITableView Methods

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectSelectedRowWithAnimation(true)

        guard let cell = tableView.cellForRowAtIndexPath(indexPath) else {
            return
        }

        switch cell {
        case usernameCell:
            usernameWasPressed()
        case roleCell:
            roleWasPressed()
        case messageCell:
            messageWasPressed()
        default:
            break
        }
    }
}


// MARK: - Helpers: Actions
//
extension InvitePersonViewController {

    func usernameWasPressed() {

    }

    func roleWasPressed() {

    }

    func messageWasPressed() {

    }
    
    @IBAction func cancelWasPressed() {
        dismissViewControllerAnimated(true, completion: nil)
    }

    @IBAction func sendWasPressed() {

    }
}


// MARK: - Private Helpers: Initializing Interface
//
private extension InvitePersonViewController {

    func setupNavigationBar() {
        title = NSLocalizedString("Add a Person", comment: "Invite People Title")

        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Cancel,
                                                           target: self,
                                                           action: #selector(cancelWasPressed))

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: NSLocalizedString("Invite", comment: "Send Person Invite"),
                                                            style: .Plain,
                                                            target: self,
                                                            action: #selector(sendWasPressed))
    }
}


// MARK: - Private Helpers: Initializing Interface
//
private extension InvitePersonViewController {

    func setupUsernameCell() {

    }

    func setupRoleCell() {

    }

    func setupMessageCell() {

    }
}


// MARK: - Private Helpers: Refreshing Interface
//
private extension InvitePersonViewController {

    func refreshUsernameCell() {

    }

    func refreshRoleCell() {

    }

    func refreshMessageCell() {

    }
}
