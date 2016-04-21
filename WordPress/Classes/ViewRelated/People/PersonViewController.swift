import Foundation
import UIKit
import WordPressShared

/// Displays a Blog's User Details
///
class PersonViewController : UITableViewController
{
    // MARK: - Public Properties
    
    var person : Person!
    
    
    // MARK: - View Lifecyle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = person?.fullName
        WPStyleGuide.configureColorsForView(view, andTableView: tableView)
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
    
    @IBOutlet var roleTableCell : UITableViewCell! {
        didSet {
            roleTableCell.textLabel?.text = NSLocalizedString("Role", comment: "User's Role")
            roleTableCell.detailTextLabel?.text = person?.role.description.capitalizedString
            WPStyleGuide.configureTableViewCell(roleTableCell)
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
    
    @IBOutlet var removalTableCell : UITableViewCell! {
        didSet {
            removalTableCell.textLabel?.text = NSLocalizedString("Remove", comment: "Remove User. Verb")
            WPStyleGuide.configureTableViewDestructiveActionCell(removalTableCell)
        }
    }
}
