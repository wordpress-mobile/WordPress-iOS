import UIKit
import AsyncImageKit
import WordPressShared
import WordPressUI

public protocol ReaderPostHeaderViewDelegate: AnyObject {
    func readerPostHeaderView(_ view: ReaderPostHeaderView, didTap element: ReaderPostHeaderView.Element)
}

public final class ReaderPostHeaderView: UIView {

    // MARK: - Types

    public enum Element {
        case siteName
        case subscribe
        case author
        case featuredImage
        case viewOriginal
    }

    public weak var delegate: ReaderPostHeaderViewDelegate?

    // MARK: - ViewModel

    public struct ViewModel {
        public let siteName: String?
        public let postTitle: String
        public let authorName: String
        public let authorAvatarURL: URL?
        public let dateString: String
        public let featuredImageURL: URL?
        public let excerpt: String?
        public let readingTime: String

        public init(
            siteName: String? = nil,
            postTitle: String,
            authorName: String,
            authorAvatarURL: URL? = nil,
            dateString: String,
            featuredImageURL: URL? = nil,
            excerpt: String? = nil,
            readingTime: String
        ) {
            self.siteName = siteName
            self.postTitle = postTitle
            self.authorName = authorName
            self.authorAvatarURL = authorAvatarURL
            self.dateString = dateString
            self.featuredImageURL = featuredImageURL
            self.excerpt = excerpt
            self.readingTime = readingTime
        }
    }

    // MARK: - Subviews

