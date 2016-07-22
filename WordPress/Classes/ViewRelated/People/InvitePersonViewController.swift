import Foundation
import UIKit
import WordPressShared
import SVProgressHUD



/// Allows the user to Invite Followers / Users
///
class InvitePersonViewController : UITableViewController {

    // MARK: - Public Properties

    /// Target Blog
    ///
    var blog: Blog!

    /// Core Data Context
    ///
    let context = ContextManager.sharedInstance().mainContext

    // MARK: - Private Properties

    /// Invitation Username / Email
    ///
    private var usernameOrEmail: String? {
        didSet {
            refreshUsernameCell()
            validateInvitation()
        }
    }

    /// Invitation Role
    ///
    private var role : Role = .Follower {
        didSet {
            refreshRoleCell()
            validateInvitation()
        }
    }

    /// Invitation Message
    ///
    private var message : String? {
        didSet {
            refreshMessageTextView()

            // Note: This is a workaround. For some reason, the textView's properties are getting reset
            setupMessageTextView()
        }
    }

    /// Last Section Index
    ///
    private var lastSectionIndex : Int {
        return tableView.numberOfSections - 1
    }

    /// Last Section Footer Text
    ///
    private let lastSectionFooterText = NSLocalizedString("Add a custom message (optional).", comment: "Invite Footer Text")


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
    @IBOutlet private var messageTextView : UITextView! {
        didSet {
            setupMessageTextView()
            refreshMessageTextView()
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

    override func tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        guard section == lastSectionIndex else {
            return nil
        }
        return lastSectionFooterText
    }

    override func tableView(tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        WPStyleGuide.configureTableViewSectionFooter(view)
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
        textViewController.onValueChanged = { [unowned self] value in
            self.usernameOrEmail = value.nonEmptyString()
        }

        // Note: Let's disable validation, since we need to allow Username OR Email
        textViewController.validatesInput = false
        textViewController.autocorrectionType = .No
        textViewController.mode = .Email
    }

    private func setupRoleSegue(segue: UIStoryboardSegue) {
        guard let roleViewController = segue.destinationViewController as? RoleViewController else {
            return
        }

        let roles = (blog.siteVisibility == .Private) ? Role.inviteRolesForPrivateSite : Role.inviteRoles

        roleViewController.mode = .Static(roles: roles)
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
        let hint = NSLocalizedString("Optional message to be included in the invitation.", comment: "Invite: Message Hint")

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
        guard let recipient = usernameOrEmail else {
            return
        }

        // Notes:
        //  -   We'll hit the actual send call once the dismiss is wrapped up.
        //  -   If, for networking reasons, the call fails instantly, UIAlertViewController presentation will
        //      fail, because it'll get attached to a VC that's getting dismissed.
        //
        // Thank you Apple . I love you too.
        //
        dismissViewControllerAnimated(true) {
            self.sendInvitation(self.blog, recipient: recipient, role: self.role, message: self.message ?? "")
        }
    }

    func sendInvitation(blog: Blog, recipient: String, role: Role, message: String) {
        guard let service = PeopleService(blog: blog, context: context) else {
            return
        }

        service.sendInvitation(recipient, role: role, message: message, success: {
            let success = NSLocalizedString("Invitation Sent!", comment: "The app successfully sent an invitation")
            SVProgressHUD.showSuccessWithStatus(success)

        }, failure: { error in
            self.handleSendError() {
                self.sendInvitation(blog, recipient: recipient, role: role, message: message)
            }
        })
    }

    func handleSendError(onRetry: (Void -> Void)) {
        let message = NSLocalizedString("There has been an unexpected error while sending your Invitation", comment: "Invite Failed Message")
        let cancelText = NSLocalizedString("Cancel", comment: "Cancels an Action")
        let retryText = NSLocalizedString("Try Again", comment: "Retries an Action")

        let alertController = UIAlertController(title: nil, message: message, preferredStyle: .Alert)

        alertController.addCancelActionWithTitle(cancelText)
        alertController.addDefaultActionWithTitle(retryText) { action in
            onRetry()
        }

        // Note: This viewController might not be visible anymore
        alertController.presentFromRootViewController()
    }
}


// MARK: - Helpers: Validation
//
private extension InvitePersonViewController {

    func validateInvitation() {
        guard let usernameOrEmail = usernameOrEmail, service = PeopleService(blog: blog, context: context) else {
            sendActionEnabled = false
            return
        }

        service.validateInvitation(usernameOrEmail, role: role, success: { [weak self] in
            guard self?.shouldHandleValidationResponse(usernameOrEmail) == true else {
                return
            }

            self?.sendActionEnabled = true

        }, failure: { [weak self] error in
            guard self?.shouldHandleValidationResponse(usernameOrEmail) == true else {
                return
            }

            self?.sendActionEnabled = false
            self?.handleValidationError(error)
        })
    }

    func shouldHandleValidationResponse(requestUsernameOrEmail: String) -> Bool {
        // Handle only whenever the recipient didn't change
        let recipient = usernameOrEmail ?? String()
        return recipient == requestUsernameOrEmail
    }

    func handleValidationError(error: ErrorType) {
        guard let error = error as? PeopleRemote.Error else {
            return
        }

        let messageMap : [PeopleRemote.Error: String] = [
            .InvalidInputError       : NSLocalizedString("The specified user cannot be found. Please, verify if it's correctly spelt.",
                                                            comment: "People: Invitation Error"),
            .UserAlreadyHasRoleError : NSLocalizedString("The user already has the specified role. Please, try assigning a different role.",
                                                            comment: "People: Invitation Error"),
            .UnknownError            : NSLocalizedString("Unknown error has occurred",
                                                            comment: "People: Invitation Error")
        ]

        let message = messageMap[error] ?? messageMap[.UnknownError]!
        let title = NSLocalizedString("Sorry!", comment: "Invite Validation Alert")
        let accept = NSLocalizedString("Accept", comment: "Invite Accept Button")
        let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)

        alert.addDefaultActionWithTitle(accept)
        presentViewController(alert, animated: true, completion: nil)
    }

    var sendActionEnabled : Bool {
        get {
            return navigationItem.rightBarButtonItem?.enabled ?? false
        }
        set {
            navigationItem.rightBarButtonItem?.enabled = newValue
        }
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

    func setupMessageTextView() {
        messageTextView.font = WPStyleGuide.tableviewTextFont()
        messageTextView.textColor = WPStyleGuide.darkGrey()
    }

    func setupNavigationBar() {
        title = NSLocalizedString("Add a Person", comment: "Invite People Title")

        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Cancel,
                                                           target: self,
                                                           action: #selector(cancelWasPressed))

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: NSLocalizedString("Invite", comment: "Send Person Invite"),
                                                            style: .Plain,
                                                            target: self,
                                                            action: #selector(sendWasPressed))

        // By default, Send is disabled
        navigationItem.rightBarButtonItem?.enabled = false
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

    func refreshMessageTextView() {
        messageTextView.text = message
    }
}
