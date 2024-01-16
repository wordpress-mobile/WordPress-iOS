import Foundation
import UIKit
import CocoaLumberjack
import WordPressShared

/// Displays a Blog's User Details
///
final class PersonViewController: UITableViewController {

    /// The sections of the table
    ///
    private enum TableSection: Int {
        case header
        case userDetails
        case action
    }

    /// PersonViewController operation modes
    ///
    enum ScreenMode: String {
        case User      = "user"
        case Follower  = "follower"
        case Viewer    = "viewer"
        case Email     = "email"

        var title: String {
            switch self {
            case .User:
                return NSLocalizedString("Blog's User", comment: "Blog's User Profile. Displayed when the name is empty!")
            case .Follower:
                return NSLocalizedString("Blog's Follower", comment: "Blog's Follower Profile. Displayed when the name is empty!")
            case .Viewer:
                return NSLocalizedString("Blog's Viewer", comment: "Blog's Viewer Profile. Displayed when the name is empty!")
            case .Email:
                return NSLocalizedString("Blog's Email Follower", comment: "Blog's Email Follower Profile. Displayed when the name is empty!")
            }
        }
    }


    /// Blog to which the Person belongs
    ///
    private let blog: Blog

    /// Core Data Context that should be used
    ///
    private let context: NSManagedObjectContext

    /// Person to be displayed
    ///
    private var person: Person {
        didSet {
            refreshInterfaceIfNeeded()
        }
    }

    /// Mode: User / Follower / Viewer / Email Follower
    ///
    private let screenMode: ScreenMode

    private let service: PeopleService?

    // MARK: - Initializers

    init?(coder: NSCoder, blog: Blog, context: NSManagedObjectContext, person: Person, screenMode: ScreenMode) {
        self.blog = blog
        self.context = context
        self.person = person
        self.screenMode = screenMode
        self.service = PeopleService(blog: blog, coreDataStack: ContextManager.shared)

        super.init(coder: coder)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Lifecyle Methods

    override func viewDidLoad() {
        super.viewDidLoad()

        title = person.fullName.nonEmptyString() ?? screenMode.title
        WPStyleGuide.configureColors(view: view, tableView: tableView)
        WPStyleGuide.configureAutomaticHeightRows(for: tableView)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        WPAnalytics.track(.openedPerson)
    }

    // MARK: - UITableView Methods

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectSelectedRowWithAnimation(true)

        switch indexPath {
        case roleIndexPath:
            roleWasPressed()
        case removeIndexPath:
            removeWasPressed()
        default:
            break
        }
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel[section].count
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return sectionHeaderHeight
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if shouldHideCell(at: indexPath) {
            return CGFloat.leastNormalMagnitude
        }
        return UITableView.automaticDimension
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        guard let section = TableSection(rawValue: indexPath.section) else {
            assertionFailure("Unhandled table section")
            return UITableViewCell()
        }

        let cell: UITableViewCell
        switch section {
        case .header:
            cell = tableView.dequeueReusableCell(withIdentifier: PersonHeaderCell.identifier, for: indexPath)
            configureHeaderCell(cell)
        case .userDetails:
            cell = dequeueCell(withIdentifier: userInfoCellIdentifier, style: .value1)
            configureUserCells(cell, at: indexPath.row)
        case .action:
            cell = dequeueCell(withIdentifier: actionCellIdentifier, style: .default)
            configureRemoveCell(cell)
        }
        return cell
    }

    // MARK: - Storyboard Methods

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let roleViewController = segue.destination as? RoleViewController else {
            return
        }

