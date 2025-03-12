import UIKit
import WordPressUI
import WordPressReader

protocol ReaderDetailToolbarDelegate: AnyObject {
    var notificationID: String? { get }
}

class ReaderDetailToolbar: UIView, NibLoadable {
    @IBOutlet weak var dividerView: UIView!
    @IBOutlet weak var saveForLaterButton: UIButton!
    @IBOutlet weak var reblogButton: PostMetaButton!
    @IBOutlet weak var commentButton: PostMetaButton!
    @IBOutlet weak var likeButton: PostMetaButton!

    /// The reader post that the toolbar interacts with
    private var post: ReaderPost?

    /// The VC where the toolbar is inserted
    private weak var viewController: UIViewController?

    /// An observer of the number of likes of the post
    private var likeCountObserver: NSKeyValueObservation?

    /// An observer of the number of likes of the post
    private var commentCountObserver: NSKeyValueObservation?

    weak var delegate: ReaderDetailToolbarDelegate? = nil

    var displaySetting: ReaderDisplaySettings = .standard {
        didSet {
            applyStyles()
            configureActionButtons()
        }
    }

    private func likeButtonTitle(likeCount: Int) -> String {
        if likeCount > 0 {
            return likeCount.formatted(.number.notation(.compactName))
        }
        return Constants.likeButtonTitle
    }

    private var likeCount: Int {
        post?.likeCount?.intValue ?? 0
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        applyStyles()

        prepareActionButtonsForVoiceOver()
    }

    func viewWillAppear() {
        subscribePostChanges()
    }

