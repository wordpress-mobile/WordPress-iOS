import UIKit

class LoginEpilogueConnectSiteCell: UITableViewCell, NibReusable {

    // Properties

    @IBOutlet var connectLabel: UILabel!

    // Init

    func configure(numberOfSites: Int) {
        connectLabel.text = numberOfSites == 0 ? LocalizedText.connectSite : LocalizedText.connectAnother
        connectLabel.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .subheadline).pointSize, weight: .regular)
        connectLabel.textColor = .primary
        accessibilityIdentifier = "connectSite"
        accessibilityTraits = .button
    }

}

private extension LoginEpilogueConnectSiteCell {
    enum LocalizedText {
        static let connectSite = NSLocalizedString("Connect a site", comment: "Link to connect a site, shown after logging in.")
        static let connectAnother = NSLocalizedString("Connect another site", comment: "Link to connect another site, shown after logging in.")
    }
}
