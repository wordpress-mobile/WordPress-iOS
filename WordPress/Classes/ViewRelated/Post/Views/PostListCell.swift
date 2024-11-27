import Foundation
import UIKit

protocol AbstractPostListCell {
    /// A post displayed by the cell.
    var post: AbstractPost? { get }
}

final class PostListCell: UITableViewCell, AbstractPostListCell, PostSearchResultCell, Reusable {
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
    private let featuredImageView = AsyncImageView()
    private let statusLabel = UILabel()

    // MARK: - Properties

    private var viewModel: PostListItemViewModel?

    // MARK: - PostSearchResultCell

    var attributedText: NSAttributedString? {
        get { contentLabel.attributedText }
        set { contentLabel.attributedText = newValue }
    }

    // MARK: AbstractPostListCell

    var post: AbstractPost? { viewModel?.post }

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

        featuredImageView.prepareForReuse()
        viewModel = nil
    }

    func configure(with viewModel: PostListItemViewModel, delegate: InteractivePostViewDelegate? = nil) {
        UIView.performWithoutAnimation {
            _configure(with: viewModel, delegate: delegate)
        }
    }

    private func _configure(with viewModel: PostListItemViewModel, delegate: InteractivePostViewDelegate? = nil) {
        headerView.configure(with: viewModel, delegate: delegate)
        contentLabel.attributedText = viewModel.content

        featuredImageView.isHidden = viewModel.imageURL == nil
        featuredImageView.layer.opacity = viewModel.syncStateViewModel.isEditable ? 1 : 0.25
        if let imageURL = viewModel.imageURL {
            let host = MediaHost(with: viewModel.post) { error in
                WordPressAppDelegate.crashLogging?.logError(error)
            }
            let thumbnailURL = MediaImageService.getResizedImageURL(for: imageURL, blog: viewModel.post.blog, size: Constants.imageSize.scaled(by: UIScreen.main.scale))
            featuredImageView.setImage(with: thumbnailURL, host: host)
        }

        statusLabel.text = viewModel.status
        statusLabel.textColor = viewModel.statusColor
        statusLabel.isHidden = viewModel.status.isEmpty

        accessibilityLabel = viewModel.accessibilityLabel

        configure(with: viewModel.syncStateViewModel)
        self.viewModel = viewModel
    }

    private func configure(with viewModel: PostSyncStateViewModel) {
        contentView.isUserInteractionEnabled = viewModel.isEditable
        headerView.configure(with: viewModel)
    }

    // MARK: - Setup

    private func setupViews() {
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
        contentView.addSubview(mainStackView)
        contentView.pinSubviewToAllEdgeMargins(mainStackView)
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