    func viewWillDisappear() {
        unsubscribePostChanges()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            configureActionButtons()
        }
        configureButtonTitles()
    }

    func configure(for post: ReaderPost, in viewController: UIViewController) {
        self.post = post
        self.viewController = viewController

        subscribePostChanges()
        configureActionButtons()
    }

    // MARK: - Actions

    @IBAction func didTapSaveForLater(_ sender: Any) {
        guard let readerPost = post, let context = readerPost.managedObjectContext,
            let viewController = viewController as? UIViewController & UIViewControllerTransitioningDelegate else {
            return
        }

        if !readerPost.isSavedForLater {
            FancyAlertViewController.presentReaderSavedPostsAlertControllerIfNecessary(from: viewController)
        }

        ReaderSaveForLaterAction().execute(with: readerPost, context: context, origin: .postDetail, viewController: viewController) { [weak self] in
            self?.saveForLaterButton.isSelected = readerPost.isSavedForLater
            self?.prepareActionButtonsForVoiceOver()
        }
    }

    @IBAction func didTapReblog(_ sender: Any) {
        guard let post, let viewController else {
            return
        }

        ReaderReblogAction().execute(readerPost: post, origin: viewController, reblogSource: .detail)
    }

    @IBAction func didTapComment(_ sender: Any) {
        guard let post, let viewController else {
            return
        }

        ReaderCommentAction().execute(post: post, origin: viewController, source: .postDetails)
    }

    @IBAction func didTapLike(_ sender: Any) {
        guard let post else {
            return
        }
        if !post.isLiked {
            likeButton.setTitle(likeButtonTitle(likeCount: likeCount + 1), for: [])
            likeButton.isSelected = true
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            likeButton.imageView?.fadeInWithRotationAnimation { _ in
                self.toggleLike()
            }
        } else {
            toggleLike()
        }
    }

    private func toggleLike() {
        let service = ReaderPostService(coreDataStack: ContextManager.shared)
        service.toggleLiked(for: post, success: { [weak self] in
            if let notificationID = self?.delegate?.notificationID {
                let mediator = NotificationSyncMediator()
                mediator?.invalidateCacheForNotification(notificationID, completion: {
                    mediator?.syncNote(with: notificationID)
                })
            }
            self?.trackArticleDetailsLikedOrUnliked()
        }, failure: { [weak self] (error: Error?) in
            self?.trackArticleDetailsLikedOrUnliked()
            if let anError = error {
                DDLogError("Error (un)liking post: \(anError.localizedDescription)")
            }
        })
    }

    // MARK: - Styles

    private func applyStyles() {
        backgroundColor = displaySetting == .standard ? .secondarySystemGroupedBackground : displaySetting.color.background
        dividerView.backgroundColor = displaySetting == .standard ? UIColor.separator : displaySetting.color.border
    }

    // MARK: - Configuration

    private func configureActionButtons() {
        resetActionButton(likeButton)
        resetActionButton(commentButton)
        resetActionButton(saveForLaterButton)
        resetActionButton(reblogButton)

        configureLikeActionButton()
        configureCommentActionButton()
        configureReblogButton()
        configureSaveForLaterButton()
        configureButtonTitles()
    }

    private func resetActionButton(_ button: UIButton) {
        button.setTitle(nil, for: UIControl.State())
        button.setTitle(nil, for: .highlighted)
        button.setTitle(nil, for: .disabled)
        button.setImage(nil, for: UIControl.State())
        button.setImage(nil, for: .highlighted)
        button.setImage(nil, for: .disabled)
        button.isSelected = false
        button.isEnabled = true
    }

    private func configureActionButton(_ button: UIButton, title: String?, image: UIImage?, highlightedImage: UIImage?, selected: Bool) {
        button.setTitle(title, for: UIControl.State())
        button.setTitle(title, for: .highlighted)
        button.setTitle(title, for: .disabled)
        button.setImage(image, for: UIControl.State())
        button.setImage(highlightedImage, for: .highlighted)
        button.setImage(highlightedImage, for: .selected)
        button.setImage(highlightedImage, for: [.highlighted, .selected])
        button.setImage(image, for: .disabled)
        button.isSelected = selected

        configureActionButtonStyle(button)
    }

    private func configureActionButtonStyle(_ button: UIButton) {
        let standardDisabledColor = UIColor(light: UIAppColor.gray(.shade10), dark: .quaternaryLabel)
        let disabledColor = displaySetting == .standard ? standardDisabledColor : displaySetting.color.border

        WPStyleGuide.applyReaderActionButtonStyle(button,
                                                  titleColor: displaySetting == .standard ? .secondaryLabel : displaySetting.color.secondaryForeground,
                                                  imageColor: displaySetting == .standard ? .secondaryLabel : displaySetting.color.secondaryForeground,
                                                  disabledColor: disabledColor)

        var configuration = UIButton.Configuration.plain()

        // Vertically stack the button's image and title.
        configuration.imagePlacement = .top
        configuration.contentInsets = Constants.buttonContentInsets
        configuration.imagePadding = Constants.buttonImagePadding

        /// Override the button's title label font.
        /// When the button's configuration exists, updating the font via `titleLabel` no longer works somehow.
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { [weak self] incoming in
            guard let self else {
                return incoming
            }

            var outgoing = incoming
            outgoing.font = self.displaySetting == .standard ? WPStyleGuide.fontForTextStyle(.footnote) : self.displaySetting.font(with: .footnote)
            return outgoing
        }

        // Don't allow the button title to wrap.
        configuration.titleLineBreakMode = .byTruncatingTail

        button.configuration = configuration

        /// Remove default background styles. The `.plain()` configuration adds a gray background to selected state.
        button.configurationUpdateHandler = { button in
            switch button.state {
            case .selected:
                button.configuration?.background.backgroundColor = .clear
            default:
                return
            }
        }
    }

    private func configureLikeActionButton(_ animated: Bool = false) {
        guard let post else {
            return
        }

        let selected = post.isLiked
        likeButton.isEnabled = (ReaderHelpers.isLoggedIn() || likeCount > 0) && !post.isExternal
        likeButton.accessibilityHint = selected ? Constants.likedButtonHint : Constants.likeButtonHint

        configureActionButton(
            likeButton,
            title: likeButtonTitle(likeCount: likeCount),
            image: WPStyleGuide.ReaderDetail.likeToolbarIcon,
            highlightedImage: WPStyleGuide.ReaderDetail.likeSelectedToolbarIcon,
            selected: selected
        )
    }

    /// Uses the configuration in WPStyleGuide for the reblog button
    private func configureReblogButton() {
        guard let post else {
            return
        }

        reblogButton.isEnabled = ReaderHelpers.isLoggedIn() && !post.isBlogPrivate
        WPStyleGuide.applyReaderReblogActionButtonStyle(reblogButton, showTitle: false)

        configureActionButtonStyle(reblogButton)
        prepareReblogForVoiceOver()
    }

    private func configureCommentActionButton() {
        commentButton.setTitle({
            let count = post?.commentCount.intValue ?? 0
            return count == 0 ? Constants.commentButtonTitle : count.formatted(.number.notation(.compactName))
        }(), for: [])

        commentButton.isEnabled = shouldShowCommentActionButton

        commentButton.setImage(WPStyleGuide.ReaderDetail.commentToolbarIcon, for: .normal)
        commentButton.setImage(WPStyleGuide.ReaderDetail.commentHighlightedToolbarIcon, for: .selected)
        commentButton.setImage(WPStyleGuide.ReaderDetail.commentHighlightedToolbarIcon, for: .highlighted)
        commentButton.setImage(WPStyleGuide.ReaderDetail.commentHighlightedToolbarIcon, for: [.highlighted, .selected])
        commentButton.setImage(WPStyleGuide.ReaderDetail.commentToolbarIcon, for: .disabled)

        configureActionButtonStyle(commentButton)
    }

    private var shouldShowCommentActionButton: Bool {
        // Show comments if logged in and comments are enabled, or if comments exist.
        // But only if it is from wpcom (jetpack and external is not yet supported).
        // Nesting this conditional cos it seems clearer that way
        guard let post else {
            return false
        }

        if post.isWPCom || post.isJetpack {
            let commentCount = post.commentCount?.intValue ?? 0
            if (ReaderHelpers.isLoggedIn() && post.commentsOpen) || commentCount > 0 {
                return true
            }
        }

        return false
    }

    private func configureSaveForLaterButton() {
        WPStyleGuide.applyReaderSaveForLaterButtonStyle(saveForLaterButton)
        WPStyleGuide.applyReaderSaveForLaterButtonTitles(saveForLaterButton, showTitle: false)

        let isSaved = post?.isSavedForLater ?? false
        saveForLaterButton.isSelected = isSaved
        prepareActionButtonsForVoiceOver()

        configureActionButtonStyle(saveForLaterButton)
    }

    fileprivate func configureButtonTitles() {
        WPStyleGuide.applyReaderSaveForLaterButtonTitles(saveForLaterButton, showTitle: true)
        WPStyleGuide.applyReaderReblogActionButtonTitle(reblogButton, showTitle: true)
    }

    // MARK: - Analytics

    private func trackArticleDetailsLikedOrUnliked() {
        guard let post else {
            return
        }

        let stat: WPAnalyticsStat = post.isLiked
            ? .readerArticleDetailLiked
            : .readerArticleDetailUnliked

        var properties = [AnyHashable: Any]()
        properties[WPAppAnalyticsKeyBlogID] = post.siteID
        properties[WPAppAnalyticsKeyPostID] = post.postID
        WPAnalytics.track(stat, withProperties: properties)
    }

    // MARK: - Voice Over

    private func prepareActionButtonsForVoiceOver() {
        let isSaved = post?.isSavedForLater ?? false
        saveForLaterButton.accessibilityLabel = isSaved ? Constants.savedButtonAccessibilityLabel : Constants.saveButtonAccessibilityLabel
        saveForLaterButton.accessibilityHint = isSaved ? Constants.savedButtonHint : Constants.saveButtonHint
    }

    private func prepareReblogForVoiceOver() {
        reblogButton.accessibilityLabel = NSLocalizedString("Reblog post", comment: "Accessibility label for the reblog button.")
        reblogButton.accessibilityHint = NSLocalizedString("Reblog this post", comment: "Accessibility hint for the reblog button.")
        reblogButton.accessibilityTraits = UIAccessibilityTraits.button
    }
}

