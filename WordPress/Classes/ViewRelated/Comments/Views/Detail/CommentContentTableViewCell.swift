import UIKit
import WordPressUI
import WordPressReader
import Gravatar
import Combine
import SwiftUI

final class CommentContentTableViewCell: UITableViewCell, NibReusable {
    // all the available images for the accessory button.
    enum AccessoryButtonType {
        case ellipsis
        case info
    }

    // MARK: - Public Properties

    /// A closure that's called when the accessory button is tapped.
    /// The button's view is sent as the closure's parameter for reference.
    @objc var accessoryButtonAction: ((UIView) -> Void)? = nil

    @objc var replyButtonAction: (() -> Void)? = nil

    @objc var contentLinkTapAction: ((URL) -> Void)? = nil

    var accessoryButtonType: AccessoryButtonType = .ellipsis {
        didSet {
            accessoryButton.setImage(accessoryButtonImage, for: .normal)
        }
    }

    var badgeTitle: String? = nil {
        didSet {
            let title = badgeTitle?.localizedUppercase ?? ""
            badgeLabel.text = title
            badgeLabel.isHidden = title.isEmpty
        }
    }

    var depth: Int {
        get { effectiveDepth }
        set { effectiveDepth = min(Self.maxDepth, newValue) }
    }

    private static let maxDepth = 4
    private static let depthInset: CGFloat = 12

    private var effectiveDepth: Int = 0 {
        didSet {
            guard oldValue != effectiveDepth else { return }
            containerStackLeadingConstraint?.constant = (Self.depthInset * CGFloat(effectiveDepth)) + 16
            configureDepthSeparators(depth: effectiveDepth)
        }
    }

    private var depthSeparators: [UIView?] = .init(repeating: nil, count: CommentContentTableViewCell.maxDepth)

    /// A custom highlight style for the cell that is more controllable than `isHighlighted`.
    /// Cell selection for this cell is disabled, and highlight style may be disabled based on the table view settings.
    @objc var isEmphasized: Bool = false {
        didSet {
            guard oldValue != isEmphasized else { return }
            backgroundColor = isEmphasized ? Style.highlightedBackgroundColor : nil
            highlightBarView.backgroundColor = isEmphasized ? Style.highlightedBarBackgroundColor : .clear
        }
    }

    // MARK: Outlets
    @IBOutlet private weak var headerView: UIView!

    @IBOutlet private weak var containerStackView: UIStackView!
    @IBOutlet private weak var containerStackLeadingConstraint: NSLayoutConstraint!
    @IBOutlet private weak var containerStackTrailingConstraint: NSLayoutConstraint!

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

    // MARK: Private Properties

    /// Called when the cell has finished loading and calculating the height of the HTML content. Passes the new content height as parameter.
    private var onContentLoaded: ((CGFloat) -> Void)? = nil

    private var comment: Comment?
    private var renderer: CommentContentRenderer?
    private var helper: ReaderCommentsHelper?
    private var viewModel: CommentCellViewModel?
    private var cancellables: [AnyCancellable] = []

    // MARK: Like Button State

    /// Styling configuration based on `ReaderDisplaySetting`. The parameter is optional so that the styling approach
    /// can be scoped by using the "legacy" style when the passed parameter is nil.
    private var style: CellStyle = .init(displaySetting: nil)

    var displaySetting: ReaderDisplaySettings? = nil {
        didSet {
            style = CellStyle(displaySetting: displaySetting)
            applyStyles()
        }
    }

    // MARK: Visibility Control

    var isAccessoryButtonEnabled: Bool = false {
        didSet {
            accessoryButton.isHidden = !isAccessoryButtonEnabled
        }
    }

    // MARK: Lifecycle

