import UIKit
import WordPressUI

final class PostListHeaderView: UIView {

    // MARK: - Views

    private let textLabel = UILabel()
    private let icon = UIImageView()
    private let indicator = UIActivityIndicatorView(style: .medium)

    // MARK: - Initializer

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Public

    func configure(with viewModel: PostListItemViewModel) {
        textLabel.attributedText = viewModel.badges
        configure(with: viewModel.syncStateViewModel)
    }

    func configure(with viewModel: PostSyncStateViewModel) {
        if let iconInfo = viewModel.iconInfo {
            icon.image = iconInfo.image
            icon.tintColor = iconInfo.color
        }
        icon.isHidden = viewModel.iconInfo == nil
        indicator.isHidden = !viewModel.isShowingIndicator

        if viewModel.isShowingIndicator {
            indicator.startAnimating()
        }
    }

    // MARK: - Setup

    private func setupView() {
        setupIcon()

        // Trailing spacer to allocate enough space for the "More" button.
        let accessoriesStackView = UIStackView(arrangedSubviews: [icon, indicator, SpacerView(width: 40)])
        accessoriesStackView.spacing = 4
        let stackView = UIStackView(arrangedSubviews: [textLabel, accessoriesStackView])

        indicator.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)

        stackView.spacing = 12
        addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        pinSubviewToAllEdges(stackView)
    }

    private func setupIcon() {
        NSLayoutConstraint.activate([
            icon.widthAnchor.constraint(equalToConstant: 22),
            icon.heightAnchor.constraint(equalToConstant: 22)
        ])
        icon.contentMode = .scaleAspectFit
    }
}
