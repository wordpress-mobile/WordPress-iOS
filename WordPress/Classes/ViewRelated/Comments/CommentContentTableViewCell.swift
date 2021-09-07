import UIKit

class CommentContentTableViewCell: UITableViewCell, NibReusable {

    // all the available images for the accessory button.
    enum AccessoryButtonType {
        case share
        case ellipsis
    }

    // MARK: - Public Properties

    var accessoryButtonAction: (() -> Void)? = nil

    /// Called when the cell has finished loading and calculating the height of the HTML content. Passes the new content height as parameter.
    var onContentLoaded: ((CGFloat) -> Void)? = nil

    var replyButtonAction: (() -> Void)? = nil

    var likeButtonAction: (() -> Void)? = nil

    /// Encapsulate the accessory button image assignment through an enum, to apply a standardized image configuration.
    /// See `accessoryIconConfiguration` in `WPStyleGuide+CommentDetail`.
    var accessoryButtonType: AccessoryButtonType = .share {
        didSet {
            accessoryButton.setImage(accessoryButtonImage, for: .normal)
        }
    }

    // MARK: Outlets

    @IBOutlet private weak var avatarImageView: CircularImageView!
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var dateLabel: UILabel!
    @IBOutlet private weak var accessoryButton: UIButton!

    @IBOutlet private weak var webView: WKWebView!
    @IBOutlet private weak var webViewHeightConstraint: NSLayoutConstraint!

    @IBOutlet private weak var reactionBarView: UIView!
    @IBOutlet private weak var replyButton: UIButton!
    @IBOutlet private weak var likeButton: UIButton!

    /// Cache the HTML template format. We only need read the template once.
    private static let htmlTemplateFormat: String? = {
        guard let templatePath = Bundle.main.path(forResource: "richCommentTemplate", ofType: "html"),
              let templateString = try? String(contentsOfFile: templatePath) else {
            return nil
        }

        return templateString
    }()

    /// Caches the HTML content, to be reused when the orientation changed.
    private var htmlContentCache: String? = nil

    // MARK: Lifecycle

    override func awakeFromNib() {
        super.awakeFromNib()
        configureViews()
    }

    override func prepareForReuse() {
        onContentLoaded = nil
        htmlContentCache = nil
    }

    // MARK: Public Methods

    /// Configures the cell with a `Comment` object.
    ///
    /// - Parameters:
    ///   - comment: The `Comment` object to display.
    ///   - onContentLoaded: Callback to be called once the content has been loaded. Provides the new content height as parameter.
    func configure(with comment: Comment, onContentLoaded: ((CGFloat) -> Void)?) {
        nameLabel?.setText(comment.authorForDisplay())
        dateLabel?.setText(comment.dateForDisplay()?.toMediumString() ?? String())

        if let avatarURL = URL(string: comment.authorAvatarURL) {
            configureImage(with: avatarURL)
        } else {
            configureImageWithGravatarEmail(comment.gravatarEmailForDisplay())
        }

        updateLikeButton(liked: comment.isLiked, numberOfLikes: comment.numberOfLikes())

        // configure comment content
        guard let templateFormat = Self.htmlTemplateFormat else {
            return
        }

        self.onContentLoaded = onContentLoaded

        // remove empty HTML elements from the `content`, as the content often contains empty paragraph elements which adds unnecessary padding/margin.
        // `rawContent` does not have this problem, but it's not used because `rawContent` gets rid of links (<a> tags) for mentions.
        let sanitizedContent = comment.content
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: String.emptyElementRegexPattern, with: String(), options: [.regularExpression])
        let htmlString = String(format: templateFormat, sanitizedContent)

        self.htmlContentCache = htmlString
        webView.loadHTMLString(htmlString, baseURL: nil)

        // TODO: Configure component visibility
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        // when screen orientation changed, reload the HTML content to ensure that the content height accounts for the new width.
        guard let cachedContent = htmlContentCache,
           traitCollection.verticalSizeClass != previousTraitCollection?.verticalSizeClass
            || traitCollection.horizontalSizeClass != previousTraitCollection?.horizontalSizeClass else {
            return
        }

        webViewHeightConstraint.constant = 1
        webView.loadHTMLString(cachedContent, baseURL: nil)
    }
}

// MARK: - WKNavigationDelegate

extension CommentContentTableViewCell: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // Wait until the HTML document finished loading.
        // This also waits for all of resources within the HTML (images, video thumbnail images) to be fully loaded.
        webView.evaluateJavaScript("document.readyState") { complete, _ in
            guard complete != nil else {
                return
            }

            // To capture the content height, the methods to use is either `document.body.scrollHeight` or `document.documentElement.scrollHeight`.
            // `document.body` does not capture margins on <body> tag, so we'll use `document.documentElement` instead.
            webView.evaluateJavaScript("document.documentElement.scrollHeight") { height, _ in
                guard let height = height as? CGFloat else {
                    return
                }
                // update the web view height obtained from the evaluated Javascript.
                self.webViewHeightConstraint.constant = height
                self.onContentLoaded?(height)
            }
        }
    }
}

