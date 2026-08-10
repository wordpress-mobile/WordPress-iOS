import UIKit
import AsyncImageKit
import DesignSystem
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
    }

    public weak var delegate: ReaderPostHeaderViewDelegate?

    // MARK: - ViewModel

    public struct ViewModel {
        public let siteName: String?
        public let postTitle: String
        public let authorName: String
        public let authorAvatarURL: URL?
        public let dateString: String?
        public let featuredImageURL: URL?
        public let featuredImageHost: MediaHostProtocol?
        public let excerpt: String?

        public init(
            siteName: String? = nil,
            postTitle: String,
            authorName: String,
            authorAvatarURL: URL? = nil,
            dateString: String?,
            featuredImageURL: URL? = nil,
            featuredImageHost: MediaHostProtocol? = nil,
            excerpt: String? = nil
        ) {
            self.siteName = siteName
            self.postTitle = postTitle
            self.authorName = authorName
            self.authorAvatarURL = authorAvatarURL
            self.dateString = dateString
            self.featuredImageURL = featuredImageURL
            self.featuredImageHost = featuredImageHost
            self.excerpt = excerpt
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

    public let buttonSubscribe: UIButton = {
        var config = UIButton.Configuration.plain()
        config.imagePadding = 8 // This sets padding for the built-in loading indicator

        let button = UIButton(configuration: config)
        button.maximumContentSizeCategory = .extraExtraExtraLarge
        button.setContentHuggingPriority(.required, for: .horizontal)
        button.setContentCompressionResistancePriority(.required, for: .horizontal)
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
        label.isUserInteractionEnabled = true
        label.isHidden = true
        return label
    }()

    private let separator = SeparatorView.horizontal(height: 1)

    // Stacks

    private lazy var headerRow: UIView = {
        let containerView = UIView()
        containerView.addSubview(siteNameLabel)
        containerView.addSubview(buttonSubscribe)

        siteNameLabel.pinEdges([.leading, .vertical])
        siteNameLabel.trailingAnchor.constraint(equalTo: buttonSubscribe.leadingAnchor, constant: -8).isActive = true

        buttonSubscribe.pinEdges(.trailing)
        buttonSubscribe.centerYAnchor.constraint(equalTo: siteNameLabel.centerYAnchor).isActive = true

        // Site name shrinks first
        buttonSubscribe.setContentCompressionResistancePriority(.init(999), for: .horizontal)

        return containerView
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

    private lazy var mainStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [
            headerRow,
            titleLabel,
            authorRow,
            featuredImageView,
            excerptLabel,
            separator,
        ])
        stack.setCustomSpacing(9, after: separator)
        stack.axis = .vertical
        stack.spacing = 12
        return stack
    }()

    private var featuredImageAspectConstraint: NSLayoutConstraint?
    private var avatarSizeConstraints: [NSLayoutConstraint] = []
    private var displaySettings: ReaderDisplaySettings = .standard
    private var fullExcerptText: String?
    private var isExcerptExpanded = false
    private var lastExcerptLayoutWidth: CGFloat = 0

    public var isSubscribed: Bool = false {
        didSet {
            guard isSubscribed != oldValue else { return }
            updateSubscribeButtonAppearance()
        }
    }

    public var isShowingSubscribeLoadingIndicator: Bool = false {
        didSet {
            guard isShowingSubscribeLoadingIndicator != oldValue else { return }
            buttonSubscribe.isEnabled = !isShowingSubscribeLoadingIndicator
            buttonSubscribe.configuration?.showsActivityIndicator = isShowingSubscribeLoadingIndicator
        }
    }

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
        dateLabel.isHidden = viewModel.dateString == nil
        authorRow.accessibilityLabel = [viewModel.authorName, viewModel.dateString]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: ", ")

        if let avatarURL = viewModel.authorAvatarURL {
            avatarImageView.wp.setImage(with: avatarURL)
        } else {
            avatarImageView.image = nil
        }

        mainStack.setCustomSpacing(viewModel.featuredImageURL != nil ? 18 : 12, after: authorRow)

        configureFeaturedImage(with: viewModel.featuredImageURL, host: viewModel.featuredImageHost)
        configureExcerpt(with: viewModel.excerpt)
    }

    public func apply(_ displaySettings: ReaderDisplaySettings) {
        self.displaySettings = displaySettings

        let colors = displaySettings.color

        siteNameLabel.font = displaySettings.font(with: .subheadline)
        siteNameLabel.textColor = colors.secondaryForeground

        titleLabel.font = displaySettings.font(with: .title1, weight: .bold)
        titleLabel.textColor = colors.foreground
        titleLabel.tintColor = colors.foreground

        avatarImageView.layer.borderColor = colors.foreground.withAlphaComponent(0.1).cgColor

        authorNameLabel.font = displaySettings.font(with: .footnote, weight: .semibold)
        authorNameLabel.textColor = colors.foreground

        dateLabel.font = displaySettings.font(with: .footnote)
        dateLabel.textColor = colors.secondaryForeground

        excerptLabel.font = displaySettings.font(with: .callout)
        excerptLabel.textColor = colors.secondaryForeground

        buttonSubscribe.configuration?.baseForegroundColor = colors.secondaryForeground
        updateSubscribeButtonAppearance()

        separator.backgroundColor = colors.border

        lastExcerptLayoutWidth = 0
        updateExcerptText()
    }

    // MARK: - Private

    private func setupView() {
        addSubview(mainStack)
        mainStack.pinEdges(insets: UIEdgeInsets(top: Constants.padding, left: Constants.padding, bottom: 20, right: Constants.padding))

        mainStack.setCustomSpacing(9, after: headerRow)
        mainStack.setCustomSpacing(12, after: featuredImageView)

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
        siteNameLabel.accessibilityTraits = .button
        siteNameLabel.accessibilityHint = Strings.siteAccessibilityHint

        buttonSubscribe.addTarget(self, action: #selector(subscribeTapped), for: .touchUpInside)

        authorRow.isUserInteractionEnabled = true
        authorRow.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(authorTapped)))
        authorRow.isAccessibilityElement = true
        authorRow.accessibilityTraits = .button
        authorRow.accessibilityHint = Strings.authorAccessibilityHint

        excerptLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(excerptTapped)))

        featuredImageView.isUserInteractionEnabled = true
        featuredImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(featuredImageTapped)))

        apply(.standard)
    }

    public override func layoutSubviews() {
        super.layoutSubviews()

        let width = mainStack.bounds.width
        if width > 0 && width != lastExcerptLayoutWidth {
            lastExcerptLayoutWidth = width
            updateExcerptTruncation()
        }
    }

    // Extends tap area of the controls.
    public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let expandedViews: [UIView] = [buttonSubscribe, siteNameLabel, authorRow, featuredImageView]
        for view in expandedViews where !view.isHidden {
            let converted = convert(point, to: view)
            if view.bounds.insetBy(dx: -8, dy: -8).contains(converted) {
                return view
            }
        }
        return super.hitTest(point, with: event)
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

    @objc private func excerptTapped() {
        guard !isExcerptExpanded, fullExcerptText != nil else { return }
        isExcerptExpanded = true
        updateExcerptText()
    }

    private func updateExcerptText() {
        if isExcerptExpanded, let text = fullExcerptText {
            let font = displaySettings.font(with: .callout)
            let textColor = displaySettings.color.secondaryForeground
            excerptLabel.attributedText = NSAttributedString(string: text, attributes: [.font: font, .foregroundColor: textColor])
        } else {
            updateExcerptTruncation()
        }
    }

    @objc private func featuredImageTapped() {
        delegate?.readerPostHeaderView(self, didTap: .featuredImage)
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
        headerRow.isHidden = siteNameLabel.isHidden
    }

    private func configureFeaturedImage(with url: URL?, host: MediaHostProtocol?) {
        guard let url else {
            featuredImageView.isHidden = true
            return
        }

        featuredImageView.isHidden = false
        updateFeaturedImageAspectRatio(Constants.defaultFeaturedImageAspectRatio)

        featuredImageView.setImage(with: ImageRequest(url: url, host: host)) { [weak self] result in
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
            if excerpt != fullExcerptText {
                isExcerptExpanded = false
            }
            fullExcerptText = excerpt
            excerptLabel.isHidden = false
            lastExcerptLayoutWidth = 0
            updateExcerptText()
        } else {
            fullExcerptText = nil
            isExcerptExpanded = false
            excerptLabel.isHidden = true
        }
    }

    private func updateExcerptTruncation() {
        guard let text = fullExcerptText, !text.isEmpty, !isExcerptExpanded else { return }

        let font = displaySettings.font(with: .callout)
        let textColor = displaySettings.color.secondaryForeground
        let atttributes: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: textColor]
        let availableWidth = mainStack.bounds.width

        guard availableWidth > 0 else {
            excerptLabel.attributedText = NSAttributedString(string: text, attributes: atttributes)
            return
        }

        let maxHeight = font.lineHeight * CGFloat(Constants.excerptMaxLines) + 1

        func isEnoughSpace(for string: String, maxHeight: CGFloat) -> Bool {
            let height = (string as NSString).boundingRect(
                with: CGSize(width: availableWidth, height: .greatestFiniteMagnitude),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                attributes: atttributes,
                context: nil
            ).height
            return height <= maxHeight
        }

        // Hide under the cut only if there is enough text to warrant it. If there is only one extra
        // line, there is no reason to cut it.
        if isEnoughSpace(for: text, maxHeight: maxHeight + font.leading * 1) {
            excerptLabel.attributedText = NSAttributedString(string: text, attributes: atttributes)
            return
        }

        let suffix = " " + Strings.viewMore

        // Find the longest prefix that fits with the suffix.
        var low = 0, high = text.count, bestCut = 0
        while low <= high {
            let mid = (low + high) / 2
            if isEnoughSpace(for: String(text.prefix(mid)) + suffix, maxHeight: maxHeight) {
                bestCut = mid
                low = mid + 1
            } else {
                high = mid - 1
            }
        }

        let trimmed = String(text.prefix(bestCut)).trimmingCharacters(in: .whitespacesAndNewlines)
        let result = NSMutableAttributedString(string: trimmed, attributes: atttributes)
        result.append(
            NSAttributedString(string: suffix, attributes: [
                .font: font.withWeight(.regular),
                .foregroundColor: displaySettings.color.foreground,
            ])
        )
        excerptLabel.attributedText = result
    }

    private func updateSubscribeButtonAppearance() {
        let subscribeFont = displaySettings.font(with: .subheadline, weight: .medium)
        let colors = displaySettings.color

        if isSubscribed {
            // Show "Subscribed" with clear background (current design)
            buttonSubscribe.configuration?.attributedTitle = AttributedString(
                Strings.subscribed,
                attributes: AttributeContainer([.font: subscribeFont])
            )
            buttonSubscribe.configuration?.baseForegroundColor = colors.secondaryForeground
        } else {
            // Show "Subscribe" with black background to stand out
            buttonSubscribe.configuration?.attributedTitle = AttributedString(
                Strings.subscribe,
                attributes: AttributeContainer([.font: subscribeFont])
            )
            buttonSubscribe.configuration?.baseForegroundColor = UIAppColor.primary
        }
    }
}

