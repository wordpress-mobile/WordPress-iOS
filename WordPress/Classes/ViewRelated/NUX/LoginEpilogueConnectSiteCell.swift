import UIKit

class LoginEpilogueConnectSiteCell: UITableViewCell, NibReusable {

    // Properties

    @IBOutlet var connectLabel: UILabel!

    // Init

    override func awakeFromNib() {
        super.awakeFromNib()
        connectLabel.text = NSLocalizedString("Connect another site", comment: "Link to connect a site, shown after logging in.")
        connectLabel.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .subheadline).pointSize, weight: .regular)
        connectLabel.textColor = .primary
    }

}