        roleViewController.roles = blog.sortedRoles?.map({ $0.toUnmanaged() }) ?? []
        roleViewController.selectedRole = person.role
        roleViewController.onChange = { [weak self] newRole in
            self?.updateUserRole(newRole)
        }
    }



    // MARK: - Constants
    private let sectionHeaderHeight      = CGFloat(20)
    private let roleSegueIdentifier      = "editRole"
    private let userInfoCellIdentifier   = "userInfoCellIdentifier"
    private let actionCellIdentifier     = "actionCellIdentifier"

    private let headerIndexPath      = IndexPath(row: 0, section: TableSection.header.rawValue)
    private let roleIndexPath        = IndexPath(row: 0, section: TableSection.userDetails.rawValue)
    private let firstNameIndexPath   = IndexPath(row: 1, section: TableSection.userDetails.rawValue)
    private let lastNameIndexPath    = IndexPath(row: 2, section: TableSection.userDetails.rawValue)
    private let displayNameIndexPath = IndexPath(row: 3, section: TableSection.userDetails.rawValue)
    private let removeIndexPath      = IndexPath(row: 0, section: TableSection.action.rawValue)

    /// The structure in sections and cells of the table
    ///
    private lazy var viewModel: [[IndexPath]] = {
        var model = [[IndexPath]]()
        model.append([
            headerIndexPath
        ])
        model.append([
            roleIndexPath,
            firstNameIndexPath,
            lastNameIndexPath,
            displayNameIndexPath
        ])

        if isRemoveEnabled {
            model.append([
                removeIndexPath
            ])
        }
        return model
    }()
}



// MARK: - Private Helpers: Actions
//
private extension PersonViewController {
    func roleWasPressed() {
        performSegue(withIdentifier: roleSegueIdentifier, sender: nil)
    }

    func removeWasPressed() {
        let titleFormat = NSLocalizedString("Remove %@", comment: "Remove Person Alert Title")
        let titleText = String(format: titleFormat, isEmailFollower ? person.displayName : "@" + person.username)
        let name = person.firstName?.nonEmptyString() ?? (isEmailFollower ? person.displayName : person.username)
        let message = warningTextForRemovingPerson(name)
        let cancelTitle = NSLocalizedString("Cancel", comment: "Cancel Action")
        let removeTitle = NSLocalizedString("Remove", comment: "Remove Action")

        let alert = UIAlertController(title: titleText, message: message, preferredStyle: .alert)

        alert.addCancelActionWithTitle(cancelTitle)

        alert.addDestructiveActionWithTitle(removeTitle) { [weak self] action in
            guard let strongSelf = self else {
                return
            }

            switch strongSelf.screenMode {
            case .User:
                strongSelf.deleteUser()
            case .Follower:
                strongSelf.deleteFollower()
            case .Viewer:
                strongSelf.deleteViewer()
                return
            case .Email:
                strongSelf.deleteEmailFollower()
            }
        }

        alert.presentFromRootViewController()
    }

    func warningTextForRemovingPerson(_ name: String) -> String {
        var messageFirstLine: String
        switch screenMode {
        case .User:
            let text = NSLocalizedString("If you remove %@, that user will no longer be able to access this site, but any content that was created by %@ will remain on the site.",
                                         comment: "First line of remove user warning in confirmation dialog. Note: '%@' is the placeholder for the user's name and it must exist twice in this string.")
            messageFirstLine = String.localizedStringWithFormat(text, name, name)
        case .Follower:
            messageFirstLine = NSLocalizedString("Removing followers makes them stop receiving updates from your site. If they choose to, they can still visit your site, and follow it again.",
                                                 comment: "First line of remove follower warning in confirmation dialog.")
        case .Viewer:
            messageFirstLine = NSLocalizedString("If you remove this viewer, he or she will not be able to visit this site.",
                                                 comment: "First line of remove viewer warning in confirmation dialog.")
        case .Email:
            messageFirstLine = NSLocalizedString("Removing followers makes them stop receiving updates from your site. If they choose to, they can still visit your site, and follow it again.",
                                                 comment: "First line of remove email follower warning in confirmation dialog.")
        }

        let messageSecondLineText = NSLocalizedString("Would you still like to remove this person?",
                                                      comment: "Second line of Remove user/follower/viewer warning in confirmation dialog.")

        return messageFirstLine + "\n\n" + messageSecondLineText
    }

