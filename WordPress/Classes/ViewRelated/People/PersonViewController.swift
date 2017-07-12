import Foundation
import UIKit
import CocoaLumberjack
import WordPressShared

/// Displays a Blog's User Details
///
final class PersonViewController: UITableViewController {

    /// PersonViewController operation modes
    ///
    enum ScreenMode: String {
        case User      = "user"
        case Follower  = "follower"
        case Viewer    = "viewer"

        var title: String {
            switch self {
            case .User:
                return NSLocalizedString("Blog's User", comment: "Blog's User Profile. Displayed when the name is empty!")
            case .Follower:
                return NSLocalizedString("Blog's Follower", comment: "Blog's Follower Profile. Displayed when the name is empty!")
            case .Viewer:
                return NSLocalizedString("Blog's Viewer", comment: "Blog's Viewer Profile. Displayed when the name is empty!")
            }
        }

        var name: String {
            switch self {
            case .User:
                return NSLocalizedString("user", comment: "Noun. Describes a site's user.")
            case .Follower:
                return NSLocalizedString("follower", comment: "Noun. Describes a site's follower.")
            case .Viewer:
                return NSLocalizedString("viewer", comment: "Noun. Describes a site's viewer.")
            }
        }
    }

    // MARK: - Public Properties

    /// Blog to which the Person belongs
    ///
    var blog: Blog!

    /// Core Data Context that should be used
    ///
    var context: NSManagedObjectContext!

    /// Person to be displayed
    ///
    var person: Person! {
        didSet {
            refreshInterfaceIfNeeded()
        }
    }

    /// Mode: User / Follower / Viewer
    ///
    var screenMode: ScreenMode = .User

    /// Gravatar Image
    ///
    @IBOutlet var gravatarImageView: UIImageView! {
        didSet {
            refreshGravatarImage()
        }
    }

    /// Person's Full Name
    ///
    @IBOutlet var fullNameLabel: UILabel! {
        didSet {
            setupFullNameLabel()
            refreshFullNameLabel()
        }
    }

    /// Person's User Name
    ///
    @IBOutlet var usernameLabel: UILabel! {
        didSet {
            setupUsernameLabel()
            refreshUsernameLabel()
        }
    }

    /// Person's Role
    ///
    @IBOutlet var roleCell: UITableViewCell! {
        didSet {
            setupRoleCell()
            refreshRoleCell()
        }
    }

    /// Person's First Name
    ///
    @IBOutlet var firstNameCell: UITableViewCell! {
        didSet {
            setupFirstNameCell()
            refreshFirstNameCell()
        }
    }

    /// Person's Last Name
    ///
    @IBOutlet var lastNameCell: UITableViewCell! {
        didSet {
            setupLastNameCell()
            refreshLastNameCell()
        }
    }

    /// Person's Display Name
    ///
    @IBOutlet var displayNameCell: UITableViewCell! {
        didSet {
            setupDisplayNameCell()
            refreshDisplayNameCell()
        }
    }

    /// Nuking the User
    ///
    @IBOutlet var removeCell: UITableViewCell! {
        didSet {
            setupRemoveCell()
            refreshRemoveCell()
        }
    }


    // MARK: - View Lifecyle Methods

    override func viewDidLoad() {
        assert(person != nil)
        assert(blog != nil)

        super.viewDidLoad()

        title = person.fullName.nonEmptyString() ?? screenMode.title
        WPStyleGuide.configureColors(for: view, andTableView: tableView)
        WPStyleGuide.configureAutomaticHeightRows(for: tableView)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        WPAnalytics.track(.openedPerson)
    }

    // MARK: - UITableView Methods

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectSelectedRowWithAnimation(true)

        guard let cell = tableView.cellForRow(at: indexPath) else {
            return
        }

        switch cell {
        case roleCell:
            roleWasPressed()
        case removeCell:
            removeWasPressed()
        default:
            break
        }
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
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
        if isFullnamePrivate == true && fullnameSection == indexPath.section && fullnameRows.contains(indexPath.row) {
            return CGFloat.leastNormalMagnitude
        }
        return super.tableView(tableView, heightForRowAt: indexPath)
    }



    // MARK: - Storyboard Methods

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let roleViewController = segue.destination as? RoleViewController else {
            return
        }

        roleViewController.mode = .dynamic(blog: blog)
        roleViewController.selectedRole = person.role
        roleViewController.onChange = { [weak self] newRole in
            self?.updateUserRole(newRole)
        }
    }



    // MARK: - Constants
    fileprivate let roleSegueIdentifier = "editRole"
    fileprivate let gravatarPlaceholderImage = UIImage(named: "gravatar.png")
    fileprivate let fullnameSection = 1
    fileprivate let fullnameRows = [1, 2]
}



// MARK: - Private Helpers: Actions
//
private extension PersonViewController {

    func roleWasPressed() {
        performSegue(withIdentifier: roleSegueIdentifier, sender: nil)
    }

