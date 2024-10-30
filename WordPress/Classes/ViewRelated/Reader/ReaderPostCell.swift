import SwiftUI
import UIKit
import Combine

final class ReaderPostCell: UITableViewCell {
    private let view = ReaderPostCellView()
    private var isSeparatorHidden = false
    private var isCompact: Bool = true {
        didSet {
            guard oldValue != isCompact else { return }
            setNeedsUpdateConstraints()
        }
    }
    private var contentViewConstraints: [NSLayoutConstraint] = []

    static let avatarSize: CGFloat = 28

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.addSubview(view)
        view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: contentView.topAnchor),
            view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).withPriority(999),
        ])

        selectedBackgroundView = UIView()
        selectedBackgroundView?.backgroundColor = UIColor.opaqueSeparator.withAlphaComponent(0.2)
    }

    required init?(coder: NSCoder) {
        fatalError("Not implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        view.prepareForReuse()
    }

    func configure(
        with viewModel: ReaderPostCellViewModel,
        isCompact: Bool,
        isSeparatorHidden: Bool
    ) {
        self.isSeparatorHidden = isSeparatorHidden
        self.isCompact = isCompact

        view.isCompact = isCompact
        updateSeparatorsInsets()
        view.configure(with: viewModel)

        accessibilityLabel = "\(viewModel.author). \(viewModel.title). \(viewModel.details)"
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        updateSeparatorsInsets()
    }

    private func updateSeparatorsInsets() {
        separatorInset = UIEdgeInsets(.leading, isSeparatorHidden ? 9999 : view.insets.left + (isCompact ? 0 : contentView.readableContentGuide.layoutFrame.minX))
    }

    override func updateConstraints() {
        NSLayoutConstraint.deactivate(contentViewConstraints)
        contentViewConstraints = [
            view.leadingAnchor.constraint(equalTo: isCompact ? contentView.leadingAnchor : contentView.readableContentGuide.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: isCompact ? contentView.trailingAnchor : contentView.readableContentGuide.trailingAnchor)
        ]
        NSLayoutConstraint.activate(contentViewConstraints)

        super.updateConstraints()
    }
}

private final class ReaderPostCellView: UIView {
    // Header
    let avatarView = ImageView()
    let buttonAuthor = makeAuthorButton()
    let timeLabel = UILabel()
    let buttonMore = makeButton(systemImage: "ellipsis", font: .systemFont(ofSize: 13))

    // Content
    let titleLabel = UILabel()
    let detailsLabel = UILabel()
    let imageView = ImageView()

    // Footer
    let buttons = ReaderPostToolbarButtons()

    private lazy var postPreview = UIStackView(axis: .vertical, alignment: .leading, spacing: 12, [
        UIStackView(axis: .vertical, spacing: 4, [titleLabel, detailsLabel]),
        imageView
    ])

    var isCompact: Bool = true {
        didSet {
            guard oldValue != isCompact else { return }
            configureLayout(isCompact: isCompact)
        }
    }

    let insets = UIEdgeInsets(top: 0, left: 44, bottom: 0, right: 16)

    private var viewModel: ReaderPostCellViewModel? // important: has to retain
    private let coverAspectRatio: CGFloat = 239.0 / 358.0
    private var imageViewConstraints: [NSLayoutConstraint] = []
    private var cancellables: [AnyCancellable] = []

