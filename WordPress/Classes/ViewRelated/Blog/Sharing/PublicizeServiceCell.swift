import UIKit
import WordPressUI
import AsyncImageKit

final class PublicizeServiceCell: UITableViewCell {
    let iconView = AsyncImageView()
    let titleLabel = UILabel()
    let detailsLabel = UILabel()

    @objc class var cellId: String { "PublicizeServiceCell" }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        detailsLabel.font = .preferredFont(forTextStyle: .footnote)
        detailsLabel.textColor = .secondaryLabel

        let stackView = UIStackView(alignment: .center, spacing: 12, [
            iconView,
            UIStackView(axis: .vertical, alignment: .leading, spacing: 2, [titleLabel, detailsLabel])
        ])
        contentView.addSubview(stackView)
        stackView.pinEdges(to: contentView.layoutMarginsGuide)

        NSLayoutConstraint.activate([
            iconView.widthAnchor.constraint(equalToConstant: 28),
            iconView.heightAnchor.constraint(equalToConstant: 28),
        ])
        iconView.layer.cornerRadius = 8
        iconView.layer.masksToBounds = true
        iconView.backgroundColor = UIColor.white

        iconView.contentMode = .scaleAspectFit
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        accessoryView = .none
        iconView.prepareForReuse()
    }

    @objc func configure(with service: PublicizeService, connections: [PublicizeConnection]) {
        let name = service.name
        if name != .unknown && !name.hasModernRemoteLogo {
            iconView.image = name.localIconImage
        } else if let imageURL = URL(string: service.icon) {
            iconView.setImage(with: imageURL)
        } else {
            iconView.image = UIImage(named: "social-default")
        }

        titleLabel.text = service.label

        detailsLabel.isHidden = connections.isEmpty
        if connections.count > 2 {
            detailsLabel.text = String(format: Strings.numberOfAccounts, connections.count)
        } else {
            detailsLabel.text = connections
                .map(\.externalDisplay)
                .joined(separator: ", ")
        }

        if service.isSupported {
            if connections.contains(where: { $0.requiresUserAction() }) {
                accessoryView = WPStyleGuide.sharingCellWarningAccessoryImageView()
            }
        } else {
            accessoryView = WPStyleGuide.sharingCellErrorAccessoryImageView()
        }
    }
}

private extension PublicizeService.ServiceName {
    /// We no longer need to provide local overrides for these on this screen
    /// as the remote images are good.
    var hasModernRemoteLogo: Bool {
        [
            PublicizeService.ServiceName.instagram,
            PublicizeService.ServiceName.mastodon
        ].contains(self)
    }
}

private enum Strings {
    static let numberOfAccounts = NSLocalizedString("socialSharing.connectionDetails.nAccount", value: "%d accounts", comment: "The number of connected accounts on a third party sharing service connected to the user's blog. The '%d' is a placeholder for the number of accounts.")
}

extension PublicizeService.ServiceName {

    /// Returns the local image for the icon representing the social network.
    var localIconImage: UIImage {
        WPStyleGuide.socialIcon(for: rawValue as NSString)
    }
}
