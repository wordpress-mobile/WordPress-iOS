import Foundation
import UIKit
import WordPressShared
import SVProgressHUD



/// Allows the user to Invite Followers / Users
///
class InvitePersonViewController: UITableViewController {

    // MARK: - Public Properties

    /// Target Blog
    ///
    @objc var blog: Blog!

    /// Core Data Context
    ///
    @objc let context = ContextManager.sharedInstance().mainContext

    // MARK: - Private Properties

    /// Invitation Username / Email
    ///
    fileprivate var usernameOrEmail: String? {
        didSet {
            refreshUsernameCell()
            validateInvitation()
        }
    }

    /// Invitation Role
    ///
    fileprivate var role: RemoteRole? {
        didSet {
            refreshRoleCell()
            validateInvitation()
        }
    }

    /// Invitation Message
    ///
    fileprivate var message: String? {
        didSet {
            refreshMessageTextView()

            // Note: This is a workaround. For some reason, the textView's properties are getting reset
            setupMessageTextView()
        }
    }

    /// Roles available for the current site
    ///
    fileprivate var availableRoles: [RemoteRole] {
        let blogRoles = blog?.sortedRoles ?? []
        var roles = [RemoteRole]()
        let inviteRole: RemoteRole
        if blog.isPrivateAtWPCom() {
            inviteRole = RemoteRole.viewer
        } else {
            inviteRole = RemoteRole.follower
        }
        roles += blogRoles.map({ $0.toUnmanaged() })
        roles.append(inviteRole)
        return roles
    }

    private let rolesDefinitionUrl = "https://wordpress.com/support/user-roles/"
    private let messageCharacterLimit = 500

    // MARK: - Outlets

    /// Username Cell
    ///
    @IBOutlet fileprivate var usernameCell: UITableViewCell! {
        didSet {
            setupUsernameCell()
            refreshUsernameCell()
        }
    }

    /// Role Cell
    ///
    @IBOutlet fileprivate var roleCell: UITableViewCell! {
        didSet {
            setupRoleCell()
            refreshRoleCell()
        }
    }

    /// Message Placeholder Label
    ///
    @IBOutlet private var placeholderLabel: UILabel! {
        didSet {
            setupPlaceholderLabel()
        }
    }

    /// Message Cell
    ///
    @IBOutlet private var messageTextView: UITextView! {
        didSet {
            setupMessageTextView()
            refreshMessageTextView()
        }
    }