    func deleteUser() {
        guard let user = user else {
            DDLogError("Error: Only Users can be deleted here")
            assertionFailure()
            return
        }

        service?.deleteUser(user, success: {
            WPAnalytics.track(.personRemoved)
        }, failure: {[weak self] (error: Error?) -> () in
            guard let strongSelf = self, let error = error as NSError? else {
                return
            }

            strongSelf.handleRemoveUserError(error, userName: "@" + strongSelf.person.username)
        })
        _ = navigationController?.popViewController(animated: true)
    }

    func deleteFollower() {
        guard let follower = follower, isFollower else {
            DDLogError("Error: Only Followers can be deleted here")
            assertionFailure()
            return
        }

        service?.deleteFollower(follower, failure: {[weak self] (error: Error?) -> () in
            guard let strongSelf = self, let error = error as NSError? else {
                return
            }

            strongSelf.handleRemoveViewerOrFollowerError(error)
        })
        _ = navigationController?.popViewController(animated: true)
    }

    func deleteEmailFollower() {
        guard let emailFollower = emailFollower, isEmailFollower else {
            DDLogError("Error: Only email followers can be deleted here")
            assertionFailure()
            return
        }

        service?.deleteEmailFollower(emailFollower, failure: { [weak self] error in
            guard let strongSelf = self, let error = error as NSError? else {
                return
            }

            strongSelf.handleRemoveViewerOrFollowerError(error)
        })
        _ = navigationController?.popViewController(animated: true)
    }

    func deleteViewer() {
        guard let viewer = viewer, isViewer else {
            DDLogError("Error: Only Viewers can be deleted here")
            assertionFailure()
            return
        }

        service?.deleteViewer(viewer, success: {
            WPAnalytics.track(.personRemoved)
        }, failure: {[weak self] (error: Error?) -> () in
            guard let strongSelf = self, let error = error as NSError? else {
                return
            }

            strongSelf.handleRemoveViewerOrFollowerError(error)
        })
        _ = navigationController?.popViewController(animated: true)
    }

    func handleRemoveUserError(_ error: NSError, userName: String) {
        // The error code will be "forbidden" per:
        // https://developer.wordpress.com/docs/api/1.1/post/sites/%24site/users/%24user_ID/delete/
        guard let errorCode = error.userInfo[WordPressComRestApi.ErrorKeyErrorCode] as? String,
            errorCode.localizedCaseInsensitiveContains("forbidden") else {
            let errorWithSource = NSError(domain: error.domain, code: error.code, userInfo: error.userInfo)
            WPError.showNetworkingAlertWithError(errorWithSource)
            return
        }

        let errorTitleFormat = NSLocalizedString("Error removing %@", comment: "Title of error dialog when removing a site owner fails.")
        let errorTitleText = String(format: errorTitleFormat, userName)
        let errorMessage = NSLocalizedString("The user you are trying to remove is the owner of this site. " +
                                             "Please contact support for assistance.",
                                             comment: "Error message shown when user attempts to remove the site owner.")
        WPError.showAlert(withTitle: errorTitleText, message: errorMessage, withSupportButton: true)
    }

    func handleRemoveViewerOrFollowerError(_ error: NSError) {
        let errorWithSource = NSError(domain: error.domain, code: error.code, userInfo: error.userInfo)
        WPError.showNetworkingAlertWithError(errorWithSource)
    }

    func updateUserRole(_ newRole: String) {
        guard let user = user else {
            DDLogError("Error: Only Users have Roles!")
            assertionFailure()
            return
        }

        guard let service = service else {
            DDLogError("Couldn't instantiate People Service")
            return
        }

        service.updateUser(user, role: newRole) { updated in
            self.person = updated
            WPAnalytics.track(.personUpdated)
        } failure: { [weak self] _, reloadedPerson in
            self?.person = reloadedPerson
            self?.retryUpdatingRole(newRole)
        }
    }

