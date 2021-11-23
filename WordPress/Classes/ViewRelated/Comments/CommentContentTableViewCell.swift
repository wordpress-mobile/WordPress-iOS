import UIKit

class CommentContentTableViewCell: UITableViewCell, NibReusable {

    // all the available images for the accessory button.
    enum AccessoryButtonType {
        case share
        case ellipsis
    }

    // MARK: - Public Properties

    /// A closure that's called when the accessory button is tapped.
    /// The button's view is sent as the closure's parameter for reference.
    var accessoryButtonAction: ((UIView) -> Void)? = nil

    var replyButtonAction: (() -> Void)? = nil

    var likeButtonAction: (() -> Void)? = nil

    var contentLinkTapAction: ((URL) -> Void)? = nil

    /// When set to true, the cell will always hide the moderation bar regardless of the user's moderating capabilities.
    var hidesModerationBar: Bool = false {
        didSet {
            updateModerationBarVisibility()
        }
    }

    /// Encapsulate the accessory button image assignment through an enum, to apply a standardized image configuration.
    /// See `accessoryIconConfiguration` in `WPStyleGuide+CommentDetail`.
    var accessoryButtonType: AccessoryButtonType = .share {
        didSet {
            accessoryButton.setImage(accessoryButtonImage, for: .normal)
        }
    }

    // MARK: Constants

    private let customBottomSpacing: CGFloat = 10

    // MARK: Outlets

    @IBOutlet private weak var containerStackView: UIStackView!
    @IBOutlet private weak var containerStackBottomConstraint: NSLayoutConstraint!

    @IBOutlet private weak var avatarImageView: CircularImageView!
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var dateLabel: UILabel!
    @IBOutlet private weak var accessoryButton: UIButton!

    @IBOutlet private weak var webView: WKWebView!
    @IBOutlet private weak var webViewHeightConstraint: NSLayoutConstraint!

    @IBOutlet private weak var reactionBarView: UIView!
    @IBOutlet private weak var replyButton: UIButton!
    @IBOutlet private weak var likeButton: UIButton!

    // This is public so its delegate can be set directly.
    @IBOutlet private(set) weak var moderationBar: CommentModerationBar!

    // MARK: Private Properties

    /// Called when the cell has finished loading and calculating the height of the HTML content. Passes the new content height as parameter.
    private var onContentLoaded: ((CGFloat) -> Void)? = nil

    /// Cache the HTML template format. We only need read the template once.
    private static let htmlTemplateFormat: String? = {
        guard let templatePath = Bundle.main.path(forResource: "richCommentTemplate", ofType: "html"),
              let templateString = try? String(contentsOfFile: templatePath) else {
            return nil
        }

        return templateString
    }()

    /// Used for the web view's `baseURL`, to reference any local files (i.e. CSS) linked from the HTML.
    private static let resourceURL: URL? = {
        Bundle.main.resourceURL
    }()

    /// Used to determine whether the cache is still valid or not.
    private var commentContentCache: String? = nil

    /// Caches the HTML content, to be reused when the orientation changed.
    private var htmlContentCache: String? = nil

    // MARK: Like Button State

    private var isLiked: Bool = false

    private var likeCount: Int = 0

    private var isLikeButtonAnimating: Bool = false

    // MARK: Visibility Control

    /// Controls the visibility of the reaction bar view. Setting this to false disables Reply and Likes functionality.
    private var isReactionEnabled: Bool = false {
        didSet {
            reactionBarView.isHidden = !isReactionEnabled
        }
    }

    private var isCommentLikesEnabled: Bool = false {
        didSet {
            likeButton.isHidden = !isCommentLikesEnabled
        }
    }

    private var isAccessoryButtonEnabled: Bool = false {
        didSet {
            accessoryButton.isHidden = !isAccessoryButtonEnabled
        }
    }

    /// Controls the visibility of the moderation bar view.
    private var isModerationEnabled: Bool = false {
        didSet {
            updateModerationBarVisibility()
        }
    }

    // MARK: Lifecycle