    private let siteNameLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.adjustsFontForContentSizeCategory = true
        label.maximumContentSizeCategory = .accessibilityMedium
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return label
    }()

    public let subscribeButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.contentInsets = NSDirectionalEdgeInsets(top: 4, leading: 12, bottom: 4, trailing: 12)
        config.cornerStyle = .capsule
        config.background.strokeWidth = 1
        let button = UIButton(configuration: config)
        button.maximumContentSizeCategory = .extraExtraExtraLarge
        button.setContentHuggingPriority(.required, for: .horizontal)
        button.setContentCompressionResistancePriority(.required, for: .horizontal)
        return button
    }()

    public let viewOriginalButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.contentInsets = .zero
        config.imagePadding = 4
        config.imagePlacement = .leading
        let button = UIButton(configuration: config)
        button.maximumContentSizeCategory = .extraExtraLarge
        button.setContentHuggingPriority(.required, for: .horizontal)
        return button
    }()

    private let titleLabel: UITextView = {
        let textView = UITextView()
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.backgroundColor = .clear
        textView.adjustsFontForContentSizeCategory = true
        return textView
    }()

    private let avatarImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = Constants.avatarSize / 2
        imageView.layer.borderWidth = 0.5
        imageView.backgroundColor = .tertiarySystemFill
        return imageView
    }()

    private let authorNameLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.adjustsFontForContentSizeCategory = true
        label.maximumContentSizeCategory = .accessibilityMedium
        return label
    }()

    private let dateLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.adjustsFontForContentSizeCategory = true
        label.maximumContentSizeCategory = .accessibilityMedium
        return label
    }()

    public let featuredImageView: AsyncImageView = {
        let imageView = AsyncImageView()
        imageView.configuration.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 6
        imageView.isHidden = true
        return imageView
    }()

    private let excerptLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        label.isHidden = true
        return label
    }()

    private let readingTimeLabel: UILabel = {
        let label = UILabel()
        label.adjustsFontForContentSizeCategory = true
        label.maximumContentSizeCategory = .extraExtraLarge
        return label
    }()

    private let readingTimeIcon: UIImageView = {
        let imageView = UIImageView()
        imageView.maximumContentSizeCategory = .extraExtraLarge
        imageView.setContentHuggingPriority(.required, for: .horizontal)
        imageView.setContentCompressionResistancePriority(.required, for: .horizontal)
        return imageView
    }()

    private let separator = SeparatorView.horizontal(height: 1)

    // Stacks

    private lazy var siteNameRow: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [siteNameLabel, subscribeButton, UIView()])
        stack.axis = .horizontal
        stack.alignment = .firstBaseline
        stack.spacing = 8
        return stack
    }()

    private lazy var authorTextStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [authorNameLabel, dateLabel])
        stack.axis = .vertical
        stack.spacing = 2
        return stack
    }()

    private lazy var authorRow: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [avatarImageView, authorTextStack])
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 8
        return stack
    }()

    private lazy var readingTimeStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [readingTimeIcon, readingTimeLabel])
        stack.axis = .horizontal
        stack.spacing = 4
        stack.alignment = .center
        return stack
    }()

    private lazy var footerRow: UIStackView = {
        let spacer = UIView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        let stack = UIStackView(arrangedSubviews: [readingTimeStack, spacer, viewOriginalButton])
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 8
        return stack
    }()

    private lazy var mainStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [
            siteNameRow,
            titleLabel,
            authorRow,
            featuredImageView,
            excerptLabel,
            separator,
            footerRow
        ])
        stack.axis = .vertical
        stack.spacing = 12
        return stack
    }()

    private var featuredImageAspectConstraint: NSLayoutConstraint?
    private var avatarSizeConstraints: [NSLayoutConstraint] = []
    private var displaySetting: ReaderDisplaySettings = .standard

    // MARK: - Init

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Configuration

    public func configure(with viewModel: ViewModel) {
        configureSiteName(with: viewModel.siteName)
        titleLabel.text = viewModel.postTitle
        authorNameLabel.text = viewModel.authorName
        dateLabel.text = viewModel.dateString

        if let avatarURL = viewModel.authorAvatarURL {
            avatarImageView.wp.setImage(with: avatarURL)
        } else {
            avatarImageView.image = nil
        }

        configureFeaturedImage(with: viewModel.featuredImageURL)
        configureExcerpt(with: viewModel.excerpt)
        configureReadingTime(with: viewModel.readingTime)
    }

    public func apply(_ displaySetting: ReaderDisplaySettings) {
        self.displaySetting = displaySetting

        let colors = displaySetting.color

        siteNameLabel.font = displaySetting.font(with: .subheadline)
        siteNameLabel.textColor = colors.secondaryForeground

        titleLabel.font = displaySetting.font(with: .title1, weight: .bold)
        titleLabel.textColor = colors.foreground
        titleLabel.tintColor = colors.foreground

        avatarImageView.layer.borderColor = colors.foreground.withAlphaComponent(0.1).cgColor

        authorNameLabel.font = displaySetting.font(with: .footnote, weight: .semibold)
        authorNameLabel.textColor = colors.foreground

        dateLabel.font = displaySetting.font(with: .footnote)
        dateLabel.textColor = colors.secondaryForeground

        excerptLabel.font = displaySetting.font(with: .callout)
        excerptLabel.textColor = colors.secondaryForeground

        readingTimeLabel.font = displaySetting.font(with: .footnote)
        readingTimeLabel.textColor = colors.secondaryForeground

        let iconConfig = UIImage.SymbolConfiguration(font: displaySetting.font(with: .caption1))
        readingTimeIcon.image = UIImage(systemName: "clock", withConfiguration: iconConfig)
        readingTimeIcon.tintColor = colors.secondaryForeground

        let subscribeFont = displaySetting.font(with: .footnote, weight: .medium)
        subscribeButton.configuration?.attributedTitle = AttributedString(
            Strings.subscribe,
            attributes: AttributeContainer([.font: subscribeFont])
        )
        subscribeButton.configuration?.baseForegroundColor = colors.secondaryForeground
        subscribeButton.configuration?.background.strokeColor = colors.secondaryForeground.withAlphaComponent(0.3)

        viewOriginalButton.configuration?.attributedTitle = AttributedString(
            Strings.viewOriginal,
            attributes: AttributeContainer([.font: displaySetting.font(with: .footnote)])
        )
        viewOriginalButton.configuration?.image = UIImage(systemName: "arrow.up.right.circle", withConfiguration: UIImage.SymbolConfiguration(font: displaySetting.font(with: .caption2)))
        viewOriginalButton.configuration?.baseForegroundColor = colors.secondaryForeground

        separator.backgroundColor = colors.border
    }

    // MARK: - Private

    private func setupView() {
        addSubview(mainStack)
        mainStack.pinEdges(insets: UIEdgeInsets(top: Constants.padding, left: Constants.padding, bottom: Constants.padding, right: Constants.padding))

        mainStack.setCustomSpacing(9, after: siteNameRow)
        mainStack.setCustomSpacing(18, after: authorRow)
        mainStack.setCustomSpacing(18, after: featuredImageView)

        avatarSizeConstraints = [
            avatarImageView.widthAnchor.constraint(equalToConstant: Constants.avatarSize),
            avatarImageView.heightAnchor.constraint(equalToConstant: Constants.avatarSize),
        ]
        NSLayoutConstraint.activate(avatarSizeConstraints)

        registerForTraitChanges([UITraitHorizontalSizeClass.self]) { (self: Self, _) in
            self.updateForSizeClass()
        }

        siteNameLabel.isUserInteractionEnabled = true
        siteNameLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(siteNameTapped)))

        subscribeButton.addTarget(self, action: #selector(subscribeTapped), for: .touchUpInside)

        authorRow.isUserInteractionEnabled = true
        authorRow.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(authorTapped)))

        featuredImageView.isUserInteractionEnabled = true
        featuredImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(featuredImageTapped)))

        viewOriginalButton.addTarget(self, action: #selector(viewOriginalTapped), for: .touchUpInside)

        apply(.standard)
    }

    @objc private func siteNameTapped() {
        delegate?.readerPostHeaderView(self, didTap: .siteName)
    }

    @objc private func subscribeTapped() {
        delegate?.readerPostHeaderView(self, didTap: .subscribe)
    }

    @objc private func authorTapped() {
        delegate?.readerPostHeaderView(self, didTap: .author)
    }

    @objc private func featuredImageTapped() {
        delegate?.readerPostHeaderView(self, didTap: .featuredImage)
    }

    @objc private func viewOriginalTapped() {
        delegate?.readerPostHeaderView(self, didTap: .viewOriginal)
    }

    private func updateForSizeClass() {
        let isRegular = traitCollection.horizontalSizeClass == .regular
        let avatarSize: CGFloat = isRegular ? Constants.avatarSizeRegular : Constants.avatarSize
        avatarImageView.layer.cornerRadius = avatarSize / 2
        avatarSizeConstraints.forEach { $0.constant = avatarSize }
        featuredImageView.layer.cornerRadius = isRegular ? 10 : 6
        mainStack.spacing = isRegular ? 16 : 12
    }

    private func configureSiteName(with siteName: String?) {
        if let siteName, !siteName.isEmpty {
            siteNameLabel.text = siteName
            siteNameLabel.isHidden = false
        } else {
            siteNameLabel.isHidden = true
        }
        siteNameRow.isHidden = siteNameLabel.isHidden && subscribeButton.isHidden
    }

    private func configureFeaturedImage(with url: URL?) {
        guard let url else {
            featuredImageView.isHidden = true
            return
        }

        featuredImageView.isHidden = false
        updateFeaturedImageAspectRatio(Constants.defaultFeaturedImageAspectRatio)

        featuredImageView.setImage(with: ImageRequest(url: url)) { [weak self] result in
            guard let self, case .success(let image) = result else { return }
            guard image.size.width > 0 else { return }
            let ratio = min(image.size.height / image.size.width, Constants.maxFeaturedImageAspectRatio)
            self.updateFeaturedImageAspectRatio(ratio)
        }
    }

    private func updateFeaturedImageAspectRatio(_ ratio: CGFloat) {
        featuredImageAspectConstraint?.isActive = false
        let constraint = featuredImageView.heightAnchor.constraint(equalTo: featuredImageView.widthAnchor, multiplier: ratio)
        constraint.isActive = true
        featuredImageAspectConstraint = constraint
    }

    private func configureExcerpt(with excerpt: String?) {
        if let excerpt, !excerpt.isEmpty {
            excerptLabel.text = excerpt
            excerptLabel.isHidden = false
        } else {
            excerptLabel.isHidden = true
        }
    }

    private func configureReadingTime(with readingTime: String) {
        readingTimeLabel.text = readingTime
    }
}

