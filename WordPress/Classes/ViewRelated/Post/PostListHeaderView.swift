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

        if RemoteFeatureFlag.syncPublishing.enabled() {
            let syncStateViewModel = viewModel.syncStateViewModel
            configureIcon(with: syncStateViewModel)

            ellipsisButton.isHidden = !syncStateViewModel.isShowingEllipsis
            icon.isHidden = syncStateViewModel.iconInfo == nil
            indicator.isHidden = !syncStateViewModel.isShowingIndicator

            if syncStateViewModel.isShowingIndicator {
                indicator.startAnimating()
            }
        }
    }

    private func configureIcon(with viewModel: PostSyncStateViewModel) {
        guard RemoteFeatureFlag.syncPublishing.enabled() else {
            return
        }
        guard let iconInfo = viewModel.iconInfo else {
            return
        }
        icon.image = iconInfo.image
        icon.tintColor = iconInfo.color
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
            icon.widthAnchor.constraint(equalToConstant: 24),
            icon.heightAnchor.constraint(equalToConstant: 24)
        ])
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
