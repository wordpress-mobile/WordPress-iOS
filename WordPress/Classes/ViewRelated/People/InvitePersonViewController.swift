import Foundation
import UIKit
import WordPressShared

/// Allows the user to Invite Followers / Users
///
class InvitePersonViewController : UITableViewController {

    // MARK: - Public Properties

    /// Site ID
    ///
    var siteID: Int!

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
        let placeholder = NSLocalizedString("Email or Username...", comment: "A placeholder for the username textfield.")
        let hint = NSLocalizedString("Email or Username of the person that should receive your invitation.", comment: "Username Placeholder")

        let controller  = SettingsTextViewController(text: invite.username, placeholder: placeholder, hint: hint)
        controller.title = NSLocalizedString("Recipient", comment: "Invite Person: Email or Username Edition Title")
        controller.mode = .Email
        controller.onValueChanged = { [unowned self] value in
            self.invite.username = value
            self.refreshUsernameCell()
        }
// TODO: No validation
        navigationController?.pushViewController(controller, animated: true)
    }

    func roleWasPressed() {
// TODO: Implement Me
    }

    func messageWasPressed() {
// TODO: Implement Me
    }

    @IBAction func cancelWasPressed() {
        dismissViewControllerAnimated(true, completion: nil)
    }

    @IBAction func sendWasPressed() {
// TODO: Implement Me
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
        usernameCell.textLabel?.text = NSLocalizedString("Email or username...", comment: "Invite Username Placeholder")
        WPStyleGuide.configureTableViewCell(usernameCell)
// TODO: Implement Me
    }

    func setupRoleCell() {
        roleCell.textLabel?.text = NSLocalizedString("Role", comment: "User's Role")
        WPStyleGuide.configureTableViewCell(roleCell)
// TODO: Implement Me
    }

    func setupMessageCell() {
// TODO: Implement Me
    }
}


// MARK: - Private Helpers: Refreshing Interface
//
private extension InvitePersonViewController {

    func refreshUsernameCell() {
// TODO: Implement Me
    }

    func refreshRoleCell() {
// TODO: Implement Me
    }

    func refreshMessageCell() {
// TODO: Implement Me
    }
}