// MARK: - Helpers

private extension CommentContentTableViewCell {
    typealias Style = WPStyleGuide.CommentDetail.Content

    var accessoryButtonImage: UIImage? {
        switch accessoryButtonType {
        case .share:
            return .init(systemName: Style.shareIconImageName, withConfiguration: Style.accessoryIconConfiguration)
        case .ellipsis:
            return .init(systemName: Style.ellipsisIconImageName, withConfiguration: Style.accessoryIconConfiguration)
        }
    }

    // assign base styles for all the cell components.
    func configureViews() {
        selectionStyle = .none

        nameLabel?.font = Style.nameFont
        nameLabel?.textColor = Style.nameTextColor

        dateLabel?.font = Style.dateFont
        dateLabel?.textColor = Style.dateTextColor

        accessoryButton?.tintColor = Style.buttonTintColor
        accessoryButton?.setImage(accessoryButtonImage, for: .normal)
        accessoryButton?.addTarget(self, action: #selector(accessoryButtonTapped), for: .touchUpInside)

        webView.navigationDelegate = self
        webView.scrollView.bounces = false
        webView.scrollView.contentInset = .zero
        webView.scrollView.showsVerticalScrollIndicator = false
        webView.backgroundColor = .clear
        webView.isOpaque = false // gets rid of the white flash upon content load in dark mode.

        replyButton?.tintColor = Style.buttonTintColor
        replyButton?.titleLabel?.font = Style.reactionButtonFont
        replyButton?.setTitle(.reply, for: .normal)
        replyButton?.setTitleColor(Style.reactionButtonTextColor, for: .normal)
        replyButton?.setImage(Style.replyIconImage, for: .normal)
        replyButton?.addTarget(self, action: #selector(replyButtonTapped), for: .touchUpInside)

        likeButton?.titleLabel?.font = Style.reactionButtonFont
        likeButton?.setTitleColor(Style.reactionButtonTextColor, for: .normal)
        likeButton?.addTarget(self, action: #selector(likeButtonTapped), for: .touchUpInside)
        updateLikeButton(liked: false, numberOfLikes: 0)
    }

    /// Configures the avatar image view with the provided URL.
    /// If the URL does not contain any image, the default placeholder image will be displayed.
    /// - Parameter url: The URL containing the image.
    func configureImage(with url: URL?) {
        if let someURL = url, let gravatar = Gravatar(someURL) {
            avatarImageView.downloadGravatar(gravatar, placeholder: Style.placeholderImage, animate: true)
            return
        }

        // handle non-gravatar images
        avatarImageView.downloadImage(from: url, placeholderImage: Style.placeholderImage)
    }

    /// Configures the avatar image view from Gravatar based on provided email.
    /// If the Gravatar image for the provided email doesn't exist, the default placeholder image will be displayed.
    /// - Parameter gravatarEmail: The email to be used for querying the Gravatar image.
    func configureImageWithGravatarEmail(_ email: String?) {
        guard let someEmail = email else {
            return
        }

        avatarImageView.downloadGravatarWithEmail(someEmail, placeholderImage: Style.placeholderImage)
    }

    func likeButtonTitle(for numberOfLikes: Int) -> String {
        switch numberOfLikes {
        case .zero:
            return .noLikes
        case 1:
            return String(format: .singularLikeFormat, numberOfLikes)
        default:
            return String(format: .pluralLikesFormat, numberOfLikes)
        }
    }

    func updateLikeButton(liked: Bool, numberOfLikes: Int) {
        likeButton.tintColor = liked ? Style.likedTintColor : Style.buttonTintColor
        likeButton.setImage(liked ? Style.likedIconImage : Style.unlikedIconImage, for: .normal)
        likeButton.setTitle(likeButtonTitle(for: numberOfLikes), for: .normal)
    }

    @objc func accessoryButtonTapped() {
        accessoryButtonAction?()
    }

    @objc func replyButtonTapped() {
        replyButtonAction?()
    }

    @objc func likeButtonTapped() {
        likeButtonAction?()
    }
}

// MARK: - Localization

private extension String {
    static let reply = NSLocalizedString("Reply", comment: "Reply to a comment.")
    static let noLikes = NSLocalizedString("Like", comment: "Button title to Like a comment.")
    static let singularLikeFormat = NSLocalizedString("%1$d Like", comment: "Singular button title to Like a comment. "
                                                        + "%1$d is a placeholder for the number of Likes.")
    static let pluralLikesFormat = NSLocalizedString("%1$d Likes", comment: "Plural button title to Like a comment. "
                                                + "%1$d is a placeholder for the number of Likes.")

    // pattern that detects empty HTML elements (including HTML comments within).
    static let emptyElementRegexPattern = "<[a-z]+>(<!-- [a-z\\/:]+ -->)+<\\/[a-z]+>"
}
