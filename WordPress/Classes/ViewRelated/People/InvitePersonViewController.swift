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

    private lazy var inviteActivityView: UIActivityIndicatorView = {
        let activityView = UIActivityIndicatorView(style: .medium)
        activityView.startAnimating()
        return activityView
    }()

    private var updatingInviteLinks = false {
        didSet {
            guard updatingInviteLinks != oldValue else {
                return
            }

            if updatingInviteLinks == false {
                generateShareCell.accessoryView = nil
                disableLinksCell.accessoryView = nil
                return
            }

            if blog.inviteLinks?.count == 0 {
                generateShareCell.accessoryView = inviteActivityView
            } else {
                disableLinksCell.accessoryView = inviteActivityView
            }
        }
    }

    private var sortedInviteLinks: [InviteLinks] {
        guard
            let links = blog.inviteLinks?.array as? [InviteLinks]
        else {
            return []
        }
        return availableRoles.compactMap { role -> InviteLinks? in
            return links.first { link -> Bool in
                link.role == role.slug
            }
        }
    }

    private var selectedInviteLinkIndex = 0 {
        didSet {
            tableView.reloadData()
        }
    }

    private var currentInviteLink: InviteLinks? {
        let links = sortedInviteLinks
        guard links.count > 0 && selectedInviteLinkIndex < links.count else {
            return nil
        }
        return links[selectedInviteLinkIndex]
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

    @IBOutlet private var generateShareCell: UITableViewCell! {
        didSet {
            refreshGenerateShareCell()
        }
    }

    @IBOutlet private var currentInviteCell: UITableViewCell! {
        didSet {
            refreshCurrentInviteCell()
        }
    }

    @IBOutlet private var expirationCell: UITableViewCell! {
        didSet {
            refreshExpirationCell()
        }
    }

    @IBOutlet private var disableLinksCell: UITableViewCell! {
        didSet {
            refreshDisableLinkCell()
        }
    }

    // MARK: - View Lifecyle Methods

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupDefaultRole()
        WPStyleGuide.configureColors(view: view, tableView: tableView)
        WPStyleGuide.configureAutomaticHeightRows(for: tableView)
        // Use the system separator color rather than the one defined by WPStyleGuide
        // so cell separators stand out in darkmode.
        tableView.separatorColor = .separator
        if blog.isWPForTeams() {
            syncInviteLinks()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.deselectSelectedRowWithAnimation(true)
    }


    // MARK: - UITableView Methods

    override func numberOfSections(in tableView: UITableView) -> Int {
        // Hide the last section if the site is not a p2.
        let count = super.numberOfSections(in: tableView)
        return blog.isWPForTeams() ? count : count - 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard
            blog.isWPForTeams(),
            section == numberOfSections(in: tableView) - 1
        else {
            // If not a P2 or not the last section, just call super.
            return super.tableView(tableView, numberOfRowsInSection: section)
        }
        // One cell for no cached inviteLinks. Otherwise 4.
        return blog.inviteLinks?.count == 0 ? 1 : 4
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard Section.inviteLink == Section(rawValue: section) else {
            return nil
        }
        return NSLocalizedString("Invite Link", comment: "Title for the Invite Link section of the Invite Person screen.")
    }

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
        switch Section(rawValue: indexPath.section) {
        case .username:
            refreshUsernameCell()
        case .role:
            setupRoleCell()
            refreshRoleCell()
        case .message:
            refreshMessageTextView()
        case .inviteLink:
            refreshInviteLinkCell(indexPath: indexPath)
        case .none:
            break
        }

        return super.tableView(tableView, cellForRowAt: indexPath)
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.section == Section.inviteLink.rawValue else {
            // There is no valid `super` implementation so do not call it.
            return
        }
        tableView.deselectRow(at: indexPath, animated: true)
        handleInviteLinkRowTapped(indexPath: indexPath)
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
        case .InviteRole:
            setupInviteRoleSegue(segue)
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

    private func setupInviteRoleSegue(_ segue: UIStoryboardSegue) {
        guard let roleViewController = segue.destination as? RoleViewController else {
            return
        }

        roleViewController.roles = availableRoles
        roleViewController.selectedRole = currentInviteLink?.role
        roleViewController.onChange = { [unowned self] newRole in
            self.selectedInviteLinkIndex = self.availableRoles.firstIndex(where: { $0.slug == newRole }) ?? 0
        }
    }


    // MARK: - Private Enums

    private enum SegueIdentifier: String {
        case Username   = "username"
        case Role       = "role"
        case Message    = "message"
        case InviteRole = "inviteRole"
    }

    // The case order matches the custom sections order in People.storyboard.
    private enum Section: Int {
        case username
        case role
        case message
        case inviteLink

        var footerText: String? {
            switch self {
            case .role:
                return NSLocalizedString("Learn more about roles", comment: "Footer text for Invite People role field.")
            case .message:
                // messageCharacterLimit cannot be accessed here, so the caller will insert it in the string.
                return NSLocalizedString("Optional: Enter a custom message up to %1$d characters to be sent with your invitation.", comment: "Footer text for Invite People message field. %1$d is the maximum number of characters allowed.")
            case .inviteLink:
                return NSLocalizedString("Use this link to onboard your team members without having to invite them one by one. Anybody visiting this URL will be able to sign up to your organization, even if they received the link from somebody else, so make sure that you share it with trusted people.", comment: "Footer text for Invite Links section of the Invite People screen.")
            default:
                return nil
            }
        }
    }

    // These represent the rows of the invite links section, in the order the rows appear.
    private enum InviteLinkRow: Int {
        case generateShare
        case role
        case expires
        case disable
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

            WPAnalytics.track(.peopleUserInvited, properties: ["role": role], blog: blog)
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
        guard let footer = footerView as? UITableViewHeaderFooterView else {
            return
        }
        guard Section(rawValue: section) == .role else {
            footer.textLabel?.isUserInteractionEnabled = false
            footer.accessibilityTraits = .staticText
            footer.gestureRecognizers?.removeAll()
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

        let webViewController = WebViewControllerFactory.controller(url: url, source: "invite_person_role_learn_more")
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

// MARK: - Invite Links related.
//
private extension InvitePersonViewController {

    func refreshInviteLinkCell(indexPath: IndexPath) {
        guard let row = InviteLinkRow(rawValue: indexPath.row) else {
            return
        }
        switch row {
        case .generateShare:
            refreshGenerateShareCell()
        case .role:
            refreshCurrentInviteCell()
        case .expires:
            refreshExpirationCell()
        case .disable:
            refreshDisableLinkCell()
        }
    }

    func refreshGenerateShareCell() {
        if blog.inviteLinks?.count == 0 {
            generateShareCell.textLabel?.text = NSLocalizedString("Generate new link", comment: "Title. A call to action to generate a new invite link.")
            generateShareCell.textLabel?.font = WPStyleGuide.tableviewTextFont()
        } else {
            generateShareCell.textLabel?.attributedText = createAttributedShareInviteText()
        }
        generateShareCell.textLabel?.font = WPStyleGuide.tableviewTextFont()
        generateShareCell.textLabel?.textAlignment = .center
        generateShareCell.textLabel?.textColor = .primary
    }

    func createAttributedShareInviteText() -> NSAttributedString {
        let pStyle = NSMutableParagraphStyle()
        pStyle.alignment = .center
        let font = WPStyleGuide.tableviewTextFont()
        let textAttributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .paragraphStyle: pStyle
        ]

        let image = UIImage.gridicon(.shareiOS)
        let attachment = NSTextAttachment(image: image)
        attachment.bounds = CGRect(x: 0,
                                   y: (font.capHeight - image.size.height)/2,
                                   width: image.size.width,
                                   height: image.size.height)
        let textStr = NSAttributedString(string: NSLocalizedString("Share invite link", comment: "Title. A call to action to share an invite link."), attributes: textAttributes)
        let attrStr = NSMutableAttributedString(attachment: attachment)
        attrStr.append(NSAttributedString(string: " "))
        attrStr.append(textStr)
        return attrStr
    }

    func refreshCurrentInviteCell() {
        guard selectedInviteLinkIndex < availableRoles.count else {
            return
        }

        currentInviteCell.textLabel?.text = NSLocalizedString("Role", comment: "Title. Indicates the user role an invite link is for.")
        currentInviteCell.textLabel?.textColor = .text

        // sortedInviteLinks and availableRoles should be complimentary. We can cheat a little and
        // get the localized "display name" to use from availableRoles rather than
        // trying to capitalize the role slug from the current invite link.
        let role = availableRoles[selectedInviteLinkIndex]
        currentInviteCell.detailTextLabel?.text = role.name

        WPStyleGuide.configureTableViewCell(currentInviteCell)
    }

    func refreshExpirationCell() {
        guard
            let invite = currentInviteLink,
            invite.expiry > 0
        else {
            return
        }

        expirationCell.textLabel?.text = NSLocalizedString("Expires on", comment: "Title. Indicates an expiration date.")
        expirationCell.textLabel?.textColor = .text

        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        let date = Date(timeIntervalSince1970: Double(invite.expiry))
        expirationCell.detailTextLabel?.text = formatter.string(from: date)

        WPStyleGuide.configureTableViewCell(expirationCell)
    }

    func refreshDisableLinkCell() {
        disableLinksCell.textLabel?.text = NSLocalizedString("Disable invite link", comment: "Title. A call to action to disable invite links.")
        disableLinksCell.textLabel?.font = WPStyleGuide.tableviewTextFont()
        disableLinksCell.textLabel?.textColor = .error
        disableLinksCell.textLabel?.textAlignment = .center
    }

    func syncInviteLinks() {
        guard let siteID = blog.dotComID?.intValue else {
            return
        }
        let service = PeopleService(blog: blog, context: context)
        service?.fetchInviteLinks(siteID, success: { [weak self] _ in
            self?.bumpStat(event: .inviteLinksGetStatus, error: nil)
            self?.updatingInviteLinks = false
            self?.tableView.reloadData()
        }, failure: { [weak self] error in
            // Fail silently.
            self?.bumpStat(event: .inviteLinksGetStatus, error: error)
            self?.updatingInviteLinks = false
            DDLogError("Error syncing invite links. \(error)")
        })
    }

    func generateInviteLinks() {
        guard
            updatingInviteLinks == false,
            let siteID = blog.dotComID?.intValue
        else {
            return
        }
        updatingInviteLinks = true
        let service = PeopleService(blog: blog, context: context)
        service?.generateInviteLinks(siteID, success: { [weak self] _ in
            self?.bumpStat(event: .inviteLinksGenerate, error: nil)
            self?.updatingInviteLinks = false
            self?.tableView.reloadData()
        }, failure: { [weak self] error in
            self?.bumpStat(event: .inviteLinksGenerate, error: error)
            self?.updatingInviteLinks = false
            self?.displayNotice(title: NSLocalizedString("Unable to create new invite links.", comment: "An error message shown when there is an issue creating new invite links."))
            DDLogError("Error generating invite links. \(error)")
        })
    }

    func shareInviteLink() {
        guard
            let link = currentInviteLink?.link,
            let url = URL(string: link) as NSURL?
        else {
            return
        }

        let controller = PostSharingController()
        controller.shareURL(url: url, fromRect: generateShareCell.frame, inView: view, inViewController: self)
        bumpStat(event: .inviteLinksShare, error: nil)
    }

    func handleDisableTapped() {
        guard updatingInviteLinks == false else {
            return
        }

        let title = NSLocalizedString("Disable invite link", comment: "Title. Title of a prompt to disable group invite links.")
        let message = NSLocalizedString("Once this invite link is disabled, nobody will be able to use it to join your team. Are you sure?", comment: "Warning message about disabling group invite links.")
        let controller = UIAlertController(title: title, message: message, preferredStyle: .alert)
        controller.addCancelActionWithTitle(NSLocalizedString("Cancel", comment: "Title. Title of a cancel button. Tapping disnisses an alert."))
        let action = UIAlertAction(title: NSLocalizedString("Disable", comment: "Title. Title of a button that will disable group invite links when tapped."),
                                   style: .destructive) { [weak self] _ in
            self?.disableInviteLinks()
        }
        controller.addAction(action)
        controller.preferredAction = action
        present(controller, animated: true, completion: nil)
    }

    func disableInviteLinks() {
        guard let siteID = blog.dotComID?.intValue else {
            return
        }
        updatingInviteLinks = true
        let service = PeopleService(blog: blog, context: context)
        service?.disableInviteLinks(siteID, success: { [weak self] in
            self?.bumpStat(event: .inviteLinksDisable, error: nil)
            self?.updatingInviteLinks = false
            self?.tableView.reloadData()
        }, failure: { [weak self] error in
            self?.bumpStat(event: .inviteLinksDisable, error: error)
            self?.updatingInviteLinks = false
            self?.displayNotice(title: NSLocalizedString("Unable to disable invite links.", comment: "An error message shown when there is an issue creating new invite links."))
            DDLogError("Error disabling invite links. \(error)")
        })
    }

    func handleInviteLinkRowTapped(indexPath: IndexPath) {
        guard let row = InviteLinkRow(rawValue: indexPath.row) else {
            return
        }
        switch row {
        case .generateShare:
            if blog.inviteLinks?.count == 0 {
                generateInviteLinks()
            } else {
                shareInviteLink()
            }
        case .disable:
            handleDisableTapped()
        default:
            // .role is handled by a segue.
            // .expires is a no op
            break
        }
    }

    func bumpStat(event: WPAnalyticsEvent, error: Error?) {
        let resultKey = "invite_links_action_result"
        let errorKey = "invite_links_action_error_message"
        var props = [AnyHashable: Any]()
        if let err = error {
            props = [
                resultKey: "error",
                errorKey: "\(err)"
            ]
        } else {
            props = [
                resultKey: "success"
            ]
        }
        WPAnalytics.track(event, properties: props, blog: blog)
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
