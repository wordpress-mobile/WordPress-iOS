import UIKit

final class PostListHeaderView: UIView {

    // MARK: - Views

    private let textLabel = UILabel()
    private let icon = UIImageView()
    private let indicator = UIActivityIndicatorView(style: .medium)
    private let ellipsisButton = UIButton(type: .custom)

    // MARK: - Properties

    private var post: Post?
    private var viewModel: PostListItemViewModel?

    // MARK: - Initializer

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Public

    func configure(with viewModel: PostListItemViewModel, delegate: InteractivePostViewDelegate? = nil) {
        if let delegate {
            configureEllipsisButton(with: viewModel.post, delegate: delegate)
        }
        textLabel.attributedText = viewModel.badges
        configure(with: viewModel.syncStateViewModel)
    }

    func configure(with viewModel: PostSyncStateViewModel) {
        guard RemoteFeatureFlag.syncPublishing.enabled() else {
            return
        }

        if let iconInfo = viewModel.iconInfo {
            icon.image = iconInfo.image
            icon.tintColor = iconInfo.color
        }

        ellipsisButton.isHidden = !viewModel.isShowingEllipsis
        icon.isHidden = viewModel.iconInfo == nil
        indicator.isHidden = !viewModel.isShowingIndicator

        if viewModel.isShowingIndicator {
            indicator.startAnimating()
        }
    }

    private func configureEllipsisButton(with post: Post, delegate: InteractivePostViewDelegate) {
        let menuHelper = AbstractPostMenuHelper(post)
        ellipsisButton.showsMenuAsPrimaryAction = true
        ellipsisButton.menu = menuHelper.makeMenu(presentingView: ellipsisButton, delegate: delegate)
    }

    // MARK: - Setup

    private func setupView() {
        setupIcon()
        setupEllipsisButton()

        let stackView: UIStackView
        if RemoteFeatureFlag.syncPublishing.enabled() {
            let innerStackView = UIStackView(arrangedSubviews: [icon, indicator, ellipsisButton])
            innerStackView.spacing = 4
            stackView = UIStackView(arrangedSubviews: [textLabel, innerStackView])
        } else {
            stackView = UIStackView(arrangedSubviews: [textLabel, ellipsisButton])
        }

        indicator.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)

        stackView.spacing = 12
        addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        pinSubviewToAllEdges(stackView)
    }

    private func setupIcon() {
        guard RemoteFeatureFlag.syncPublishing.enabled() else {
            return
        }
        NSLayoutConstraint.activate([
            icon.widthAnchor.constraint(equalToConstant: 22),
            icon.heightAnchor.constraint(equalToConstant: 22)
        ])
        icon.contentMode = .scaleAspectFit
    }

    private func setupEllipsisButton() {
        ellipsisButton.translatesAutoresizingMaskIntoConstraints = false
        ellipsisButton.setImage(UIImage(named: "more-horizontal-mobile"), for: .normal)
        ellipsisButton.tintColor = .listIcon

        NSLayoutConstraint.activate([
            ellipsisButton.widthAnchor.constraint(equalToConstant: 24)
        ])
    }
}