// MARK: - Constants

private extension ReaderPostHeaderView {
    enum Constants {
        static let padding: CGFloat = 16
        static let avatarSize: CGFloat = 32
        static let avatarSizeRegular: CGFloat = 40
        static let defaultFeaturedImageAspectRatio: CGFloat = 9.0 / 16.0
        static let maxFeaturedImageAspectRatio: CGFloat = 2.0
    }
}

private enum Strings {
    static let subscribe = AppLocalizedString(
        "reader.post.header.subscribe",
        value: "Subscribe",
        comment: "Button in the reader post header to subscribe to the site"
    )
    static let viewOriginal = AppLocalizedString(
        "reader.post.header.viewOriginal",
        value: "View Original",
        comment: "Button in the reader post header to view the original post in a browser"
    )
}

// MARK: - Preview

@available(iOS 17, *)
#Preview("Full Header") {
    UINavigationController(rootViewController: ReaderPostHeaderPreviewController(viewModel: .init(
        siteName: "Automattic Design",
        postTitle: "Drawing the holiday spirit — Interviewing Cinta Arribas",
        authorName: "Roosmarijn van Kessel",
        authorAvatarURL: URL(string: "https://picsum.photos/id/237/120/120.jpg"),
        dateString: "Dec 18, 2025 at 3:30 PM",
        featuredImageURL: URL(string: "https://automattic.design/wp-content/uploads/2025/12/a8ch25_zoom-bg-1.png?w=1024"),
        excerpt: "Based in a small city in Northern Spain, Cinta Arribas is an illustrator and visual artist with over ten years of professional experience. She studied Fine Arts in Salamanca and Kassel (Germany), and recently completed an artist residency in Washington, DC, through a program of the Spanish Embassy.",
        readingTime: "5 min read"
    )))
}

