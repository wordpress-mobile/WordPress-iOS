import UIKit
import WordPressUI

final class MeHeaderView: UIView {
    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let detailsLabel = UILabel()
    private var viewModel: MeHeaderViewModel?

    private lazy var stackView = UIStackView(
        axis: .vertical,
        alignment: .center,
        spacing: 10,
        insets: UIEdgeInsets(horizontal: 20, vertical: 8),
        [iconView, infoStackView]
    )

    private lazy var infoStackView = UIStackView(axis: .vertical, spacing: 2, [titleLabel, detailsLabel])

    override init(frame: CGRect) {
        super.init(frame: .zero)

        titleLabel.font = WPStyleGuide.fontForTextStyle(.headline)
        titleLabel.accessibilityIdentifier = "Display Name"
        titleLabel.adjustsFontForContentSizeCategory = true

        detailsLabel.font = WPStyleGuide.fontForTextStyle(.subheadline)
        detailsLabel.textColor = .secondaryLabel
        detailsLabel.accessibilityIdentifier = "Username"
        detailsLabel.adjustsFontForContentSizeCategory = true

        let iconSize: CGFloat = 64
        NSLayoutConstraint.activate([
            iconView.widthAnchor.constraint(equalToConstant: iconSize),
            iconView.heightAnchor.constraint(equalToConstant: iconSize)
        ])
        iconView.layer.cornerRadius = iconSize / 2
        iconView.layer.masksToBounds = true
        iconView.isUserInteractionEnabled = true

        addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        pinSubviewToAllEdges(stackView).forEach {
            // tableView.headerView inevitably has to break something
            $0.priority = UILayoutPriority(999)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(with viewModel: MeHeaderViewModel) {
        self.viewModel = viewModel

        titleLabel.text = viewModel.displayName
        detailsLabel.text = viewModel.username

        if let gravatarEmail = viewModel.gravatarEmail {
            iconView.downloadGravatar(for: gravatarEmail, gravatarRating: .x)
        } else {
            iconView.image = nil
        }
    }

    func overrideGravatarImage(_ image: UIImage) {
        iconView.image = image

        // Note:
        // We need to update the internal cache. Otherwise, any upcoming query to refresh the gravatar
        // might return the cached (outdated) image, and the UI will end up in an inconsistent state.
        if let gravatarEmail = viewModel?.gravatarEmail {
            iconView.overrideGravatarImageCache(image, gravatarRating: .x, email: gravatarEmail)
            iconView.updateGravatar(image: image, email: gravatarEmail)
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        NSLog(traitCollection.debugDescription)
    }
}

struct MeHeaderViewModel {
    let gravatarEmail: String?
    let username: String
    let displayName: String

    init(account: WPAccount) {
        self.gravatarEmail = account.email
        let username = account.username ?? ""
        self.username = "\(username.contains("@") ? "" : "@")\(username)"
        self.displayName = account.displayName ?? ""
    }
}
