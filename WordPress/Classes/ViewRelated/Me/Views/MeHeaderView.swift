import Combine
import UIKit
import WordPressData
import WordPressUI

protocol MeHeaderViewDelegate: NSObjectProtocol {
    func meHeaderViewDidTapOnIconView(_ view: MeHeaderView)
}

final class MeHeaderView: UIView {
    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let detailsLabel = UILabel()
    private var viewModel: MeHeaderViewModel?
    private var avatarSubscription: AnyCancellable?

    weak var delegate: MeHeaderViewDelegate?

    private lazy var stackView = UIStackView(
        axis: .vertical,
        alignment: .center,
        spacing: 10,
        insets: NSDirectionalEdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 20),
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
        avatarSubscription = AccountAvatar.shared.$image.sink { [weak self] avatar in
            self?.updateAvatar(avatar)
        }

        iconView.isUserInteractionEnabled = true
        iconView.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(onIconViewTap))
        )
    }

    @objc func onIconViewTap() {
        delegate?.meHeaderViewDidTapOnIconView(self)
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

        updateAvatar(AccountAvatar.shared.image)
    }

    private func updateAvatar(_ avatar: UIImage?) {
        guard viewModel?.gravatarEmail != nil else {
            iconView.image = nil
            return
        }
        iconView.image = avatar ?? .gravatarPlaceholderImage
    }

    func configureHorizontalMode() {
        stackView.axis = .horizontal
        stackView.spacing = 16
        stackView.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 6, leading: 30, bottom: 6, trailing: 30)
        infoStackView.alignment = .leading
        setIconSize(40)
    }

    func configureReaderMode() {
        infoStackView.alignment = .leading
        setIconSize(60)
        titleLabel.font = AppStyleGuide.current.navigationBarLargeFont
        infoStackView.spacing = 0
        detailsLabel.isHidden = true
    }
}

struct MeHeaderViewModel {
    let gravatarEmail: String?
    let username: String
    let displayName: String

    init(account: WPAccount) {
        self.gravatarEmail = account.email
        let username = account.username
        self.username = "\(username.contains("@") ? "" : "@")\(username)"
        self.displayName = account.displayName ?? ""
    }
}
