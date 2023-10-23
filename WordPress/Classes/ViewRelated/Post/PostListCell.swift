import Foundation
import UIKit
import Combine

final class PostListCell: UITableViewCell, Reusable {

    // MARK: - Views

    private lazy var mainStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        return stackView
    }()

    private lazy var contentStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        return stackView
    }()

    private let headerView = PostListHeaderView()
    private let contentLabel = UILabel()
    private let featuredImageView = CachedAnimatedImageView()
    private let statusLabel = UILabel()
    private var cancellables: [AnyCancellable] = []

    // MARK: - Properties

    private lazy var imageLoader = ImageLoader(imageView: featuredImageView, loadingIndicator: SolidColorActivityIndicator())

    // MARK: - Initializers

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Public

    override func prepareForReuse() {
        super.prepareForReuse()

        cancellables = []
    }

    func configure(with viewModel: PostListItemViewModel, delegate: InteractivePostViewDelegate? = nil) {
        headerView.configure(with: viewModel, delegate: delegate)

        viewModel.$content.sink { [contentLabel] in
            contentLabel.attributedText = $0
        }.store(in: &cancellables)

        imageLoader.prepareForReuse()
        featuredImageView.isHidden = viewModel.imageURL == nil
        if let imageURL = viewModel.imageURL {
            let host = MediaHost(with: viewModel.post) { error in
                WordPressAppDelegate.crashLogging?.logError(error)
            }
            imageLoader.loadImage(with: imageURL, from: host, preferredSize: Constants.imageSize)
        }

        statusLabel.text = viewModel.status
        statusLabel.textColor = viewModel.statusColor
        statusLabel.isHidden = viewModel.status.isEmpty
    }

    // MARK: - Setup

    private func setupViews() {
        separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 0)

        setupContentLabel()
        setupFeaturedImageView()
        setupStatusLabel()

        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        contentStackView.addArrangedSubviews([
            contentLabel,
            featuredImageView
        ])
        contentStackView.spacing = 16
        contentStackView.alignment = .top

        mainStackView.translatesAutoresizingMaskIntoConstraints = false
        mainStackView.addArrangedSubviews([
            headerView,
            contentStackView,
            statusLabel
        ])
        mainStackView.spacing = 4
        mainStackView.isLayoutMarginsRelativeArrangement = true
        mainStackView.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16)

        contentView.addSubview(mainStackView)
        contentView.pinSubviewToAllEdges(mainStackView)
    }

    private func setupContentLabel() {
        contentLabel.translatesAutoresizingMaskIntoConstraints = false
        contentLabel.adjustsFontForContentSizeCategory = true
        contentLabel.numberOfLines = 3
        contentLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
    }

    private func setupFeaturedImageView() {
        featuredImageView.translatesAutoresizingMaskIntoConstraints = false
        featuredImageView.contentMode = .scaleAspectFill
        featuredImageView.layer.masksToBounds = true
        featuredImageView.layer.cornerRadius = 5
        featuredImageView.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)

        NSLayoutConstraint.activate([
            featuredImageView.widthAnchor.constraint(equalToConstant: Constants.imageSize.width),
            featuredImageView.heightAnchor.constraint(equalToConstant: Constants.imageSize.height),
        ])
    }

    private func setupStatusLabel() {
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.adjustsFontForContentSizeCategory = true
        statusLabel.numberOfLines = 1
        statusLabel.font = WPStyleGuide.fontForTextStyle(.footnote, fontWeight: .regular)
    }
}

private enum Constants {
    static let imageSize = CGSize(width: 64, height: 64)
}