@available(iOS 17, *)
#Preview("No Featured Image") {
    UINavigationController(rootViewController: ReaderPostHeaderPreviewController(viewModel: .init(
        siteName: "Automattic Design",
        postTitle: "Drawing the holiday spirit — Interviewing Cinta Arribas",
        authorName: "Roosmarijn van Kessel",
        authorAvatarURL: URL(string: "https://picsum.photos/id/237/120/120.jpg"),
        dateString: "Dec 18, 2025 at 3:30 PM",
        excerpt: "Based in a small city in Northern Spain, Cinta Arribas is an illustrator and visual artist with over ten years of professional experience. She studied Fine Arts in Salamanca and Kassel (Germany), and recently completed an artist residency in Washington, DC, through a program of the Spanish Embassy.",
        readingTime: "5 min read"
    )))
}

@available(iOS 17, *)
#Preview("No Excerpt") {
    UINavigationController(rootViewController: ReaderPostHeaderPreviewController(viewModel: .init(
        siteName: "Automattic Design",
        postTitle: "Drawing the holiday spirit — Interviewing Cinta Arribas",
        authorName: "Roosmarijn van Kessel",
        authorAvatarURL: URL(string: "https://picsum.photos/id/237/120/120.jpg"),
        dateString: "Dec 18, 2025 at 3:30 PM",
        featuredImageURL: URL(string: "https://automattic.design/wp-content/uploads/2025/12/a8ch25_zoom-bg-1.png?w=1024"),
        readingTime: "3 min read"
    )))
}

@available(iOS 17, *)
#Preview("Long Excerpt") {
    UINavigationController(rootViewController: ReaderPostHeaderPreviewController(viewModel: .init(
        siteName: "Automattic Design",
        postTitle: "A Very Long Title That Spans Multiple Lines to Test How the Layout Handles Wrapping Text in the Header",
        authorName: "Roosmarijn van Kessel",
        authorAvatarURL: URL(string: "https://picsum.photos/id/237/120/120.jpg"),
        dateString: "Dec 18, 2025 at 3:30 PM",
        featuredImageURL: URL(string: "https://automattic.design/wp-content/uploads/2025/12/a8ch25_zoom-bg-1.png?w=1024"),
        excerpt: "Based in a small city in Northern Spain, Cinta Arribas is an illustrator and visual artist with over ten years of professional experience. She studied Fine Arts in Salamanca and Kassel (Germany), and recently completed an artist residency in Washington, DC, through a program of the Spanish Embassy. Her work has been featured in numerous publications and exhibitions across Europe and the Americas. She specializes in editorial illustration, children's books, and cultural event posters, bringing a unique blend of traditional and contemporary techniques to every project she undertakes.",
        readingTime: "12 min read"
    )))
}

@available(iOS 17, *)
#Preview("Portrait Image") {
    UINavigationController(rootViewController: ReaderPostHeaderPreviewController(viewModel: .init(
        siteName: "Automattic Design",
        postTitle: "Drawing the holiday spirit — Interviewing Cinta Arribas",
        authorName: "Roosmarijn van Kessel",
        authorAvatarURL: URL(string: "https://picsum.photos/id/237/120/120.jpg"),
        dateString: "Dec 18, 2025 at 3:30 PM",
        featuredImageURL: URL(string: "https://automattic.design/wp-content/uploads/2025/12/aecc_stars.png"),
        excerpt: "Based in a small city in Northern Spain, Cinta Arribas is an illustrator and visual artist with over ten years of professional experience.",
        readingTime: "5 min read"
    )))
}

@available(iOS 17, *)
#Preview("Minimal") {
    UINavigationController(rootViewController: ReaderPostHeaderPreviewController(viewModel: .init(
        siteName: "Blog",
        postTitle: "Hello World",
        authorName: "admin",
        authorAvatarURL: URL(string: "https://picsum.photos/id/237/120/120.jpg"),
        dateString: "Mar 1, 2026",
        readingTime: "1 min read"
    )))
}