    override func awakeFromNib() {
        super.awakeFromNib()
        configureViews()
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

        // Configure feature availability.
        isReactionEnabled = !comment.isReadOnly()
        isCommentLikesEnabled = isReactionEnabled && (comment.blog?.supports(.commentLikes) ?? false)
        isAccessoryButtonEnabled = comment.isApproved()
        isModerationEnabled = comment.allowsModeration()

        // When reaction bar is hidden, add some space between the webview and the moderation bar.
        containerStackView.setCustomSpacing(isReactionEnabled ? 0 : customBottomSpacing, after: webView)

        // When both reaction bar and moderation bar is hidden, the custom spacing for the webview won't be applied since it's at the bottom of the stack view.
        // The reaction bar and the moderation bar have their own spacing, unlike the webview. Therefore, additional bottom spacing is needed.
        containerStackBottomConstraint.constant = (isReactionEnabled || isModerationEnabled) ? 0 : customBottomSpacing

        if isModerationEnabled {
            moderationBar.commentStatus = CommentStatusType.typeForStatus(comment.status)
        }

        // optimize: do not reload if the content doesn't change.
        if let contentCache = commentContentCache, contentCache == comment.content {
            return
        }

        // Configure comment content.
        self.onContentLoaded = onContentLoaded
        webViewHeightConstraint.constant = 1 // reset webview height to handle cases where the new content requires the webview to shrink.
        webView.isOpaque = false // gets rid of the white flash upon content load in dark mode.
        webView.loadHTMLString(formattedHTMLString(for: comment.content), baseURL: Self.resourceURL)
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

                // reset the webview to opaque again so the scroll indicator is visible.
                webView.isOpaque = true

                // update the web view height obtained from the evaluated Javascript.
                self.webViewHeightConstraint.constant = height
                self.onContentLoaded?(height)
            }
        }
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        switch navigationAction.navigationType {
        case .other:
            // allow local file requests.
            decisionHandler(.allow)
        default:
            decisionHandler(.cancel)
            guard let destinationURL = navigationAction.request.url,
                  let linkTapAction = contentLinkTapAction else {
                      return
                  }
            linkTapAction(destinationURL)
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

    var likeButtonTitle: String {
        switch likeCount {
        case .zero:
            return .noLikes
        case 1:
            return String(format: .singularLikeFormat, likeCount)
        default:
            return String(format: .pluralLikesFormat, likeCount)
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
        webView.scrollView.showsVerticalScrollIndicator = false

        replyButton?.tintColor = Style.buttonTintColor
        replyButton?.titleLabel?.font = Style.reactionButtonFont
        replyButton?.titleLabel?.adjustsFontSizeToFitWidth = true
        replyButton?.titleLabel?.adjustsFontForContentSizeCategory = true
        replyButton?.setTitle(.reply, for: .normal)
        replyButton?.setTitleColor(Style.reactionButtonTextColor, for: .normal)
        replyButton?.setImage(Style.replyIconImage, for: .normal)
        replyButton?.addTarget(self, action: #selector(replyButtonTapped), for: .touchUpInside)
        replyButton?.flipInsetsForRightToLeftLayoutDirection()
        replyButton?.adjustsImageSizeForAccessibilityContentSizeCategory = true

        likeButton?.titleLabel?.font = Style.reactionButtonFont
        likeButton?.titleLabel?.adjustsFontSizeToFitWidth = true
        likeButton?.titleLabel?.adjustsFontForContentSizeCategory = true
        likeButton?.setTitleColor(Style.reactionButtonTextColor, for: .normal)
        likeButton?.addTarget(self, action: #selector(likeButtonTapped), for: .touchUpInside)
        likeButton?.flipInsetsForRightToLeftLayoutDirection()
        likeButton?.adjustsImageSizeForAccessibilityContentSizeCategory = true
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

    /// Returns a formatted HTML string by loading the template for rich comment.
    ///
    /// The method will try to return cached content if possible, by detecting whether the content matches the previous content.
    /// If it's different (e.g. due to edits), it will reprocess the HTML string.
    ///
    /// - Parameter content: The content value from the `Comment` object.
    /// - Returns: Formatted HTML string to be displayed in the web view.
    ///
    func formattedHTMLString(for content: String) -> String {
        // return the previous HTML string if the comment content is unchanged.
        if let previousCommentContent = commentContentCache,
           let previousHTMLString = htmlContentCache,
           previousCommentContent == content {
            return previousHTMLString
        }

        // otherwise: sanitize the content, cache it, and then return it.
        guard let htmlTemplateFormat = Self.htmlTemplateFormat else {
            DDLogError("\(Self.classNameWithoutNamespaces()): Failed to load HTML template format for comment content.")
            return String()
        }

        // remove empty HTML elements from the `content`, as the content often contains empty paragraph elements which adds unnecessary padding/margin.
        // `rawContent` does not have this problem, but it's not used because `rawContent` gets rid of links (<a> tags) for mentions.
        let htmlContent = String(format: htmlTemplateFormat, content
                                    .replacingOccurrences(of: String.emptyElementRegexPattern, with: String(), options: [.regularExpression])
                                    .trimmingCharacters(in: .whitespacesAndNewlines))

        // cache the contents.
        commentContentCache = content
        htmlContentCache = htmlContent

        return htmlContent
    }

    func updateModerationBarVisibility() {
        moderationBar.isHidden = !isModerationEnabled || hidesModerationBar
    }

    /// Updates the style and text of the Like button.
    /// - Parameters:
    ///   - liked: Represents the target state – true if the comment is liked, or should be false otherwise.
    ///   - numberOfLikes: The number of likes to be displayed.
    ///   - animated: Whether the Like button state change should be animated or not. Defaults to false.
    ///   - completion: Completion block called once the animation is completed. Defaults to nil.
    func updateLikeButton(liked: Bool, numberOfLikes: Int, animated: Bool = false, completion: (() -> Void)? = nil) {
        guard !isLikeButtonAnimating else {
            return
        }

        isLiked = liked
        likeCount = numberOfLikes

        let onAnimationComplete = {
            self.likeButton.tintColor = liked ? Style.likedTintColor : Style.buttonTintColor
            self.likeButton.setImage(liked ? Style.likedIconImage : Style.unlikedIconImage, for: .normal)
            self.likeButton.setTitle(self.likeButtonTitle, for: .normal)
            completion?()
        }

        guard animated else {
            onAnimationComplete()
            return
        }

        isLikeButtonAnimating = true

        if isLiked {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }

        animateLikeButton {
            onAnimationComplete()
            self.isLikeButtonAnimating = false
        }
    }

    /// Animates the Like button state change.
    func animateLikeButton(completion: @escaping () -> Void) {
        guard let buttonImageView = likeButton.imageView,
              let overlayImage = Style.likedIconImage?.withTintColor(Style.likedTintColor) else {
                  completion()
                  return
              }

        let overlayImageView = UIImageView(image: overlayImage)
        overlayImageView.frame = likeButton.convert(buttonImageView.bounds, from: buttonImageView)
        likeButton.addSubview(overlayImageView)

        let animation = isLiked ? overlayImageView.fadeInWithRotationAnimation : overlayImageView.fadeOutWithRotationAnimation
        animation { _ in
            overlayImageView.removeFromSuperview()
            completion()
        }
    }

    @objc func accessoryButtonTapped() {
        accessoryButtonAction?(accessoryButton)
    }

    @objc func replyButtonTapped() {
        replyButtonAction?()
    }

    @objc func likeButtonTapped() {
        ReachabilityUtils.onAvailableInternetConnectionDo {
            updateLikeButton(liked: !isLiked, numberOfLikes: isLiked ? likeCount - 1 : likeCount + 1, animated: true) {
                self.likeButtonAction?()
            }
        }
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
    static let emptyElementRegexPattern = "<[a-z]+>(<!-- [a-zA-Z0-9\\/: \"{}\\-\\.,\\?=\\[\\]]+ -->)+<\\/[a-z]+>"
}
