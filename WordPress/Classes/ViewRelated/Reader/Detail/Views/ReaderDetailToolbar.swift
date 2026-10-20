import UIKit
import WordPressData
import WordPressUI
import WordPressReader

protocol ReaderDetailToolbarDelegate: AnyObject {
    var notificationID: String? { get }
}

class ReaderDetailToolbar {
    private var post: ReaderPost?
    private weak var viewController: UIViewController?

    private var likeCountObserver: NSKeyValueObservation?
    private var commentCountObserver: NSKeyValueObservation?

    /// The buttons currently shown in the toolbar.
    ///
    /// They are updated in place rather than recreated on every change. On iOS 26, while the toolbar
    /// is over a dark image, new items can come up in the dark style while the toolbar and the other
    /// items stay light, mixing black and white icons.
    private var buttons: Buttons?

    weak var delegate: ReaderDetailToolbarDelegate?

    private var likeCount: Int {
        post?.likeCount?.intValue ?? 0
    }

    func viewWillAppear() {
        subscribePostChanges()
    }

    func viewWillDisappear() {
        unsubscribePostChanges()
    }

    func configure(for viewController: UIViewController) {
        self.viewController = viewController
    }

    func configure(for post: ReaderPost, in viewController: UIViewController) {
        self.post = post
        self.viewController = viewController

        subscribePostChanges()
        updateToolbarItems()
    }

    private func updateToolbarItems() {
        guard let viewController, let post else { return }

        let showsCommentButton = shouldShowCommentActionButton
        let showsLikeButton = post.isLikesEnabled

        if let buttons, (buttons.comment != nil) == showsCommentButton, (buttons.like != nil) == showsLikeButton {
            configure(buttons, for: post)
            return
        }

        let buttons = Buttons(
            saveForLater: UIBarButtonItem(
                image: nil,
                style: .plain,
                target: self,
                action: #selector(didTapSaveForLater)
            ),
            reblog: UIBarButtonItem(
                image: WPStyleGuide.ReaderDetail.reblogToolbarIcon,
                style: .plain,
                target: self,
                action: #selector(didTapReblog)
            ),
            comment: showsCommentButton ? makeCustomButton(action: #selector(didTapComment)) : nil,
            like: showsLikeButton ? makeCustomButton(action: #selector(didTapLike)) : nil
        )
        configure(buttons, for: post)
        self.buttons = buttons
        viewController.setToolbarItems(buttons.toolbarItems, animated: false)
    }

    // MARK: - Configure Buttons

    private func configure(_ buttons: Buttons, for post: ReaderPost) {
        configureSaveForLaterButton(buttons.saveForLater, for: post)
        configureReblogButton(buttons.reblog, for: post)
        if let comment = buttons.comment {
            configureCommentButton(comment, for: post)
        }
        if let like = buttons.like {
            configureLikeButton(like, for: post)
        }
    }

    private func configureSaveForLaterButton(_ button: UIBarButtonItem, for post: ReaderPost) {
        let isSaved = post.isSavedForLater

        button.image =
            isSaved ? WPStyleGuide.ReaderDetail.saveSelectedToolbarIcon : WPStyleGuide.ReaderDetail.saveToolbarIcon
        button.accessibilityLabel = isSaved ? Constants.savedButtonAccessibilityLabel : Constants.saveButtonAccessibilityLabel
        button.accessibilityHint = isSaved ? Constants.savedButtonHint : Constants.saveButtonHint
        button.tintColor = isSaved ? UIAppColor.primary : .label
    }

    private func configureReblogButton(_ button: UIBarButtonItem, for post: ReaderPost) {
        button.isEnabled = ReaderHelpers.isLoggedIn() && !post.isBlogPrivate
        button.accessibilityLabel = NSLocalizedString("Reblog post", comment: "Accessibility label for the reblog button.")
        button.accessibilityHint = NSLocalizedString("Reblog this post", comment: "Accessibility hint for the reblog button.")
        button.tintColor = .label
    }

    private func configureCommentButton(_ button: UIBarButtonItem, for post: ReaderPost) {
        let count = post.commentCount?.intValue ?? 0

        configureCustomButton(
            button,
            image: WPStyleGuide.ReaderDetail.commentToolbarIcon,
            title: count.formatted(.number.notation(.compactName))
        )
    }

    private func configureLikeButton(_ button: UIBarButtonItem, for post: ReaderPost) {
        let isLiked = post.isLiked

        configureCustomButton(
            button,
            image: isLiked ? WPStyleGuide.ReaderDetail.likeSelectedToolbarIcon : WPStyleGuide.ReaderDetail.likeToolbarIcon,
            title: likeCount.formatted(.number.notation(.compactName)),
            isSelected: isLiked
        )
        button.accessibilityHint = isLiked ? Constants.likedButtonHint : Constants.likeButtonHint
    }

    private func makeCustomButton(action: Selector) -> UIBarButtonItem {
        let button = UIButton(configuration: .plain(), primaryAction: nil)
        button.addTarget(self, action: action, for: .touchUpInside)
        return UIBarButtonItem(customView: button)
    }

    private func configureCustomButton(
        _ item: UIBarButtonItem,
        image: UIImage?,
        title: String,
        isSelected: Bool = false
    ) {
        guard let button = item.customView as? UIButton else { return }

        var configuration = UIButton.Configuration.plain()
        configuration.image = image
        configuration.title = title

        // Apply colors based on display settings and selection state
        let tintColor = isSelected ? UIAppColor.primary : .label
        configuration.baseForegroundColor = tintColor
        configuration.imagePadding = 5

        // Set font
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = .system(size: 15)
            return outgoing
        }

        button.configuration = configuration
        button.tintColor = tintColor
        // The toolbar doesn't resize a custom view when its content changes, e.g. when the like count gets longer.
        button.sizeToFit()
    }

    // MARK: - Actions

    @objc private func didTapSaveForLater(_ sender: Any) {
        guard let readerPost = post, let context = readerPost.managedObjectContext,
              let viewController = viewController as? UIViewController & UIViewControllerTransitioningDelegate else {
            return
        }
        ReaderSaveForLaterAction().execute(with: readerPost, context: context, origin: .postDetail, viewController: viewController) { [weak self] in
            self?.updateToolbarItems()
        }
    }

    @objc private func didTapReblog(_ sender: Any) {
        guard let post, let viewController else {
            return
        }

        ReaderReblogAction().execute(readerPost: post, origin: viewController, reblogSource: .detail)
    }

    @objc private func didTapComment(_ sender: Any) {
        guard let post, let viewController else {
            return
        }

        ReaderCommentAction().execute(post: post, origin: viewController, source: .postDetails, trackingSource: ScreenTrackingSource(ScreenID.Reader.article, component: ElementID.Reader.toolbarComment))
    }

    @objc private func didTapLike(_ sender: Any) {
        guard let post else {
            return
        }

        if !post.isLiked {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }

        toggleLike()
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
            self?.updateToolbarItems()
        }, failure: { [weak self] (error: Error?) in
            self?.trackArticleDetailsLikedOrUnliked()
            if let error {
                DDLogError("Error (un)liking post: \(error.localizedDescription)")
                Notice(error: error).post()
                UINotificationFeedbackGenerator().notificationOccurred(.error)
            }
            self?.updateToolbarItems()
        })
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