    func removeWasPressed() {
        let titleFormat = NSLocalizedString("Remove @%@", comment: "Remove Person Alert Title")
        let titleText = String(format: titleFormat, person.username)

        let name = person.firstName?.nonEmptyString() ?? person.username

        var messageFirstLine: String
        switch screenMode {
        case .User:
            messageFirstLine = NSLocalizedString( "If you remove " + name + ", that user will no longer be able to access this site, " +
                                                  "but any content that was created by " + name + " will remain on the site.",
                                                  comment: "First line of remove user warning")
        case .Follower:
            messageFirstLine = NSLocalizedString( "If removed, this follower will stop receiving notifications about this site, unless they re-follow.",
                                                  comment: "First line of remove follower warning")
        case .Viewer:
            messageFirstLine = NSLocalizedString( "If you remove this viewer, he or she will not be able to visit this site.",
                                                  comment: "First line of remove viewer warning")
        }

        let messageSecondLineFormat = NSLocalizedString("Would you still like to remove this %@?", comment: "Second line of Remove user/follower/viewer confirmation. ")
        let messageSecondLineText = String(format: messageSecondLineFormat, screenMode.name)

        let message = messageFirstLine + "\n\n" + messageSecondLineText

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
            }
        }

        alert.presentFromRootViewController()
    }

    func deleteUser() {
        guard let user = user else {
            DDLogError("Error: Only Users can be deleted here")
            assertionFailure()
            return
        }

        let service = PeopleService(blog: blog, context: context)
        service?.deleteUser(user, success: {
            WPAnalytics.track(.personRemoved)
        }, failure: {[weak self] (error: Error?) -> () in
            guard let strongSelf = self, let error = error as NSError? else {
                return
            }
            guard let personWithError = strongSelf.person else {
                return
            }

            strongSelf.handleRemoveUserError(error, userName: "@" + personWithError.username)
        })
        _ = navigationController?.popViewController(animated: true)
    }

    func deleteFollower() {
        guard let follower = follower, isFollower else {
            DDLogError("Error: Only Followers can be deleted here")
            assertionFailure()
            return
        }

        let service = PeopleService(blog: blog, context: context)
        service?.deleteFollower(follower, failure: {[weak self] (error: Error?) -> () in
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

        let service = PeopleService(blog: blog, context: context)
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

    func updateUserRole(_ newRole: Role) {
        guard let user = user else {
            DDLogError("Error: Only Users have Roles!")
            assertionFailure()
            return
        }

        guard let service = PeopleService(blog: blog, context: context) else {
            DDLogError("Couldn't instantiate People Service")
            return
        }

        let updated = service.updateUser(user, role: newRole) { (error, reloadedPerson) in
            self.person = reloadedPerson
            self.retryUpdatingRole(newRole)
        }

        // Optimistically refresh the UI
        self.person = updated

        WPAnalytics.track(.personUpdated)
    }

    func retryUpdatingRole(_ newRole: Role) {
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



// MARK: - Private Helpers: Initializing Interface
//
private extension PersonViewController {

    func setupFullNameLabel() {
        fullNameLabel.font = WPStyleGuide.tableviewTextFont()
        fullNameLabel.textColor = WPStyleGuide.darkGrey()
    }

    func setupUsernameLabel() {
        usernameLabel.font = WPStyleGuide.tableviewSectionHeaderFont()
        usernameLabel.textColor = WPStyleGuide.wordPressBlue()
    }

    func setupFirstNameCell() {
        firstNameCell.textLabel?.text = NSLocalizedString("First Name", comment: "User's First Name")
        WPStyleGuide.configureTableViewCell(firstNameCell)
    }

    func setupLastNameCell() {
        lastNameCell.textLabel?.text = NSLocalizedString("Last Name", comment: "User's Last Name")
        WPStyleGuide.configureTableViewCell(lastNameCell)
    }

    func setupDisplayNameCell() {
        displayNameCell.textLabel?.text = NSLocalizedString("Display Name", comment: "User's Display Name")
        WPStyleGuide.configureTableViewCell(displayNameCell)
    }

    func setupRoleCell() {
        roleCell.textLabel?.text = NSLocalizedString("Role", comment: "User's Role")
        WPStyleGuide.configureTableViewCell(roleCell)
    }

    func setupRemoveCell() {
        let removeFormat = NSLocalizedString("Remove @%@", comment: "Remove User. Verb")
        let removeText = String(format: removeFormat, person.username)
        removeCell.textLabel?.text = removeText as String
        WPStyleGuide.configureTableViewDestructiveActionCell(removeCell)
    }
}



// MARK: - Private Helpers: Refreshing Interface
//
private extension PersonViewController {

    func refreshInterfaceIfNeeded() {
        guard isViewLoaded else {
            return
        }

        refreshGravatarImage()
        refreshFullNameLabel()
        refreshUsernameLabel()
        refreshRoleCell()
        refreshFirstNameCell()
        refreshLastNameCell()
        refreshDisplayNameCell()
        refreshRemoveCell()
    }

    func refreshGravatarImage() {
        let gravatar = person.avatarURL.flatMap { Gravatar($0) }
        let placeholder = UIImage(named: "gravatar")!
        gravatarImageView.downloadGravatar(gravatar, placeholder: placeholder, animate: false)
    }

    func refreshFullNameLabel() {
        fullNameLabel.text = person.fullName
    }

    func refreshUsernameLabel() {
        usernameLabel.text = "@" + person.username
    }

    func refreshFirstNameCell() {
        firstNameCell.detailTextLabel?.text = person.firstName
        firstNameCell.isHidden = isFullnamePrivate
    }

    func refreshLastNameCell() {
        lastNameCell.detailTextLabel?.text = person.lastName
        lastNameCell.isHidden = isFullnamePrivate
    }

    func refreshDisplayNameCell() {
        displayNameCell.detailTextLabel?.text = person.displayName
    }

    func refreshRoleCell() {
        let enabled = isPromoteEnabled
        roleCell.detailTextLabel?.text = person.role.localizedName
        roleCell.accessoryType = enabled ? .disclosureIndicator : .none
        roleCell.selectionStyle = enabled ? .gray : .none
        roleCell.isUserInteractionEnabled = enabled
        roleCell.detailTextLabel?.text = person.role.localizedName
    }

    func refreshRemoveCell() {
        removeCell.isHidden = !isRemoveEnabled
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

    var isViewer: Bool {
        return viewer != nil
    }

    var viewer: Viewer? {
        return person as? Viewer
    }
}
