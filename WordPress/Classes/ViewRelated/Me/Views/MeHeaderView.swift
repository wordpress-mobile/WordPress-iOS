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

    private lazy var infoStackView = UIStackView(axis: .vertical, alignment: .center, spacing: 2, [titleLabel, detailsLabel])

    private lazy var iconSizeConstraints = [
        iconView.widthAnchor.constraint(equalToConstant: 0),
        iconView.heightAnchor.constraint(equalToConstant: 0)
    ]

    override init(frame: CGRect) {
        super.init(frame: .zero)

        titleLabel.font = WPStyleGuide.fontForTextStyle(.headline)
        titleLabel.accessibilityIdentifier = "Display Name"
        titleLabel.adjustsFontForContentSizeCategory = true

        detailsLabel.font = WPStyleGuide.fontForTextStyle(.subheadline)
        detailsLabel.textColor = .secondaryLabel
        detailsLabel.accessibilityIdentifier = "Username"
        detailsLabel.adjustsFontForContentSizeCategory = true

        NSLayoutConstraint.activate(iconSizeConstraints)
        setIconSize(64)

        addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        pinSubviewToAllEdges(stackView).forEach {
            // tableView.headerView inevitably has to break something
            $0.priority = UILayoutPriority(999)
        }
        NotificationCenter.default.addObserver(self, selector: #selector(refreshAvatar), name: .GravatarQEAvatarUpdateNotification, object: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setIconSize(_ size: CGFloat) {
        for constraint in iconSizeConstraints {
            constraint.constant = size
        }
        iconView.layer.cornerRadius = size / 2
        iconView.layer.masksToBounds = true
    }

    func update(with viewModel: MeHeaderViewModel) {
        self.viewModel = viewModel

        titleLabel.text = viewModel.displayName
        detailsLabel.text = viewModel.username

        if viewModel.gravatarEmail != nil {
            downloadAvatar()
        } else {
            iconView.image = nil
        }
    }

    private func downloadAvatar(forceRefresh: Bool = false) {
        if let email = viewModel?.gravatarEmail {
            iconView.downloadGravatar(for: email, gravatarRating: .x, forceRefresh: forceRefresh)
        }
    }

    @objc private func refreshAvatar(_ notification: Foundation.Notification) {
        guard let email = viewModel?.gravatarEmail,
              notification.userInfoHasEmail(email) else { return }
        downloadAvatar(forceRefresh: true)
    }

    func overrideGravatarImage(_ image: UIImage) {
        guard !RemoteFeatureFlag.gravatarQuickEditor.enabled() else { return }
        iconView.image = image

        // Note:
        // We need to update the internal cache. Otherwise, any upcoming query to refresh the gravatar
        // might return the cached (outdated) image, and the UI will end up in an inconsistent state.
        if let gravatarEmail = viewModel?.gravatarEmail {
            iconView.overrideGravatarImageCache(image, gravatarRating: .x, email: gravatarEmail)
            iconView.updateGravatar(image: image, email: gravatarEmail)
        }
    }

    func configureHorizontalMode() {
        stackView.axis = .horizontal
        stackView.spacing = 16
        stackView.layoutMargins = UIEdgeInsets(horizontal: 30, vertical: 6)
        infoStackView.alignment = .leading
        setIconSize(40)
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