    // MARK: - View Lifecyle Methods

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupDefaultRole()
        WPStyleGuide.configureColors(view: view, tableView: tableView)
        WPStyleGuide.configureAutomaticHeightRows(for: tableView)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.deselectSelectedRowWithAnimation(true)
    }


    // MARK: - UITableView Methods

    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        let sectionType = Section(rawValue: section)
        var footerText = sectionType?.footerText

        if sectionType == .message,
           let footerFormat = footerText {
            footerText = String(format: footerFormat, messageCharacterLimit)
        }

        return footerText
    }

    override func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        addTapGesture(toView: view, inSection: section)
        WPStyleGuide.configureTableViewSectionFooter(view)
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Workaround for UIKit issue where labels text are set to nil
        // when user changes system font size in static tables (dynamic type)
        setupRoleCell()
        refreshRoleCell()
        refreshUsernameCell()
        refreshMessageTextView()
        return super.tableView(tableView, cellForRowAt: indexPath)
    }


    // MARK: - Storyboard Methods

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let rawIdentifier = segue.identifier, let identifier = SegueIdentifier(rawValue: rawIdentifier) else {
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

    fileprivate func setupUsernameSegue(_ segue: UIStoryboardSegue) {
        guard let textViewController = segue.destination as? SettingsTextViewController else {
            return
        }

        let title = NSLocalizedString("Recipient", comment: "Invite Person: Email or Username Edition Title")
        let placeholder = NSLocalizedString("Email or Username…", comment: "A placeholder for the username textfield.")
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
        textViewController.autocorrectionType = .no
        textViewController.mode = .email
    }

    fileprivate func setupRoleSegue(_ segue: UIStoryboardSegue) {
        guard let roleViewController = segue.destination as? RoleViewController else {
            return
        }

        roleViewController.roles = availableRoles
        roleViewController.selectedRole = role?.slug
        roleViewController.onChange = { [unowned self] newRole in
            self.role = self.availableRoles.first(where: { $0.slug == newRole })
        }
    }

    fileprivate func setupMessageSegue(_ segue: UIStoryboardSegue) {
        guard let textViewController = segue.destination as? SettingsMultiTextViewController else {
            return
        }

        let title = NSLocalizedString("Message", comment: "Invite Message Editor's Title")
        let hintFormat = NSLocalizedString("Optional message up to %1$d characters to be included in the invitation.", comment: "Invite: Message Hint. %1$d is the maximum number of characters allowed.")
        let hint = String(format: hintFormat, messageCharacterLimit)

        textViewController.title = title
        textViewController.text = message
        textViewController.hint = hint
        textViewController.isPassword = false
        textViewController.maxCharacterCount = messageCharacterLimit
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

    // The case order matches the custom sections order in People.storyboard.
    private enum Section: Int {
        case username
        case role
        case message

        var footerText: String? {
            switch self {
            case .role:
                return NSLocalizedString("Learn more about roles", comment: "Footer text for Invite People role field.")
            case .message:
                // messageCharacterLimit cannot be accessed here, so the caller will insert it in the string.
                return NSLocalizedString("Optional: Enter a custom message up to %1$d characters to be sent with your invitation.", comment: "Footer text for Invite People message field. %1$d is the maximum number of characters allowed.")
            default:
                return nil
            }
        }
    }

}


// MARK: - Helpers: Actions
//
extension InvitePersonViewController {

    @IBAction func cancelWasPressed() {
        dismiss(animated: true)
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
        dismiss(animated: true) {
            guard let role = self.role else {
                return
            }
            self.sendInvitation(self.blog, recipient: recipient, role: role.slug, message: self.message ?? "")
        }
    }

    @objc func sendInvitation(_ blog: Blog, recipient: String, role: String, message: String) {
        guard let service = PeopleService(blog: blog, context: context) else {
            return
        }

        service.sendInvitation(recipient, role: role, message: message, success: {
            let success = NSLocalizedString("Invitation Sent!", comment: "The app successfully sent an invitation")
            SVProgressHUD.showDismissibleSuccess(withStatus: success)

        }, failure: { error in
            self.handleSendError() {
                self.sendInvitation(blog, recipient: recipient, role: role, message: message)
            }
        })
    }

    @objc func handleSendError(_ onRetry: @escaping (() -> Void)) {
        let message = NSLocalizedString("There has been an unexpected error while sending your Invitation", comment: "Invite Failed Message")
        let cancelText = NSLocalizedString("Cancel", comment: "Cancels an Action")
        let retryText = NSLocalizedString("Try Again", comment: "Retries an Action")

        let alertController = UIAlertController(title: nil, message: message, preferredStyle: .alert)

        alertController.addCancelActionWithTitle(cancelText)
        alertController.addDefaultActionWithTitle(retryText) { action in
            onRetry()
        }

        // Note: This viewController might not be visible anymore
        alertController.presentFromRootViewController()
    }

    private func addTapGesture(toView footerView: UIView, inSection section: Int) {
        guard let footer = footerView as? UITableViewHeaderFooterView,
           Section(rawValue: section) == .role else {
            return
        }

        footer.textLabel?.isUserInteractionEnabled = true
        footer.accessibilityTraits = .link
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleRoleFooterTap(_:)))
        footer.addGestureRecognizer(tap)
    }

    @objc private func handleRoleFooterTap(_ sender: UITapGestureRecognizer) {
        guard let url = URL(string: rolesDefinitionUrl) else {
            return
        }

        let webViewController = WebViewControllerFactory.controller(url: url)
        let navController = UINavigationController(rootViewController: webViewController)
        present(navController, animated: true)
    }
}


// MARK: - Helpers: Validation
//
private extension InvitePersonViewController {