// MARK: - Constants

private extension ReaderPostHeaderView {
    enum Constants {
        static let padding: CGFloat = 16
        static let avatarSize: CGFloat = 32
        static let avatarSizeRegular: CGFloat = 40
        static let excerptMaxLines: Int = 5
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

    static let subscribed = AppLocalizedString(
        "reader.post.header.subscribed",
        value: "Subscribed",
        comment: "Button in the reader post header showing the user is subscribed to the site"
    )

    static let viewMore = AppLocalizedString(
        "reader.post.header.viewMore",
        value: "\u{2026}view more",
        comment: "Appended to the truncated excerpt in the reader post header to indicate more content is available"
    )

    static let siteAccessibilityHint = AppLocalizedString(
        "reader.post.header.site.a11yHint",
        value: "Views posts from the site",
        comment: "Accessibility hint for the site name in the reader post header. Tapping it shows the site's posts."
    )

    static let authorAccessibilityHint = AppLocalizedString(
        "reader.post.header.author.a11yHint",
        value: "Views the author's profile",
        comment: "Accessibility hint for the author row in the reader post header. Tapping it shows the author's profile."
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
        excerpt: "Based in a small city in Northern Spain, Cinta Arribas is an illustrator and visual artist with over ten years of professional experience. She studied Fine Arts in Salamanca and Kassel (Germany), and recently completed an artist residency in Washington, DC, through a program of the Spanish Embassy."
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
        excerpt: "Based in a small city in Northern Spain, Cinta Arribas is an illustrator and visual artist with over ten years of professional experience. She studied Fine Arts in Salamanca and Kassel (Germany), and recently completed an artist residency in Washington, DC, through a program of the Spanish Embassy."
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
        featuredImageURL: URL(string: "https://automattic.design/wp-content/uploads/2025/12/a8ch25_zoom-bg-1.png?w=1024")
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
        excerpt: "Based in a small city in Northern Spain, Cinta Arribas is an illustrator and visual artist with over ten years of professional experience. She studied Fine Arts in Salamanca and Kassel (Germany), and recently completed an artist residency in Washington, DC, through a program of the Spanish Embassy. Her work has been featured in numerous publications and exhibitions across Europe and the Americas. She specializes in editorial illustration, children's books, and cultural event posters, bringing a unique blend of traditional and contemporary techniques to every project she undertakes."
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
        excerpt: "Based in a small city in Northern Spain, Cinta Arribas is an illustrator and visual artist with over ten years of professional experience."
    )))
}

@available(iOS 17, *)
#Preview("Minimal") {
    UINavigationController(rootViewController: ReaderPostHeaderPreviewController(viewModel: .init(
        siteName: "Blog",
        postTitle: "Hello World",
        authorName: "admin",
        authorAvatarURL: URL(string: "https://picsum.photos/id/237/120/120.jpg"),
        dateString: "Mar 1, 2026"
    )))
}