    // MARK: - Analytics

    private func trackArticleDetailsLikedOrUnliked() {
        guard let post else {
            return
        }

        let stat: WPAnalyticsStat = post.isLiked ? .readerArticleDetailLiked : .readerArticleDetailUnliked

        var properties = [AnyHashable: Any]()
        properties[WPAppAnalyticsKeyBlogID] = post.siteID
        properties[WPAppAnalyticsKeyPostID] = post.postID
        WPAnalytics.track(stat, withProperties: properties)
    }
}

// MARK: - Private Helpers

private extension ReaderDetailToolbar {

    struct Buttons {
        let saveForLater: UIBarButtonItem
        let reblog: UIBarButtonItem
        let comment: UIBarButtonItem?
        let like: UIBarButtonItem?

        var toolbarItems: [UIBarButtonItem] {
            var items: [UIBarButtonItem] = []

            if #unavailable(iOS 26) {
                items.append(.flexibleSpace())
            }

            items.append(saveForLater)

            if #unavailable(iOS 26) {
                items.append(.flexibleSpace())
            }
            items.append(reblog)

            items.append(.flexibleSpace())

            if let comment {
                items.append(comment)
            }

            if let like {
                if #unavailable(iOS 26) {
                    items.append(.flexibleSpace())
                }
                items.append(like)
            }

            if #unavailable(iOS 26) {
                items.append(.flexibleSpace())
            }

            return items
        }
    }

    struct Constants {
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
        likeCountObserver = post?.observe(\.likeCount, options: [.old, .new]) { [weak self] _, change in
            // ensure that we only update the like button when there's actual change.
            let oldValue = change.oldValue??.intValue ?? 0
            let newValue = change.newValue??.intValue ?? 0
            guard oldValue != newValue else {
                return
            }

            self?.updateToolbarItems()
        }

        commentCountObserver = post?.observe(\.commentCount, options: [.old, .new]) { [weak self] _, change in
            // ensure that we only update the like button when there's actual change.
            let oldValue = change.oldValue??.intValue ?? 0
            let newValue = change.newValue??.intValue ?? 0
            guard oldValue != newValue else {
                return
            }

            self?.updateToolbarItems()
        }
    }

    func unsubscribePostChanges() {
        likeCountObserver?.invalidate()
        commentCountObserver?.invalidate()
    }
}