    func retryUpdatingRole(_ newRole: String) {
        let retryTitle          = NSLocalizedString("Retry", comment: "Retry updating User's Role")
        let cancelTitle         = NSLocalizedString("Cancel", comment: "Cancel updating User's Role")
        let title               = NSLocalizedString("Sorry!", comment: "Update User Failed Title")
        let localizedError      = NSLocalizedString("There was an error updating @%@", comment: "Updating Role failed error message")
        let messageText         = String(format: localizedError, person.username)

        let alertController = UIAlertController(title: title, message: messageText, preferredStyle: .alert)

        alertController.addCancelActionWithTitle(cancelTitle, handler: nil)
        alertController.addDefaultActionWithTitle(retryTitle) { action in
            self.updateUserRole(newRole)
        }

        alertController.presentFromRootViewController()
    }
}



// MARK: - Private Helpers: Configuring table cells
//
private extension PersonViewController {

    func dequeueCell(withIdentifier identifier: String, style: UITableViewCell.CellStyle) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: identifier) {
            return cell
        } else {
            return WPTableViewCell(style: style, reuseIdentifier: identifier)
        }
    }

    func configureHeaderCell(_ cell: UITableViewCell) {
        guard let headerCell = cell as? PersonHeaderCell else {
            assertionFailure("Cell should be of class PersonHeaderCell, but it is \(type(of: cell))")
            return
        }
        headerCell.fullNameLabel.font = WPStyleGuide.tableviewTextFont()
        headerCell.fullNameLabel.textColor = .text
        headerCell.fullNameLabel.text = isEmailFollower ? person.displayName : person.fullName

        headerCell.userNameLabel.font = WPStyleGuide.tableviewSectionHeaderFont()
        headerCell.userNameLabel.textColor = .primary
        headerCell.userNameLabel.text = person.username.count > 0 ? "@" + person.username : ""

        refreshGravatarImage(in: headerCell.gravatarImageView)
    }

    func configureUserCells(_ cell: UITableViewCell, at index: Int) {
        WPStyleGuide.configureTableViewCell(cell)

        switch index {
        case roleIndexPath.row:
            configureRoleCell(cell)
        case firstNameIndexPath.row:
            configureFirstNameCell(cell)
        case lastNameIndexPath.row:
            configureLastNameCell(cell)
        case displayNameIndexPath.row:
            configureDisplayNameCell(cell)
        default:
            break
        }
    }

    func configureRemoveCell(_ cell: UITableViewCell) {
        WPStyleGuide.configureTableViewDestructiveActionCell(cell)
        let removeFormat     = NSLocalizedString("Remove %@", comment: "Remove User. Verb")
        let removeText       = String(format: removeFormat, isEmailFollower ? person.displayName : "@" + person.username)
        cell.textLabel?.text = removeText as String
        cell.isHidden        = !isRemoveEnabled
    }

    func configureFirstNameCell(_ cell: UITableViewCell) {
        cell.textLabel?.text       = NSLocalizedString("First Name", comment: "User's First Name")
        cell.detailTextLabel?.text = person.firstName
        cell.isHidden              = isFullnamePrivate
        cell.isUserInteractionEnabled = false
    }

    func configureLastNameCell(_ cell: UITableViewCell) {
        cell.textLabel?.text       = NSLocalizedString("Last Name", comment: "User's Last Name")
        cell.detailTextLabel?.text = person.lastName
        cell.isHidden              = isFullnamePrivate
        cell.isUserInteractionEnabled = false
    }

    func configureDisplayNameCell(_ cell: UITableViewCell) {
        cell.textLabel?.text       = NSLocalizedString("Display Name", comment: "User's Display Name")
        cell.detailTextLabel?.text = person.displayName
        cell.isUserInteractionEnabled = false
    }

    func configureRoleCell(_ cell: UITableViewCell) {
        cell.textLabel?.text          = NSLocalizedString("Role", comment: "User's Role")
        cell.detailTextLabel?.text    = role?.name

        let enabled                   = isPromoteEnabled
        cell.accessoryType            = enabled ? .disclosureIndicator : .none
        cell.selectionStyle           = enabled ? .gray : .none
        cell.isUserInteractionEnabled = enabled
    }

    /// Returns true if the cell at the given index path should be hidden from the table
    ///
    func shouldHideCell(at indexPath: IndexPath) -> Bool {
        // Forgive Me:
        // ===========
        // Why do we check the indexPath's values, instead of grabbing the cellForRowAtIndexPath, and check if
        // it's hidden or not?
        //
        // Because:
        // UITableView is crashing if we do so, in this method. Probably due to an internal structure
        // not being timely initialized.
        //
        //
        return isFullnamePrivate == true && (indexPath == firstNameIndexPath || indexPath == lastNameIndexPath)
    }
}