    override func prepareForReuse() {
        super.prepareForReuse()

        viewModel = nil
        cancellables = []
        avatarImageView.wp.prepareForReuse()
        renderer?.prepareForReuse()

        isEmphasized = false
        depth = 0

        accessoryButtonAction = nil
        replyButtonAction = nil
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
    ///   - onContentLoaded: Callback to be called once the content has been loaded. Provides the new content height as parameter.
    func configure(
        viewModel: CommentCellViewModel,
        helper: ReaderCommentsHelper,
        onContentLoaded: ((CGFloat) -> Void)?
    ) {
        let comment = viewModel.comment
        self.comment = comment
        self.viewModel = viewModel
        self.helper = helper
        self.onContentLoaded = onContentLoaded

        viewModel.$state.sink { [weak self] in
            self?.configure(with: $0)
        }.store(in: &cancellables)

        viewModel.$avatar.sink { [weak self] in
            self?.configureAvatar(with: $0)
        }.store(in: &cancellables)

        viewModel.$content.sink { [weak self] in
            self?.configureContent($0 ?? "", helper: helper)
        }.store(in: &cancellables)

        // Configure feature availability.
        isAccessoryButtonEnabled = comment.isApproved()
    }

    /// Configures the cell with a `Comment` object, to be displayed in the post details view.
    ///
    /// - Parameters:
    ///   - comment: The `Comment` object to display.
    ///   - onContentLoaded: Callback to be called once the content has been loaded. Provides the new content height as parameter.
    func configureForPostDetails(with comment: Comment, helper: ReaderCommentsHelper, onContentLoaded: ((CGFloat) -> Void)?) {
        configure(viewModel: CommentCellViewModel(comment: comment), helper: helper, onContentLoaded: onContentLoaded)

        hideActions()

        containerStackLeadingConstraint.constant = 0
        containerStackTrailingConstraint.constant = 0
    }

    func hideActions() {
        replyButton.isHidden = true
        likeButton.isHidden = true
        isAccessoryButtonEnabled = false
    }

    func configureForCommentDetails() {
        containerStackView.isLayoutMarginsRelativeArrangement = true
        containerStackView.layoutMargins = UIEdgeInsets(.vertical, 4)
    }

    private func configure(with state: CommentCellViewModel.State) {
        nameLabel.text = state.title
        dateLabel.text = state.dateCreated?.toMediumString()

        replyButton.isHidden = !state.isReplyEnabled
        likeButton.isHidden = !state.isLikeEnabled
        likeButton?.configuration?.contentInsets.leading = state.isReplyEnabled ? 8 : 0

        updateLikeButton(isLiked: state.isLiked, likeCount: state.likeCount)
    }

    private func configureDepthSeparators(depth: Int) {
        for depthSeparator in depthSeparators {
            depthSeparator?.isHidden = true
        }
        for level in 0..<depth {
            let separatorView = depthSeparators[level] ?? {
                let separatorView = SeparatorView.vertical()
                depthSeparators[level] = separatorView
                contentView.addSubview(separatorView)
                separatorView.pinEdges([.top, .bottom])
                let inset = -Self.depthInset * CGFloat(level + 1)
                separatorView.trailingAnchor.constraint(equalTo: containerStackView.leadingAnchor, constant: inset).isActive = true
                return separatorView
            }()
            separatorView.isHidden = false
        }
    }
}

// MARK: - CommentContentRendererDelegate

extension CommentContentTableViewCell: CommentContentRendererDelegate {
    func renderer(_ renderer: CommentContentRenderer, asyncRenderCompletedWithHeight height: CGFloat, comment: String) {
        if let constraint = contentContainerHeightConstraint {
            if height != constraint.constant {
                constraint.constant = height
                helper?.setCachedContentHeight(height, for: comment)
                onContentLoaded?(height) // We had the right size from the get-go
            }
        } else {
            wpAssertionFailure("constraint missing")
        }
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
        let displaySetting: ReaderDisplaySettings?

        /// NOTE: Remove when the `readerCustomization` flag is removed.
        var customizationEnabled: Bool {
            ReaderDisplaySettings.customizationEnabled
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
        case .ellipsis:
            return .init(systemName: "ellipsis", withConfiguration: UIImage.SymbolConfiguration(font: .preferredFont(forTextStyle: .footnote)))?.withTintColor(.secondaryLabel)
        case .info:
            return .init(systemName: "info.circle", withConfiguration: UIImage.SymbolConfiguration(font: .preferredFont(forTextStyle: .footnote)))
        }
    }

    // assign base styles for all the cell components.
    func configureViews() {
        selectionStyle = .none

        headerView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(headerTapped)))

        nameLabel?.font = style.nameFont
        nameLabel?.textColor = style.nameTextColor
        nameLabel?.numberOfLines = 1

        badgeLabel?.font = Style.badgeFont
        badgeLabel?.textColor = Style.badgeTextColor
        badgeLabel?.backgroundColor = Style.badgeColor
        badgeLabel?.adjustsFontForContentSizeCategory = true
        badgeLabel?.adjustsFontSizeToFitWidth = true

        dateLabel?.font = style.dateFont
        dateLabel?.textColor = style.dateTextColor

