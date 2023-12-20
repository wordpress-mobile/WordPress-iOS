import UIKit

class CommentContentTableViewCell: UITableViewCell, NibReusable {

    // all the available images for the accessory button.
    enum AccessoryButtonType {
        case share
        case ellipsis
        case info
    }

    enum RenderMethod: Equatable {
        /// Uses WebKit to render the comment body.
        case web

        /// Uses WPRichContent to render the comment body.
        case richContent(NSAttributedString)
    }

    // MARK: - Public Properties

    /// A closure that's called when the accessory button is tapped.
    /// The button's view is sent as the closure's parameter for reference.
    @objc var accessoryButtonAction: ((UIView) -> Void)? = nil

    @objc var replyButtonAction: (() -> Void)? = nil

    @objc var likeButtonAction: (() -> Void)? = nil

    @objc var contentLinkTapAction: ((URL) -> Void)? = nil

    @objc weak var richContentDelegate: WPRichContentViewDelegate? = nil

    /// Encapsulate the accessory button image assignment through an enum, to apply a standardized image configuration.
    /// See `accessoryIconConfiguration` in `WPStyleGuide+CommentDetail`.
    var accessoryButtonType: AccessoryButtonType = .share {
        didSet {
            accessoryButton.setImage(accessoryButtonImage, for: .normal)
        }
    }

    /// When supplied with a non-empty string, the cell will show a badge label beside the name label.
    /// Note that the badge will be hidden when the title is nil or empty.
    var badgeTitle: String? = nil {
        didSet {
            let title: String = {
                if let title = badgeTitle {
                    return title.localizedUppercase
                }
                return String()
            }()

            badgeLabel.setText(title)
            badgeLabel.isHidden = title.isEmpty
            badgeLabel.updateConstraintsIfNeeded()
        }
    }

    override var indentationWidth: CGFloat {
        didSet {
            updateContainerLeadingConstraint()
        }
    }

    override var indentationLevel: Int {
        didSet {
            updateContainerLeadingConstraint()
        }
    }

    /// A custom highlight style for the cell that is more controllable than `isHighlighted`.
    /// Cell selection for this cell is disabled, and highlight style may be disabled based on the table view settings.
    @objc var isEmphasized: Bool = false {
        didSet {
            backgroundColor = isEmphasized ? Style.highlightedBackgroundColor : nil
            highlightBarView.backgroundColor = isEmphasized ? Style.highlightedBarBackgroundColor : .clear
        }
    }

    @objc var isReplyHighlighted: Bool = false {
        didSet {
            replyButton?.tintColor = isReplyHighlighted ? Style.highlightedReplyButtonTintColor : Style.reactionButtonTextColor
            replyButton?.setTitleColor(isReplyHighlighted ? Style.highlightedReplyButtonTintColor : Style.reactionButtonTextColor, for: .normal)
            replyButton?.setImage(isReplyHighlighted ? Style.highlightedReplyIconImage : Style.replyIconImage, for: .normal)
        }
    }

    // MARK: Constants

    private let customBottomSpacing: CGFloat = 10
    private let contentButtonsTopSpacing: CGFloat = 15

    // MARK: Outlets

    @IBOutlet private weak var containerStackView: UIStackView!
    @IBOutlet private weak var containerStackBottomConstraint: NSLayoutConstraint!

    @IBOutlet private weak var containerStackLeadingConstraint: NSLayoutConstraint!
    @IBOutlet private weak var containerStackTrailingConstraint: NSLayoutConstraint!
    private var defaultLeadingMargin: CGFloat = 0

    @IBOutlet private weak var avatarImageView: CircularImageView!
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var badgeLabel: BadgeLabel!
    @IBOutlet private weak var dateLabel: UILabel!
    @IBOutlet private(set) weak var accessoryButton: UIButton!

    @IBOutlet private weak var contentContainerView: UIView!
    @IBOutlet private weak var contentContainerHeightConstraint: NSLayoutConstraint!