// MARK: - Private Helpers: Refreshing Interface
//
private extension PersonViewController {

    func refreshInterfaceIfNeeded() {
        guard isViewLoaded else {
            return
        }
        tableView.reloadData()
    }

    func refreshGravatarImage(in imageView: UIImageView) {
        let gravatar = person.avatarURL.flatMap { Gravatar($0) }
        let placeholder = UIImage(named: "gravatar")!
        imageView.downloadGravatar(gravatar, placeholder: placeholder, animate: false)
    }
}



// MARK: - Private Computed Properties
//
private extension PersonViewController {

    var isMyself: Bool {
        return blog.account!.userID.intValue == person.ID || blog.account!.userID.intValue == person.linkedUserID
    }

    var isFullnamePrivate: Bool {
        // Followers + Viewers shouldn't display First / Last name
        return isUser == false
    }

    var isPromoteEnabled: Bool {
        // Note: *Only* users can be promoted.
        //
        return blog.isUserCapableOf(.PromoteUsers) && isMyself == false && isUser == true
    }

    var isRemoveEnabled: Bool {
        switch screenMode {
        case .User:
            // YES, ListUsers. Brought from Calypso's code
            return blog.isUserCapableOf(.ListUsers) && isMyself == false && isUser == true
        case .Follower:
            return isFollower == true
        case .Viewer:
            return isViewer == true
        case .Email:
            return isEmailFollower
        }
    }

    var isUser: Bool {
        return user != nil
    }

    var user: User? {
        return person as? User
    }

    var isFollower: Bool {
        return follower != nil
    }

    var follower: Follower? {
        return person as? Follower
    }

    var isEmailFollower: Bool {
        return person is EmailFollower
    }

    var emailFollower: EmailFollower? {
        return person as? EmailFollower
    }

    var isViewer: Bool {
        return viewer != nil
    }

    var viewer: Viewer? {
        return person as? Viewer
    }

    var role: RemoteRole? {
        switch screenMode {
        case .Follower:
            return .follower
        case .Viewer:
            return .viewer
        case .User:
            return try? Role.lookup(withBlogID: blog.objectID, slug: person.role, in: context)?.toUnmanaged()
        case .Email:
            return .follower
        }
    }
}

// MARK: - Jetpack powered badge
extension PersonViewController {

    private static let jetpackBadgeHeight: CGFloat = 96
    private static func shouldShowJetpackBadge() -> Bool {
        JetpackBrandingVisibility.all.enabled &&
        JetpackBrandingCoordinator.shouldShowBannerForJetpackDependentFeatures()
    }
    private var lastSection: Int {
        viewModel.count - 1
    }

    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard
            section == lastSection,
            Self.shouldShowJetpackBadge()
        else {
            return nil
        }
        let textProvider = JetpackBrandingTextProvider(screen: JetpackBadgeScreen.person)
        return JetpackButton.makeBadgeView(title: textProvider.brandingText(),
                                           target: self,
                                           selector: #selector(jetpackButtonTapped))
    }

    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        guard
            section == lastSection,
            Self.shouldShowJetpackBadge()
        else {
            return UITableView.automaticDimension
        }

        return Self.jetpackBadgeHeight
    }

    @objc private func jetpackButtonTapped() {
        JetpackBrandingCoordinator.presentOverlay(from: self)
        JetpackBrandingAnalyticsHelper.trackJetpackPoweredBadgeTapped(screen: .person)
    }
}
