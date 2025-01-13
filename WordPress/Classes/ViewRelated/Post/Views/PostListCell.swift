import Foundation
import UIKit
import AsyncImageKit
import WordPressUI

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
    private let ellipsisButton = UIButton(type: .system)
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
        headerView.configure(with: viewModel)
        contentLabel.attributedText = viewModel.content

        featuredImageView.isHidden = viewModel.imageURL == nil
        featuredImageView.layer.opacity = viewModel.syncStateViewModel.isEditable ? 1 : 0.25
        if let imageURL = viewModel.imageURL {
            let host = MediaHost(viewModel.post)
            let thumbnailURL = MediaImageService.getResizedImageURL(for: imageURL, blog: viewModel.post.blog, size: Constants.imageSize.scaled(by: UIScreen.main.scale))
            featuredImageView.setImage(with: thumbnailURL, host: host)
        }

        statusLabel.text = viewModel.status
        statusLabel.textColor = viewModel.statusColor
        statusLabel.isHidden = viewModel.status.isEmpty

        accessibilityLabel = viewModel.accessibilityLabel

        configure(with: viewModel.syncStateViewModel)
        if let delegate {
            configureEllipsisButton(with: viewModel.post, delegate: delegate)
        }
        self.viewModel = viewModel
    }

    private func configure(with viewModel: PostSyncStateViewModel) {
        contentView.isUserInteractionEnabled = viewModel.isEditable
        headerView.configure(with: viewModel)
        ellipsisButton.isHidden = !viewModel.isShowingEllipsis
    }

    private func configureEllipsisButton(with post: Post, delegate: InteractivePostViewDelegate) {
        let menuHelper = AbstractPostMenuHelper(post)
        ellipsisButton.showsMenuAsPrimaryAction = true
        ellipsisButton.menu = menuHelper.makeMenu(presentingView: ellipsisButton, delegate: delegate)
    }

    // MARK: - Setup

    private func setupViews() {
        setupContentLabel()
        setupFeaturedImageView()
        setupStatusLabel()

        contentStackView.addArrangedSubviews([
            contentLabel,
            featuredImageView
        ])
        contentStackView.spacing = 16
        contentStackView.alignment = .top

        mainStackView.addArrangedSubviews([
            headerView,
            contentStackView,
            statusLabel
        ])
        mainStackView.spacing = 4
        contentView.addSubview(mainStackView)
        mainStackView.pinEdges(to: contentView.layoutMarginsGuide)

        // It is added last to ensure it's tappable
        setupEllipsisButton()
    }

    private func setupContentLabel() {
        contentLabel.adjustsFontForContentSizeCategory = true
        contentLabel.numberOfLines = 3
        contentLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
    }

    private func setupFeaturedImageView() {
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
        statusLabel.adjustsFontForContentSizeCategory = true
        statusLabel.numberOfLines = 1
        statusLabel.font = WPStyleGuide.fontForTextStyle(.footnote, fontWeight: .regular)
    }

    private func setupEllipsisButton() {
        ellipsisButton.setImage(UIImage(named: "more-horizontal-mobile"), for: .normal)
        ellipsisButton.tintColor = .secondaryLabel

        NSLayoutConstraint.activate([
            ellipsisButton.heightAnchor.constraint(equalToConstant: 44),
            ellipsisButton.widthAnchor.constraint(equalToConstant: 54)
        ])

        contentView.addSubview(ellipsisButton)
        ellipsisButton.pinEdges([.top, .trailing])
    }
}

private enum Constants {
    static let imageSize = CGSize(width: 64, height: 64)
}