    func validateInvitation() {
        guard let usernameOrEmail = usernameOrEmail, let service = PeopleService(blog: blog, context: context) else {
            sendActionEnabled = false
            return
        }

        guard let role = role else {
            return
        }

        service.validateInvitation(usernameOrEmail, role: role.slug, success: { [weak self] in
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

    func shouldHandleValidationResponse(_ requestUsernameOrEmail: String) -> Bool {
        // Handle only whenever the recipient didn't change
        let recipient = usernameOrEmail ?? String()
        return recipient == requestUsernameOrEmail
    }

    func handleValidationError(_ error: Error) {
        guard let error = error as? PeopleServiceRemote.ResponseError else {
            return
        }

        let messageMap: [PeopleServiceRemote.ResponseError: String] = [
            .invalidInputError: NSLocalizedString("The specified user cannot be found. Please, verify if it's correctly spelt.",
                                                  comment: "People: Invitation Error"),
            .userAlreadyHasRoleError: NSLocalizedString("The user already has the specified role. Please, try assigning a different role.",
                                                        comment: "People: Invitation Error"),
            .unknownError: NSLocalizedString("Unknown error has occurred",
                                             comment: "People: Invitation Error")
        ]

        let message = messageMap[error] ?? messageMap[.unknownError]!
        let title = NSLocalizedString("Sorry!", comment: "Invite Validation Alert")
        let okTitle = NSLocalizedString("OK", comment: "Alert dismissal title")
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)

        alert.addDefaultActionWithTitle(okTitle)
        present(alert, animated: true)
    }

    var sendActionEnabled: Bool {
        get {
            return navigationItem.rightBarButtonItem?.isEnabled ?? false
        }
        set {
            navigationItem.rightBarButtonItem?.isEnabled = newValue
        }
    }
}


// MARK: - Private Helpers: Initializing Interface
//
private extension InvitePersonViewController {

    func setupUsernameCell() {
        usernameCell.accessoryType = .disclosureIndicator
        WPStyleGuide.configureTableViewCell(usernameCell)
    }

    func setupRoleCell() {
        roleCell.textLabel?.text = NSLocalizedString("Role", comment: "User's Role")
        roleCell.textLabel?.textColor = .text
        roleCell.accessoryType = .disclosureIndicator
        WPStyleGuide.configureTableViewCell(roleCell)
    }

    func setupMessageTextView() {
        messageTextView.font = WPStyleGuide.tableviewTextFont()
        messageTextView.textColor = .text
        messageTextView.backgroundColor = .listForeground
        messageTextView.delegate = self
    }

    func setupPlaceholderLabel() {
        placeholderLabel.text = NSLocalizedString("Custom message…", comment: "Placeholder for Invite People message field.")
        placeholderLabel.font = WPStyleGuide.tableviewTextFont()
        placeholderLabel.textColor = UIColor.textPlaceholder
    }

    func setupNavigationBar() {
        title = NSLocalizedString("Invite People", comment: "Invite People Title")

        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel,
                                                           target: self,
                                                           action: #selector(cancelWasPressed))

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: NSLocalizedString("Invite", comment: "Send Person Invite"),
                                                            style: .plain,
                                                            target: self,
                                                            action: #selector(sendWasPressed))

        // By default, Send is disabled
        navigationItem.rightBarButtonItem?.isEnabled = false
    }

    func setupDefaultRole() {
        guard let lastRole = availableRoles.last else {
            return
        }

        role = lastRole
    }
}


// MARK: - Private Helpers: Refreshing Interface
//
private extension InvitePersonViewController {

    func refreshUsernameCell() {
        guard let usernameOrEmail = usernameOrEmail?.nonEmptyString() else {
            usernameCell.textLabel?.text = NSLocalizedString("Email or Username…", comment: "Invite Username Placeholder")
            usernameCell.textLabel?.textColor = .textPlaceholder
            return
        }

        usernameCell.textLabel?.text = usernameOrEmail
        usernameCell.textLabel?.textColor = .text
    }

    func refreshRoleCell() {
        roleCell.detailTextLabel?.text = role?.name
    }

    func refreshMessageTextView() {
        messageTextView.text = message
        refreshPlaceholderLabel()
    }

    func refreshPlaceholderLabel() {
        placeholderLabel?.isHidden = !messageTextView.text.isEmpty
    }
}

// MARK: - UITextViewDelegate

extension InvitePersonViewController: UITextViewDelegate {
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        // This calls the segue in People.storyboard
        // that shows the SettingsMultiTextViewController.
        performSegue(withIdentifier: "message", sender: nil)
        return false
    }

}
