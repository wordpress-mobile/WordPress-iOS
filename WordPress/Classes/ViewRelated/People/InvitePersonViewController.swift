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


    // MARK: - Private Properties

    /// Invitation Username / Email
    ///
    private var usernameOrEmail: String? {
        didSet {
            refreshUsernameCell()
        }
    }

    /// Invitation Role
    ///
    private var role : Role = .Follower {
        didSet {
            refreshRoleCell()
        }
    }

    /// Invitation Message
    ///
    private var message : String? {
        didSet {
            refreshMessageCell()
        }
    }

    /// Last Section Index
    ///
    private var lastSectionIndex : Int {
        return tableView.numberOfSections - 1
    }

    /// Last Section Footer Text
    ///
    private let lastSectionFooter = NSLocalizedString("Add a custom message (optional).", comment: "Invite Footer Text")


    // MARK: - Outlets

    /// Username Cell
    ///
    @IBOutlet private var usernameCell : UITableViewCell! {
        didSet {
            setupUsernameCell()
            refreshUsernameCell()
        }
    }

    /// Role Cell
    ///
    @IBOutlet private var roleCell : UITableViewCell! {
        didSet {
            setupRoleCell()
            refreshRoleCell()
        }
    }

    /// Message Cell
    ///
    @IBOutlet private var messageCell : UITableViewCell! {
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

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        tableView.deselectSelectedRowWithAnimation(true)
    }


    // MARK: - UITableView Methods

    override func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        guard section == lastSectionIndex else {
            return CGFloat.min
        }

        return WPTableViewSectionHeaderFooterView.heightForFooter(lastSectionFooter, width: view.bounds.width)
    }

    override func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard section == lastSectionIndex else {
            return nil
        }

        let headerView = WPTableViewSectionHeaderFooterView(reuseIdentifier: nil, style: .Footer)
        headerView.title = lastSectionFooter
        return headerView
    }


    // MARK: - Storyboard Methods

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        guard let rawIdentifier = segue.identifier, identifier = SegueIdentifier(rawValue: rawIdentifier) else {
            return
        }

        switch identifier {
        case .Username:
            setupUsernameSegue(segue)
        case .Role:
            setupRoleSegue(segue)
        case .Message:
            setupMessageSegue(segue)
        }
    }

    private func setupUsernameSegue(segue: UIStoryboardSegue) {
        guard let textViewController = segue.destinationViewController as? SettingsTextViewController else {
            return
        }

        let title = NSLocalizedString("Recipient", comment: "Invite Person: Email or Username Edition Title")
        let placeholder = NSLocalizedString("Email or Username...", comment: "A placeholder for the username textfield.")
        let hint = NSLocalizedString("Email or Username of the person that should receive your invitation.", comment: "Username Placeholder")

        textViewController.title = title
        textViewController.text = usernameOrEmail
        textViewController.placeholder = placeholder
        textViewController.hint = hint
        textViewController.mode = .Email
        textViewController.onValueChanged = { [unowned self] value in
            self.usernameOrEmail = value
        }

        // Note: Let's disable validation, since the we need to allow Username OR Email
        textViewController.validatesInput = false
    }

    private func setupRoleSegue(segue: UIStoryboardSegue) {
        guard let roleViewController = segue.destinationViewController as? RoleViewController else {
            return
        }

        roleViewController.mode = .Static(roles: Role.inviteRoles)
        roleViewController.selectedRole = role
        roleViewController.onChange = { [unowned self] newRole in
            self.role = newRole
        }
    }

    private func setupMessageSegue(segue: UIStoryboardSegue) {
        guard let textViewController = segue.destinationViewController as? SettingsMultiTextViewController else {
            return
        }

        let title = NSLocalizedString("Message", comment: "Invite Message Editor's Title")
        let hint = NSLocalizedString("Optional message to be included in the Invitation.", comment: "Invite: Message Hint")

        textViewController.title = title
        textViewController.text = message
        textViewController.hint = hint
        textViewController.isPassword = false
        textViewController.onValueChanged = { [unowned self] value in
            self.message = value
        }
    }


    // MARK: - Private Enums

    private enum SegueIdentifier: String {
        case Username   = "username"
        case Role       = "role"
        case Message    = "message"
    }
}


// MARK: - Helpers: Actions
//
extension InvitePersonViewController {

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
        usernameCell.accessoryType = .DisclosureIndicator
        WPStyleGuide.configureTableViewCell(usernameCell)
    }

    func setupRoleCell() {
        roleCell.textLabel?.text = NSLocalizedString("Role", comment: "User's Role")
        roleCell.accessoryType = .DisclosureIndicator
        WPStyleGuide.configureTableViewCell(roleCell)
    }

    func setupMessageCell() {
// TODO: Fix Vertical Alignment
        messageCell.textLabel?.numberOfLines = 0
        WPStyleGuide.configureTableViewCell(messageCell)
    }
}


// MARK: - Private Helpers: Refreshing Interface
//
private extension InvitePersonViewController {

    func refreshUsernameCell() {
        guard let usernameOrEmail = usernameOrEmail?.nonEmptyString() else {
            usernameCell.textLabel?.text = NSLocalizedString("Email or Username...", comment: "Invite Username Placeholder")
            usernameCell.textLabel?.textColor = WPStyleGuide.grey()
            return
        }

        usernameCell.textLabel?.text = usernameOrEmail
        usernameCell.textLabel?.textColor = WPStyleGuide.darkGrey()
    }

    func refreshRoleCell() {
        roleCell.detailTextLabel?.text = role.localizedName
    }

    func refreshMessageCell() {
        messageCell.textLabel?.text = message
    }
}