    @IBOutlet private weak var replyButton: UIButton!
    @IBOutlet private weak var likeButton: UIButton!

    @IBOutlet private weak var highlightBarView: UIView!
    @IBOutlet private weak var separatorView: UIView!

    // MARK: Private Properties

    /// Called when the cell has finished loading and calculating the height of the HTML content. Passes the new content height as parameter.
    private var onContentLoaded: ((CGFloat) -> Void)? = nil

    private var renderer: CommentContentRenderer? = nil

    private var renderMethod: RenderMethod?

    // MARK: Like Button State

    private var isLiked: Bool = false

    private var likeCount: Int = 0

    private var isLikeButtonAnimating: Bool = false

    // MARK: Visibility Control

    private var isCommentReplyEnabled: Bool = false {
        didSet {
            replyButton.isHidden = !isCommentReplyEnabled
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

    private var isReactionBarVisible: Bool {
        return isCommentReplyEnabled || isCommentLikesEnabled
    }

    var shouldHideSeparator = false {
        didSet {
            separatorView.isHidden = shouldHideSeparator
        }
    }

    // MARK: Lifecycle

    override func prepareForReuse() {
        super.prepareForReuse()

        // reset all highlight states.
        isEmphasized = false
        isReplyHighlighted = false

        // reset all button actions.
        accessoryButtonAction = nil
        replyButtonAction = nil
        likeButtonAction = nil
        contentLinkTapAction = nil

        onContentLoaded = nil
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        configureViews()
    }

    // MARK: Public Methods

    /// Configures the cell with a `Comment` object.
    ///
    /// - Parameters:
    ///   - comment: The `Comment` object to display.
    ///   - renderMethod: Specifies how to display the comment body. See `RenderMethod`.
    ///   - onContentLoaded: Callback to be called once the content has been loaded. Provides the new content height as parameter.
    func configure(with comment: Comment, renderMethod: RenderMethod = .web, onContentLoaded: ((CGFloat) -> Void)?) {
        nameLabel?.setText(comment.authorForDisplay())
        dateLabel?.setText(comment.dateForDisplay()?.toMediumString() ?? String())

        // Always cancel ongoing image downloads, just in case. This is to prevent comment cells being displayed with the wrong avatar image,
        // likely resulting from previous download operation before the cell is reused.
        //
        // Note that when downloading an image, any ongoing operation will be cancelled in UIImageView+Networking.
        // This is more of a preventative step where the cancellation is made to happen as early as possible.
        //
        // Ref: https://github.com/wordpress-mobile/WordPress-iOS/issues/17972
        avatarImageView.cancelImageDownload()

        if let avatarURL = URL(string: comment.authorAvatarURL) {
            configureImage(with: avatarURL)
        } else {
            configureImageWithGravatarEmail(comment.gravatarEmailForDisplay())
        }

        updateLikeButton(liked: comment.isLiked, numberOfLikes: comment.numberOfLikes())

        // Configure feature availability.
        isCommentReplyEnabled = comment.canReply()
        isCommentLikesEnabled = comment.canLike()
        isAccessoryButtonEnabled = comment.isApproved()

        // When reaction bar is hidden, add some space between the webview and the moderation bar.
        containerStackView.setCustomSpacing(contentButtonsTopSpacing, after: contentContainerView)

        // Configure content renderer.
        self.onContentLoaded = onContentLoaded
        configureRendererIfNeeded(for: comment, renderMethod: renderMethod)
    }

    /// Configures the cell with a `Comment` object, to be displayed in the post details view.
    ///
    /// - Parameters:
    ///   - comment: The `Comment` object to display.
    ///   - onContentLoaded: Callback to be called once the content has been loaded. Provides the new content height as parameter.
    func configureForPostDetails(with comment: Comment, onContentLoaded: ((CGFloat) -> Void)?) {
        configure(with: comment, onContentLoaded: onContentLoaded)

        isCommentLikesEnabled = false
        isCommentReplyEnabled = false
        isAccessoryButtonEnabled = false

        containerStackLeadingConstraint.constant = 0
        containerStackTrailingConstraint.constant = 0
    }

    @objc func ensureRichContentTextViewLayout() {
        switch renderMethod {
        case .richContent:
            if let richContentTextView = contentContainerView.subviews.first as? WPRichContentView {
                richContentTextView.updateLayoutForAttachments()
            }
        default:
            return
        }
    }
}

// MARK: - CommentContentRendererDelegate

extension CommentContentTableViewCell: CommentContentRendererDelegate {
    func renderer(_ renderer: CommentContentRenderer, asyncRenderCompletedWithHeight height: CGFloat) {
        if renderMethod == .web {
            contentContainerHeightConstraint?.constant = height
        }
        onContentLoaded?(height)
    }

    func renderer(_ renderer: CommentContentRenderer, interactedWithURL url: URL) {
        contentLinkTapAction?(url)
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
        case .info:
            return .init(systemName: Style.infoIconImageName, withConfiguration: Style.accessoryIconConfiguration)
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
        // Store default margin for use in content layout.
        defaultLeadingMargin = containerStackLeadingConstraint.constant

        selectionStyle = .none

        nameLabel?.font = Style.nameFont
        nameLabel?.textColor = Style.nameTextColor

        badgeLabel?.font = Style.badgeFont
        badgeLabel?.textColor = Style.badgeTextColor
        badgeLabel?.backgroundColor = Style.badgeColor
        badgeLabel?.adjustsFontForContentSizeCategory = true
        badgeLabel?.adjustsFontSizeToFitWidth = true

        dateLabel?.font = Style.dateFont
        dateLabel?.textColor = Style.dateTextColor

        accessoryButton?.tintColor = Style.buttonTintColor
        accessoryButton?.setImage(accessoryButtonImage, for: .normal)
        accessoryButton?.addTarget(self, action: #selector(accessoryButtonTapped), for: .touchUpInside)

        replyButton?.tintColor = Style.reactionButtonTextColor
        replyButton?.titleLabel?.font = Style.reactionButtonFont
        replyButton?.titleLabel?.adjustsFontSizeToFitWidth = true
        replyButton?.titleLabel?.adjustsFontForContentSizeCategory = true
        replyButton?.setTitle(.reply, for: .normal)
        replyButton?.setTitleColor(Style.reactionButtonTextColor, for: .normal)
        replyButton?.setImage(Style.replyIconImage, for: .normal)
        replyButton?.addTarget(self, action: #selector(replyButtonTapped), for: .touchUpInside)
        replyButton?.flipInsetsForRightToLeftLayoutDirection()
        replyButton?.adjustsImageSizeForAccessibilityContentSizeCategory = true
        adjustImageAndTitleEdgeInsets(for: replyButton)
        replyButton?.sizeToFit()
        replyButton?.accessibilityIdentifier = .replyButtonAccessibilityId

        likeButton?.tintColor = Style.reactionButtonTextColor
        likeButton?.titleLabel?.font = Style.reactionButtonFont
        likeButton?.titleLabel?.adjustsFontSizeToFitWidth = true
        likeButton?.titleLabel?.adjustsFontForContentSizeCategory = true
        likeButton?.setTitleColor(Style.reactionButtonTextColor, for: .normal)
        likeButton?.addTarget(self, action: #selector(likeButtonTapped), for: .touchUpInside)
        likeButton?.flipInsetsForRightToLeftLayoutDirection()
        likeButton?.adjustsImageSizeForAccessibilityContentSizeCategory = true
        adjustImageAndTitleEdgeInsets(for: likeButton)
        updateLikeButton(liked: false, numberOfLikes: 0)
        likeButton?.sizeToFit()
        likeButton?.accessibilityIdentifier = .likeButtonAccessibilityId
    }

    private func adjustImageAndTitleEdgeInsets(for button: UIButton) {
        guard let imageSize = button.imageView?.frame.size, let titleSize = button.titleLabel?.frame.size else {
            return
        }

        let spacing: CGFloat = 3
        button.titleEdgeInsets = .init(top: 0, left: -titleSize.width, bottom: -(imageSize.height + spacing), right: 0)
        button.imageEdgeInsets = .init(top: -(titleSize.height + spacing), left: imageSize.width/2, bottom: 0, right: 0)
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

    func updateContainerLeadingConstraint() {
        containerStackLeadingConstraint?.constant = (indentationWidth * CGFloat(indentationLevel)) + defaultLeadingMargin
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

        let onAnimationComplete = { [weak self] in
            guard let self = self else {
                return
            }

            self.likeButton.tintColor = liked ? Style.likedTintColor : Style.reactionButtonTextColor
            self.likeButton.setImage(liked ? Style.likedIconImage : Style.unlikedIconImage, for: .normal)
            self.likeButton.setTitle(self.likeButtonTitle, for: .normal)
            self.adjustImageAndTitleEdgeInsets(for: self.likeButton)
            self.likeButton.setTitleColor(liked ? Style.likedTintColor : Style.reactionButtonTextColor, for: .normal)
            self.likeButton.accessibilityLabel = liked ? String(numberOfLikes) + .commentIsLiked : String(numberOfLikes) + .commentIsNotLiked
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

    // MARK: Content Rendering

    func resetRenderedContents() {
        renderer = nil
        contentContainerView.subviews.forEach { $0.removeFromSuperview() }
    }

    func configureRendererIfNeeded(for comment: Comment, renderMethod: RenderMethod) {
        // skip creating the renderer if the content does not change.
        // this prevents the cell to jump multiple times due to consecutive reloadData calls.
        //
        // note that this doesn't apply for `.richContent` method. Always reset the textView instead
        // of reusing it to prevent crash. Ref: http://git.io/Jtl2U
        if let renderer = renderer,
           renderer.matchesContent(from: comment),
           renderMethod == .web {
            return
        }

        // clean out any pre-existing renderer just to be sure.
        resetRenderedContents()

        var renderer: CommentContentRenderer = {
            switch renderMethod {
            case .web:
                return WebCommentContentRenderer(comment: comment)
            case .richContent(let attributedText):
                let renderer = RichCommentContentRenderer(comment: comment)
                renderer.richContentDelegate = self.richContentDelegate
                renderer.attributedText = attributedText
                return renderer
            }
        }()
        renderer.delegate = self
        self.renderer = renderer
        self.renderMethod = renderMethod

        if renderMethod == .web {
            // reset height constraint to handle cases where the new content requires the webview to shrink.
            contentContainerHeightConstraint?.isActive = true
            contentContainerHeightConstraint?.constant = 1
        } else {
            contentContainerHeightConstraint?.isActive = false
        }

        let contentView = renderer.render()
        contentContainerView?.addSubview(contentView)
        contentContainerView?.pinSubviewToAllEdges(contentView)
    }

    // MARK: Button Actions

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
    static let commentIsLiked = " likes. Comment is liked"
    static let commentIsNotLiked = " existing likes. Comment is not liked"
    static let replyButtonAccessibilityId = "reply-comment-button"
    static let likeButtonAccessibilityId = "like-comment-button"
    static let reply = NSLocalizedString("Reply", comment: "Reply to a comment.")
    static let noLikes = NSLocalizedString("Like", comment: "Button title to Like a comment.")
    static let singularLikeFormat = NSLocalizedString("%1$d Like", comment: "Singular button title to Like a comment. "
                                                        + "%1$d is a placeholder for the number of Likes.")
    static let pluralLikesFormat = NSLocalizedString("%1$d Likes", comment: "Plural button title to Like a comment. "
                                                + "%1$d is a placeholder for the number of Likes.")

    // pattern that detects empty HTML elements (including HTML comments within).
    static let emptyElementRegexPattern = "<[a-z]+>(<!-- [a-zA-Z0-9\\/: \"{}\\-\\.,\\?=\\[\\]]+ -->)+<\\/[a-z]+>"
}