// MARK: - Private Helpers

private extension ReaderDetailToolbar {

    struct Constants {
        static let buttonContentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
        static let buttonImagePadding: CGFloat = 0

        // MARK: Strings

        static let savedButtonAccessibilityLabel = NSLocalizedString(
            "reader.detail.toolbar.saved.button.a11y.label",
            value: "Saved Post",
            comment: "Accessibility label for the 'Save Post' button when a post has been saved."
        )

        static let savedButtonHint = NSLocalizedString(
            "reader.detail.toolbar.saved.button.a11y.hint",
            value: "Unsaves this post.",
            comment: "Accessibility hint for the 'Save Post' button when a post is already saved."
        )

        static let saveButtonAccessibilityLabel = NSLocalizedString(
            "reader.detail.toolbar.save.button.a11y.label",
            value: "Save post",
            comment: "Accessibility label for the 'Save Post' button."
        )

        static let saveButtonHint = NSLocalizedString(
            "reader.detail.toolbar.save.button.a11y.hint",
            value: "Saves this post for later.",
            comment: "Accessibility hint for the 'Save Post' button."
        )

        static let likeButtonTitle = NSLocalizedString(
            "reader.detail.toolbar.like.button",
            value: "Like",
            comment: """
                Title for the Like button in the Reader Detail toolbar.
                This is shown when the user has not liked the post yet.
                Note: Since the display space is limited, a short or concise translation is preferred.
                """
        )