    override init(frame: CGRect) {
        super.init(frame: frame)

        setupStyle()
        setupLayout()
        setupActions()
        setupAccessibility()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func prepareForReuse() {
        cancellables = []
        avatarView.prepareForReuse()
        imageView.prepareForReuse()
    }

    private func setupStyle() {
        avatarView.layer.cornerRadius = ReaderPostCell.avatarSize / 2
        avatarView.layer.masksToBounds = true
        avatarView.successBackgroundColor = UIColor.white
        avatarView.layer.borderWidth = 0.5
        avatarView.layer.borderColor = UIColor.opaqueSeparator.withAlphaComponent(0.5).cgColor
        avatarView.isErrorViewEnabled = false

        buttonAuthor.maximumContentSizeCategory = .accessibilityLarge
        setupTimeLabel(timeLabel)
        timeLabel.setContentCompressionResistancePriority(.init(800), for: .horizontal)

        titleLabel.font = .preferredFont(forTextStyle: .headline)
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.maximumContentSizeCategory = .accessibilityExtraLarge

        detailsLabel.font = .preferredFont(forTextStyle: .subheadline)
        detailsLabel.textColor = .secondaryLabel
        detailsLabel.adjustsFontForContentSizeCategory = true
        detailsLabel.maximumContentSizeCategory = .accessibilityExtraLarge

        imageView.layer.cornerRadius = 8
        imageView.layer.masksToBounds = true
        imageView.contentMode = .scaleAspectFill

        buttonMore.configuration?.baseForegroundColor = UIColor.opaqueSeparator
        buttonMore.configuration?.contentInsets = .init(top: 12, leading: 8, bottom: 12, trailing: 20)
    }

    private func setupLayout() {
        let dot = UILabel()
        setupTimeLabel(dot)
        dot.text = " · "

        // These seems to be an issue with `lineBreakMode` in `UIButton.Configuration`
        // and `.firstLineBaseline`, so reserving to `.center`.
        let headerView = UIStackView(alignment: .center, [buttonAuthor, dot, timeLabel])
        let toolbarView = UIStackView(buttons.allButtons)

        for view in [avatarView, headerView, postPreview, buttonMore, toolbarView] {
            addSubview(view)
            view.translatesAutoresizingMaskIntoConstraints = false
        }

        // Using constraints as it provides a bit more control, performance, and
        // is arguable more readable than too many nested stacks.
        NSLayoutConstraint.activate([
            avatarView.widthAnchor.constraint(equalToConstant: ReaderPostCell.avatarSize),
            avatarView.heightAnchor.constraint(equalToConstant: ReaderPostCell.avatarSize),
            avatarView.centerYAnchor.constraint(equalTo: timeLabel.centerYAnchor),
            avatarView.trailingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: -8),

            headerView.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            headerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: insets.left),
            headerView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -50),

            buttonMore.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            buttonMore.trailingAnchor.constraint(equalTo: trailingAnchor),

            postPreview.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 0),
            postPreview.leadingAnchor.constraint(equalTo: leadingAnchor, constant: insets.left),
            postPreview.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -insets.right),
            postPreview.bottomAnchor.constraint(equalTo: toolbarView.topAnchor),

            // Align with a preview, but keep the extended frame to make it easier to tap
            toolbarView.leadingAnchor.constraint(equalTo: postPreview.leadingAnchor, constant: -14),
            toolbarView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        configureLayout(isCompact: isCompact)
    }

    private func setupTimeLabel(_ label: UILabel) {
        label.font = .preferredFont(forTextStyle: .footnote)
        label.textColor = .secondaryLabel
        label.adjustsFontForContentSizeCategory = true
        label.maximumContentSizeCategory = .accessibilityMedium
    }

    private func configureLayout(isCompact: Bool) {
        titleLabel.numberOfLines = 2
        detailsLabel.numberOfLines = isCompact ? 3 : 5

        postPreview.axis = isCompact ? .vertical : .horizontal
        postPreview.spacing = isCompact ? 12 : 20

        setNeedsUpdateConstraints()
    }

    override func updateConstraints() {
        NSLayoutConstraint.deactivate(imageViewConstraints)
        if isCompact {
            imageViewConstraints = [
                imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: coverAspectRatio),
                imageView.widthAnchor.constraint(lessThanOrEqualTo: widthAnchor, constant: -(insets.left * 2)),
                imageView.widthAnchor.constraint(equalTo: widthAnchor).withPriority(150)
            ]
        } else {
            imageViewConstraints = [
                imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: coverAspectRatio),
                imageView.widthAnchor.constraint(equalToConstant: 200)
            ]
        }
        NSLayoutConstraint.activate(imageViewConstraints)

        super.updateConstraints()
    }

    // MARK: Actions

    private func setupActions() {
        buttonAuthor.addTarget(self, action: #selector(buttonAuthorTapped), for: .primaryActionTriggered)
        buttonMore.showsMenuAsPrimaryAction = true
        buttonMore.menu = UIMenu(options: .displayInline, children: [
            UIDeferredMenuElement.uncached { [weak self] callback in
                callback(self?.makeMoreMenu() ?? [])
            }
        ])
        buttons.bookmark.addTarget(self, action: #selector(buttonBookmarkTapped), for: .primaryActionTriggered)
        buttons.reblog.addTarget(self, action: #selector(buttonReblogTapped), for: .primaryActionTriggered)
        buttons.comment.addTarget(self, action: #selector(buttonCommentTapped), for: .primaryActionTriggered)
        buttons.like.addTarget(self, action: #selector(buttonLikeTapped), for: .primaryActionTriggered)
    }

    @objc private func buttonAuthorTapped() {
        viewModel?.showSiteDetails()
    }

    @objc private func buttonBookmarkTapped() {
        viewModel?.toogleBookmark()
    }

    @objc private func buttonReblogTapped() {
        viewModel?.reblog()
    }

    @objc private func buttonCommentTapped() {
        viewModel?.comment()
    }

    @objc private func buttonLikeTapped() {
        viewModel?.toggleLike()
    }

    private func makeMoreMenu() -> [UIMenuElement] {
        guard let viewModel, let viewController = viewModel.viewController else {
            return []
        }
        return ReaderPostMenu(
            post: viewModel.post,
            topic: viewController.readerTopic,
            anchor: buttonMore,
            viewController: viewController
        ).makeMenu()
    }

    // MARK: Configure (ViewModel)

    func configure(with viewModel: ReaderPostCellViewModel) {
        self.viewModel = viewModel

        setAvatar(with: viewModel)
        buttonAuthor.configuration?.attributedTitle = AttributedString(viewModel.author, attributes: Self.authorAttributes)
        timeLabel.text = viewModel.time

        titleLabel.text = viewModel.title
        detailsLabel.text = viewModel.details

        imageView.isHidden = viewModel.imageURL == nil
        if let imageURL = viewModel.imageURL {
            imageView.setImage(with: imageURL)
        }

        configureToolbar(with: viewModel.toolbar)
        configureToolbarAccessibility(with: viewModel.toolbar)
    }

    private func configureToolbar(with viewModel: ReaderPostToolbarViewModel) {
        buttons.bookmark.configuration = {
            var configuration = buttons.bookmark.configuration ?? .plain()
            configuration.image = UIImage(systemName: viewModel.isBookmarked ? "bookmark.fill" : "bookmark")
            configuration.baseForegroundColor = viewModel.isBookmarked ? UIAppColor.brand : .secondaryLabel
            return configuration
        }()

        buttons.comment.isHidden = !viewModel.isCommentsEnabled
        if viewModel.isCommentsEnabled {
            buttons.comment.configuration?.attributedTitle = AttributedString(kFormatted(viewModel.commentCount), attributes: Self.toolbarAttributes)
        }
        buttons.like.isHidden = !viewModel.isLikesEnabled
        if viewModel.isLikesEnabled {
            buttons.like.configuration = {
                var configuration = buttons.like.configuration ?? .plain()
                configuration.attributedTitle = AttributedString(kFormatted(viewModel.likeCount), attributes: Self.toolbarAttributes)
                configuration.image = UIImage(systemName: viewModel.isLiked ? "star.fill" : "star")
                configuration.baseForegroundColor = viewModel.isLiked ? .systemYellow : .secondaryLabel
                return configuration
            }()
        }
    }

    private func setAvatar(with viewModel: ReaderPostCellViewModel) {
        avatarView.imageView.image = UIImage(named: "post-blavatar-placeholder")
        let avatarSize = CGSize(width: ReaderPostCell.avatarSize, height: ReaderPostCell.avatarSize)
            .scaled(by: UITraitCollection.current.displayScale)
        if let avatarURL = viewModel.avatarURL {
            avatarView.setImage(with: avatarURL, size: avatarSize)
        } else {
            viewModel.$avatarURL.compactMap({ $0 }).sink { [weak self] in
                self?.avatarView.setImage(with: $0, size: avatarSize)
            }.store(in: &cancellables)
        }
    }

    private static let authorAttributes = AttributeContainer([
        .font: WPStyleGuide.fontForTextStyle(.footnote, fontWeight: .medium),
        .foregroundColor: UIColor.label
    ])

    private static let toolbarAttributes = AttributeContainer([
        .font: UIFont.preferredFont(forTextStyle: .footnote),
        .foregroundColor: UIColor.secondaryLabel
    ])
}

// MARK: - Helpers

private struct ReaderPostToolbarButtons {
    let bookmark = makeButton(systemImage: "bookmark")
    let reblog = makeButton(systemImage: "arrow.2.squarepath")
    let comment = makeButton(systemImage: "message")
    let like = makeButton(systemImage: "star")

    var allButtons: [UIButton] { [bookmark, reblog, comment, like] }
}

private func makeAuthorButton() -> UIButton {
    var configuration = UIButton.Configuration.plain()
    configuration.titleLineBreakMode = .byTruncatingTail
    configuration.contentInsets = .init(top: 8, leading: 0, bottom: 8, trailing: 0)
    return UIButton(configuration: configuration)
}

private func makeButton(systemImage: String, font: UIFont = UIFont.preferredFont(forTextStyle: .footnote)) -> UIButton {
    var configuration = UIButton.Configuration.plain()
    configuration.image = UIImage(systemName: systemImage)
    configuration.imagePadding = 8
    configuration.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(font: font)
    configuration.baseForegroundColor = .secondaryLabel
    configuration.contentInsets = .init(top: 16, leading: 12, bottom: 14, trailing: 12)

    let button = UIButton(configuration: configuration)
    if #available(iOS 17.0, *) {
        button.isSymbolAnimationEnabled = true
    }
    button.maximumContentSizeCategory = .extraExtraExtraLarge
    return button
}

private func kFormatted(_ count: Int) -> String {
    count.formatted(.number.notation(.compactName))
}

// MARK: - ReaderPostCellView (Accessibility)

private extension ReaderPostCellView {
    func setupAccessibility() {
        buttonAuthor.accessibilityHint =  NSLocalizedString("reader.post.buttonSite.accessibilityHint", value: "Opens the site details", comment: "Accessibility hint for the site header")
        buttonMore.accessibilityLabel = NSLocalizedString("reader.post.moreMenu.accessibilityLabel", value: "More actions", comment: "Button accessibility label")

        buttonAuthor.accessibilityIdentifier = "reader-author-button"
        buttonMore.accessibilityIdentifier = "reader-more-button"
        buttons.bookmark.accessibilityIdentifier = "reader-bookmark-button"
        buttons.reblog.accessibilityIdentifier = "reader-reblog-button"
        buttons.comment.accessibilityIdentifier = "reader-comment-button"
        buttons.like.accessibilityIdentifier = "reader-like-button"
    }

    func configureToolbarAccessibility(with viewModel: ReaderPostToolbarViewModel) {
        buttons.bookmark.accessibilityLabel = viewModel.isBookmarked ? NSLocalizedString("reader.post.buttonRemoveBookmark.accessibilityLint", value: "Remove bookmark", comment: "Button accessibility label") : NSLocalizedString("reader.post.buttonBookmark.accessibilityLabel", value: "Bookmark", comment: "Button accessibility label")
        buttons.reblog.accessibilityLabel = NSLocalizedString("reader.post.buttonReblog.accessibilityLabel", value: "Reblog", comment: "Button accessibility label")
        buttons.comment.accessibilityLabel = {
            let label = NSLocalizedString("reader.post.buttonComment.accessibilityLabel", value: "Show comments", comment: "Button accessibility label")
            let count = String(format: NSLocalizedString("reader.post.numberOfComments.accessibilityLabel", value: "%@ comments", comment: "Accessibility label showing total number of comments"), viewModel.commentCount.description)
            return "\(label). \(count)."
        }()
        buttons.like.accessibilityLabel = {
            let label = viewModel.isLiked ? NSLocalizedString("reader.post.buttonRemoveLike.accessibilityLabel", value: "Remove like", comment: "Button accessibility label") : NSLocalizedString("reader.post.buttonLike.accessibilityLabel", value: "Like", comment: "Button accessibility label")
            let count = String(format: NSLocalizedString("reader.post.numberOfLikes.accessibilityLabel", value: "%@ likes", comment: "Accessibility label showing total number of likes"), viewModel.likeCount.description)
            return "\(label). \(count)."
        }()
    }
}

// MARK: - Previews

@available(iOS 17, *)
#Preview {
    let cell = ReaderPostCellView()
    cell.configure(with: .mock())
    cell.isCompact = true

    let vc = UIViewController()
    vc.view.addSubview(cell)
    cell.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
        cell.leadingAnchor.constraint(equalTo: vc.view.leadingAnchor, constant: cell.isCompact ? 0 : 128),
        cell.trailingAnchor.constraint(equalTo: vc.view.trailingAnchor, constant: cell.isCompact ? 0 : -128),
        cell.centerYAnchor.constraint(equalTo: vc.view.centerYAnchor)
    ])
    cell.layer.borderColor = UIColor.separator.cgColor
    cell.layer.borderWidth = 0.5

    return vc
}
