import Foundation
import WordPressAuthenticator

class PickDomainTableViewController: SiteCreationDomainsTableViewController {

    override func titleAndDescriptionCell() -> UITableViewCell {
        let title = ""
        let description = NSLocalizedString("Pick an available address",
                                            comment: "Description for the Register domain screen")
        let cell = LoginSocialErrorCell(title: title, description: description)
        cell.selectionStyle = .none
        return cell
    }
}
