import Foundation
import WordPressShared
import DesignSystem

struct GravatarInfoRow: ImmuTableRow {

    static let cell = ImmuTableCell.class(GravatarInfoCell.self)

    let title: String
    let description: String
    let action: ImmuTableAction?

    func configureCell(_ cell: UITableViewCell) {
        guard let cell = cell as? GravatarInfoCell else {
            return
        }

        cell.titleLabel.text = title
        cell.descriptionLabel.text = description
        cell.selectionStyle = .none
    }
}

class GravatarInfoCell: MigrationCell {

    private enum Constants {
        static let wordpressGravatarLogo = UIImage(named: "wordpress-gravatar")
        static let jetpackGravatarLogo = UIImage(named: "jetpack-gravatar")
        static let imageSize = CGSize(width: 50, height: 30)
    }

    private let intersectingLogosView: UIImageView = {
        let view = UIImageView(frame: .zero)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.contentMode = .scaleAspectFit
        view.image = AppConfiguration.isJetpack ? Constants.jetpackGravatarLogo : Constants.wordpressGravatarLogo
        view.widthAnchor.constraint(equalToConstant: Constants.imageSize.width).isActive = true
        view.heightAnchor.constraint(equalToConstant: Constants.imageSize.height).isActive = true
        return view
    }()

    override var logoImageView: UIImageView {
        return intersectingLogosView
    }
}

enum GravatarInfoConstants {
    static let title = NSLocalizedString("Your WordPress.com profile is powered by Gravatar.", comment: "Text in the profile editing page. Let the user know that their profile is managed by Gravatar.")
    static let description = NSLocalizedString("Updating your avatar, name and about info here will also update it across all sites that use Gravatar profiles.", comment: "Text in the profile editing page. Lets the user know about the consequences of their profile editing actions and how this relates to Gravatar.")
    static let linkText = NSLocalizedString("What is Gravatar?", comment: "This is a link that takes the user to the external Gravatar website")
    static let gravatarLinkAccessibilityHint = NSLocalizedString("Tap to visit the Gravatar website in an external browser", comment: "Accessibility hint, informing user the button can be used to visit the Gravatar website.")
    static let gravatarLink = "https://gravatar.com"
}
