import Foundation
import UIKit
import WordPressShared

/// Displays a Blog's User Details
///
class PersonViewController : UITableViewController {

    // MARK: - Public Properties
    var person  : Person!
    var blog    : Blog!


    // MARK: - View Lifecyle Methods
    override func viewDidLoad() {
        assert(person != nil)
        assert(blog != nil)

        super.viewDidLoad()

        title = person.fullName.nonEmptyString() ?? NSLocalizedString("Blog's User", comment: "Blog's User Profile. Displayed when the name is empty!")
        WPStyleGuide.configureColorsForView(view, andTableView: tableView)
    }


    // MARK: - UITableView Methods
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectSelectedRowWithAnimation(true)

        guard let cell = tableView.cellForRowAtIndexPath(indexPath) else {
            return
        }

        switch cell {
        case roleCell:
            handleRoleWasPressed()
        case removeCell:
            handleRemoveWasPressed()
        default:
            break
        }
    }

    // MARK: - Storyboard Methods
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        guard let roleViewController = segue.destinationViewController as? RoleViewController else {
            return
        }

        roleViewController.role = person.role
        roleViewController.onChange = { newRole in
// TODO: JLP May.3.2016. To be implemented as part of #5175
        }
    }


    // MARK: - Action Handlers
    @IBAction func handleRoleWasPressed() {
        performSegueWithIdentifier(roleSegueIdentifier, sender: nil)
    }

    @IBAction func handleRemoveWasPressed() {
// TODO: JLP May.3.2016. To be implemented as part of #5175
    }


    // MARK: - Outlets
    @IBOutlet var gravatarImageView : UIImageView! {
        didSet {
            let placeholder = UIImage(named: "gravatar.png")
            gravatarImageView.downloadImage(person.avatarURL, placeholderImage: placeholder)
        }
    }

    @IBOutlet var fullNameLabel : UILabel! {
        didSet {
            fullNameLabel.text = person.fullName
            fullNameLabel.font = WPStyleGuide.tableviewTextFont()
            fullNameLabel.textColor = WPStyleGuide.darkGrey()
        }
    }

    @IBOutlet var usernameLabel : UILabel! {
        didSet {
            usernameLabel.text = "@" + person.username
            usernameLabel.font = WPStyleGuide.tableviewSectionHeaderFont()
            usernameLabel.textColor = WPStyleGuide.wordPressBlue()
        }
    }

    @IBOutlet var roleCell : UITableViewCell! {
        didSet {
            roleCell.textLabel?.text = NSLocalizedString("Role", comment: "User's Role")
            roleCell.detailTextLabel?.text = person?.role.description.capitalizedString
            roleCell.accessoryType = canPromote ? .DisclosureIndicator : .None
            roleCell.selectionStyle = canPromote ? .Gray : .None
            roleCell.userInteractionEnabled = canPromote
            WPStyleGuide.configureTableViewCell(roleCell)
        }
    }

    @IBOutlet var firstNameCell : UITableViewCell! {
        didSet {
            firstNameCell.textLabel?.text = NSLocalizedString("First Name", comment: "User's First Name")
            firstNameCell.detailTextLabel?.text = person.firstName
            WPStyleGuide.configureTableViewCell(firstNameCell)
        }
    }

    @IBOutlet var lastNameCell : UITableViewCell! {
        didSet {
            lastNameCell.textLabel?.text = NSLocalizedString("Last Name", comment: "User's Last Name")
            lastNameCell.detailTextLabel?.text = person.lastName
            WPStyleGuide.configureTableViewCell(lastNameCell)
        }
    }

    @IBOutlet var displayNameCell : UITableViewCell! {
        didSet {
            displayNameCell.textLabel?.text = NSLocalizedString("Display Name", comment: "User's Display Name")
            displayNameCell.detailTextLabel?.text = person.displayName
            WPStyleGuide.configureTableViewCell(displayNameCell)
        }
    }

    @IBOutlet var removeCell : UITableViewCell! {
        didSet {
            removeCell.textLabel?.text = NSLocalizedString("Remove User", comment: "Remove User. Verb")
            WPStyleGuide.configureTableViewDestructiveActionCell(removeCell)
            removeCell.hidden = !canRemove
        }
    }


    // MARK: - Private Properties
    private var isSomeoneElse : Bool {
        return blog.account.userID != person.ID
    }

    private var canPromote : Bool {
// TODO: JLP May.3.2016. To be uncommented as part of #5175
        return false
//        return blog.isUserCapableOf(.PromoteUsers) && isSomeoneElse
    }

    private var canRemove : Bool {
// TODO: JLP May.3.2016. To be uncommented as part of #5175
        return false

//        // Note: YES, ListUsers. Brought from Calypso's code
//        return blog.isUserCapableOf(.ListUsers) && isSomeoneElse
    }

    // MARK: - Private Constants
    private let roleSegueIdentifier = "editRole"
}