        accessoryButton?.tintColor = .secondaryLabel
        accessoryButton?.setImage(accessoryButtonImage, for: .normal)
        accessoryButton?.addTarget(self, action: #selector(accessoryButtonTapped), for: .touchUpInside)

        replyButton.configuration = makeReactionButtonConfiguration(image: UIImage(named: "icon-reader-comment-reply"))
        replyButton.configuration?.contentInsets.leading = 0
        replyButton.tintColor = .secondaryLabel
        replyButton.setTitle(.reply, for: .normal)
        replyButton.addTarget(self, action: #selector(replyButtonTapped), for: .touchUpInside)
        replyButton.maximumContentSizeCategory = .accessibilityMedium
        replyButton.accessibilityIdentifier = .replyButtonAccessibilityId

        likeButton.configuration = makeReactionButtonConfiguration(image: WPStyleGuide.ReaderDetail.likeToolbarIcon)
        likeButton.tintColor = .secondaryLabel

        likeButton.addTarget(self, action: #selector(likeButtonTapped), for: .touchUpInside)
        likeButton.maximumContentSizeCategory = .accessibilityMedium
        likeButton.accessibilityIdentifier = .likeButtonAccessibilityId

        applyStyles()
    }

    private func makeReactionButtonConfiguration(image: UIImage? = nil) -> UIButton.Configuration {
        var configuration = UIButton.Configuration.plain()
        let font = UIFont.preferredFont(forTextStyle: .footnote)
        configuration.image = image
        configuration.imagePlacement = .leading
        configuration.imagePadding = 2
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer {
            var attributes = $0
            attributes.font = font
            return attributes
        }
        configuration.contentInsets = .init(top: 8, leading: 8, bottom: 8, trailing: 8)
        configuration.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(font: font)
        return configuration
    }

    /// Applies the `ReaderDisplaySetting` styles
    private func applyStyles() {
        nameLabel?.font = style.nameFont
        nameLabel?.textColor = style.nameTextColor

        dateLabel?.font = style.dateFont
        dateLabel?.textColor = style.dateTextColor
    }

    private func configureAvatar(with avatar: CommentCellViewModel.Avatar?) {
        guard let avatar else {
            avatarImageView.wp.prepareForReuse()
            return
        }
        switch avatar {
        case .url(let imageURL):
            if let gravatar = AvatarURL(url: imageURL) {
                avatarImageView.downloadGravatar(gravatar, placeholder: Style.placeholderImage, animate: false)
            } else {
                avatarImageView.image = Style.placeholderImage
                avatarImageView.wp.setImage(with: imageURL)
            }
        case .email(let email):
            avatarImageView.downloadGravatar(for: email, placeholderImage: Style.placeholderImage)
        }
    }

    func updateLikeButton(isLiked: Bool, likeCount: Int) {
        likeButton.tintColor = isLiked ? UIAppColor.primary : .secondaryLabel
        if var configuration = likeButton.configuration {
            configuration.image = isLiked ? WPStyleGuide.ReaderDetail.likeSelectedToolbarIcon : WPStyleGuide.ReaderDetail.likeToolbarIcon
            configuration.title = likeCount > 0 ? "\(likeCount)" : String.noLikes
            likeButton.accessibilityLabel = {
                switch likeCount {
                case .zero: .noLikes
                case 1: String(format: .singularLikeFormat, likeCount)
                default: String(format: .pluralLikesFormat, likeCount)
                }
            }()
            likeButton.configuration = configuration
        } else {
            wpAssertionFailure("missing configuration")
        }
        likeButton.accessibilityLabel = isLiked ? String(likeCount) + .commentIsLiked : String(likeCount) + .commentIsNotLiked
    }

    // MARK: Content Rendering

    func configureContent(_ content: String, helper: ReaderCommentsHelper) {
        let renderer = self.renderer ?? {
            let renderer = helper.makeWebRenderer()
            renderer.delegate = self
            self.renderer = renderer
            return renderer
        }()

        // reset height constraint to handle cases where the new content requires the webview to shrink.
        contentContainerHeightConstraint?.isActive = true
        // - warning: It's important to set height to the minimum supported
        // value because `WKWebView` can only increase the content height and
        // never decreases it when the content changes.
        contentContainerHeightConstraint?.constant = helper.getCachedContentHeight(for: content) ?? 20

        let contentView = renderer.view
        if contentContainerView.subviews.first != contentView {
            contentContainerView.subviews.forEach { $0.removeFromSuperview() }
            contentView.removeFromSuperview()
            contentContainerView?.addSubview(contentView)
            contentView.pinEdges()
        }
        renderer.render(comment: content)
    }

    // MARK: Button Actions

    @objc private func headerTapped() {
        guard let comment = viewModel?.comment else {
            return
        }
        let viewModel = ReaderUserProfileViewModel(comment: comment)
        let profileVC = UIHostingController(rootView: ReaderUserProfileView(viewModel: viewModel))
        let navigationVC = UINavigationController(rootViewController: profileVC)
        profileVC.navigationItem.leftBarButtonItem = UIBarButtonItem(systemItem: .close, primaryAction: .init { [weak profileVC] _ in
            profileVC?.presentingViewController?.dismiss(animated: true)
        })
        navigationVC.sheetPresentationController?.detents = [.medium()]
        UIViewController.topViewController?.present(navigationVC, animated: true)
    }

    @objc func accessoryButtonTapped() {
        accessoryButtonAction?(accessoryButton)
    }

    @objc func replyButtonTapped() {
        replyButtonAction?()
    }

    @objc func likeButtonTapped() {
        guard let viewModel else {
            return wpAssertionFailure("ViewModel missing")
        }
        if !viewModel.state.isLiked, let imageView = likeButton.imageView {
            // Animate the changes and then update the model to avoid animation interruptions
            updateLikeButton(isLiked: true, likeCount: viewModel.state.likeCount + 1)
            imageView.fadeInWithRotationAnimation { _ in
                viewModel.buttonLikeTapped()
            }
        } else {
            viewModel.buttonLikeTapped()
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
    static let singularLikeFormat = NSLocalizedString("%1$d Like", comment: "Singular button title to Like a comment. %1$d is a placeholder for the number of Likes.")
    static let pluralLikesFormat = NSLocalizedString("%1$d Likes", comment: "Plural button title to Like a comment. %1$d is a placeholder for the number of Likes.")
}
