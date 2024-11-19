import UIKit
import WordPressUI
import Gravatar

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
            replyButton.tintColor = isReplyHighlighted ? UIAppColor.brand : .label
            replyButton.configuration?.image = UIImage(systemName: isReplyHighlighted ? "arrowshape.turn.up.left.fill" : "arrowshape.turn.up.left")
        }
    }

    // MARK: Constants

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

    /// Styling configuration based on `ReaderDisplaySetting`. The parameter is optional so that the styling approach
    /// can be scoped by using the "legacy" style when the passed parameter is nil.
    private var style: CellStyle = .init(displaySetting: nil)

    var displaySetting: ReaderDisplaySetting? = nil {
        didSet {
            style = CellStyle(displaySetting: displaySetting)
            resetRenderedContents()
            applyStyles()
        }
    }

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

        shouldHideSeparator = true

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

// MARK: - Cell Style

private extension CommentContentTableViewCell {
    /// A structure to override the cell styling based on `ReaderDisplaySetting`.
    /// This doesn't cover all aspects of the cell, and iks currently scoped only for Reader Detail.
    struct CellStyle {
        let displaySetting: ReaderDisplaySetting?

        /// NOTE: Remove when the `readerCustomization` flag is removed.
        var customizationEnabled: Bool {
            ReaderDisplaySetting.customizationEnabled
        }

        // Name Label

        var nameFont: UIFont {
            guard let displaySetting, customizationEnabled else {
                return Style.nameFont
            }
            return displaySetting.font(with: .subheadline, weight: .semibold)
        }

        var nameTextColor: UIColor {
            guard let displaySetting, customizationEnabled else {
                return Style.nameTextColor
            }
            return displaySetting.color.foreground
        }

        // Date Label

        var dateFont: UIFont {
            guard let displaySetting, customizationEnabled else {
                return Style.dateFont
            }
            return displaySetting.font(with: .footnote)
        }

        var dateTextColor: UIColor {
            guard let displaySetting, customizationEnabled else {
                return Style.dateTextColor
            }
            return displaySetting.color.secondaryForeground
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

        nameLabel?.font = style.nameFont
        nameLabel?.textColor = style.nameTextColor

        badgeLabel?.font = Style.badgeFont
        badgeLabel?.textColor = Style.badgeTextColor
        badgeLabel?.backgroundColor = Style.badgeColor
        badgeLabel?.adjustsFontForContentSizeCategory = true
        badgeLabel?.adjustsFontSizeToFitWidth = true

        dateLabel?.font = style.dateFont
        dateLabel?.textColor = style.dateTextColor

        accessoryButton?.tintColor = Style.buttonTintColor
        accessoryButton?.setImage(accessoryButtonImage, for: .normal)
        accessoryButton?.addTarget(self, action: #selector(accessoryButtonTapped), for: .touchUpInside)

        replyButton.configuration = makeReactionButtonConfiguration(systemImage: "arrowshape.turn.up.left")
        replyButton.tintColor = .label
        replyButton.setTitle(.reply, for: .normal)
        replyButton.addTarget(self, action: #selector(replyButtonTapped), for: .touchUpInside)
        replyButton.maximumContentSizeCategory = .accessibilityMedium
        replyButton.accessibilityIdentifier = .replyButtonAccessibilityId

        likeButton.configuration = makeReactionButtonConfiguration(systemImage: "star")
        likeButton.tintColor = .label

        likeButton.addTarget(self, action: #selector(likeButtonTapped), for: .touchUpInside)
        likeButton.maximumContentSizeCategory = .accessibilityMedium
        updateLikeButton(liked: false, numberOfLikes: 0)
        likeButton.accessibilityIdentifier = .likeButtonAccessibilityId

        separatorView.layoutMargins = .init(top: 0, left: 20, bottom: 0, right: 0).flippedForRightToLeft

        applyStyles()
    }

    private func makeReactionButtonConfiguration(systemImage: String) -> UIButton.Configuration {
        var configuration = UIButton.Configuration.plain()
        configuration.image = UIImage(systemName: systemImage)
        configuration.imagePlacement = .top
        configuration.imagePadding = 5
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer {
            var attributes = $0
            attributes.font = UIFont.preferredFont(forTextStyle: .footnote)
            return attributes
        }
        configuration.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(font: UIFont.preferredFont(forTextStyle: .caption1))
        return configuration
    }

    /// Applies the `ReaderDisplaySetting` styles
    private func applyStyles() {
        nameLabel?.font = style.nameFont
        nameLabel?.textColor = style.nameTextColor

        dateLabel?.font = style.dateFont
        dateLabel?.textColor = style.dateTextColor
    }

    /// Configures the avatar image view with the provided URL.
    /// If the URL does not contain any image, the default placeholder image will be displayed.
    /// - Parameter url: The URL containing the image.
    func configureImage(with url: URL?) {
        if let someURL = url, let gravatar = AvatarURL(url: someURL) {
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

        avatarImageView.downloadGravatar(for: someEmail, placeholderImage: Style.placeholderImage)
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
    func updateLikeButton(liked: Bool, numberOfLikes: Int, animated: Bool = false) {
        isLiked = liked
        likeCount = numberOfLikes
        likeButton.tintColor = liked ? Style.likedTintColor : .label
        if var configuration = likeButton.configuration {
            configuration.image = UIImage(systemName: liked ? "star.fill" : "star")
            configuration.title = likeButtonTitle
            likeButton.configuration = configuration
        } else {
            wpAssertionFailure("missing configuration")
        }
        likeButton.accessibilityLabel = liked ? String(numberOfLikes) + .commentIsLiked : String(numberOfLikes) + .commentIsNotLiked
        if liked && animated {
            likeButton.imageView?.fadeInWithRotationAnimation()
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
                return WebCommentContentRenderer(comment: comment, displaySetting: displaySetting ?? .standard)
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
        updateLikeButton(liked: !isLiked, numberOfLikes: isLiked ? likeCount - 1 : likeCount + 1, animated: true)
        likeButtonAction?()
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
}