        static let likeButtonHint = NSLocalizedString(
            "reader.detail.toolbar.like.button.a11y.hint",
            value: "Likes this post.",
            comment: """
                Accessibility hint for the Like button state. The button shows that the user has not liked the post,
                but tapping on this button will add a Like to the post.
                """
        )

        static let likedButtonTitle = NSLocalizedString(
            "reader.detail.toolbar.liked.button",
            value: "Liked",
            comment: """
                Title for the Like button in the Reader Detail toolbar.
                This is shown when the user has already liked the post.
                Note: Since the display space is limited, a short or concise translation is preferred.
                """
        )

        static let likedButtonHint = NSLocalizedString(
            "reader.detail.toolbar.liked.button.a11y.hint",
            value: "Unlikes this post.",
            comment: """
                Accessibility hint for the Liked button state. The button shows that the user has liked the post,
                but tapping on this button will remove their like from the post.
                """
        )

        static let commentButtonTitle = NSLocalizedString(
            "reader.detail.toolbar.comment.button",
            value: "Comment",
            comment: """
                Title for the Comment button on the Reader Detail toolbar.
                Note: Since the display space is limited, a short or concise translation is preferred.
                """
        )
    }
}

// MARK: - Observe Post

private extension ReaderDetailToolbar {
    func subscribePostChanges() {
        likeCountObserver = post?.observe(\.likeCount, options: [.old, .new]) { [weak self] updatedPost, change in
            // ensure that we only update the like button when there's actual change.
            let oldValue = change.oldValue??.intValue ?? 0
            let newValue = change.newValue??.intValue ?? 0
            guard oldValue != newValue else {
                return
            }

            self?.configureLikeActionButton(true)
        }

        commentCountObserver = post?.observe(\.commentCount, options: [.old, .new]) { [weak self] _, change in
            // ensure that we only update the like button when there's actual change.
            let oldValue = change.oldValue??.intValue ?? 0
            let newValue = change.newValue??.intValue ?? 0
            guard oldValue != newValue else {
                return
            }

            self?.configureCommentActionButton()
        }
    }

    func unsubscribePostChanges() {
        likeCountObserver?.invalidate()
        commentCountObserver?.invalidate()
    }
}
