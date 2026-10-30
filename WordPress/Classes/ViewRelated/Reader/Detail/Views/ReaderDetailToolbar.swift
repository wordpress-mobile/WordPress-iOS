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

    /// Whether the user is signed in to WordPress.com.
    private let isLoggedIn: () -> Bool

    init(isLoggedIn: @escaping () -> Bool = { ReaderHelpers.isLoggedIn() }) {
        self.isLoggedIn = isLoggedIn
    }

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

        let layout = Layout(
            showsReblogButton: isLoggedIn() && !post.isBlogPrivate,
            showsCommentButton: shouldShowCommentActionButton,
            showsLikeButton: post.isLikesEnabled
        )

        // A like, a save or a new count keeps the same buttons, so update them in place.
        // Rebuild the toolbar only when a button has to be added or removed.
        if let buttons, buttons.layout == layout {
            configure(buttons, for: post)
            return
        }

        let buttons = Buttons(
            // Custom views, so they can sit on the frosted capsules on iOS 26+.
            saveForLater: makeCustomButton(action: #selector(didTapSaveForLater)),
            reblog: layout.showsReblogButton ? makeCustomButton(action: #selector(didTapReblog)) : nil,
            comment: layout.showsCommentButton ? makeCustomButton(action: #selector(didTapComment)) : nil,
            like: layout.showsLikeButton ? makeCustomButton(action: #selector(didTapLike)) : nil
        )
        configure(buttons, for: post)
        self.buttons = buttons
        viewController.setToolbarItems(buttons.toolbarItems, animated: false)
    }

    // MARK: - Configure Buttons

    private func configure(_ buttons: Buttons, for post: ReaderPost) {
        configureSaveForLaterButton(buttons.saveForLater, for: post)
        if let reblog = buttons.reblog {
            configureReblogButton(reblog)
        }
        if let comment = buttons.comment {
            configureCommentButton(comment, for: post)
        }
        if let like = buttons.like {
            configureLikeButton(like, for: post)
        }
        // A capsule doesn't resize by itself when a count changes, like a custom view button.
        buttons.capsules.forEach { ($0.customView as? FrostedCapsule)?.contentDidChange() }
    }

    private func configureSaveForLaterButton(_ button: UIBarButtonItem, for post: ReaderPost) {
        let isSaved = post.isSavedForLater

        configureCustomButton(
            button,
            image: isSaved
                ? WPStyleGuide.ReaderDetail.saveSelectedToolbarIcon : WPStyleGuide.ReaderDetail.saveToolbarIcon,
            title: nil,
            isSelected: isSaved
        )
        button.customView?.accessibilityLabel =
            isSaved ? Constants.savedButtonAccessibilityLabel : Constants.saveButtonAccessibilityLabel
        button.customView?.accessibilityHint = isSaved ? Constants.savedButtonHint : Constants.saveButtonHint
    }

    private func configureReblogButton(_ button: UIBarButtonItem) {
        configureCustomButton(button, image: WPStyleGuide.ReaderDetail.reblogToolbarIcon, title: nil)
        button.customView?.accessibilityLabel = NSLocalizedString(
            "Reblog post",
            comment: "Accessibility label for the reblog button."
        )
        button.customView?.accessibilityHint = NSLocalizedString(
            "Reblog this post",
            comment: "Accessibility hint for the reblog button."
        )
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
        button.customView?.accessibilityHint = isLiked ? Constants.likedButtonHint : Constants.likeButtonHint
    }

    private func makeCustomButton(action: Selector) -> UIBarButtonItem {
        let button = UIButton(configuration: .plain(), primaryAction: nil)
        button.addTarget(self, action: action, for: .touchUpInside)
        return UIBarButtonItem(customView: button)
    }

    private func configureCustomButton(
        _ item: UIBarButtonItem,
        image: UIImage?,
        title: String?,
        isSelected: Bool = false
    ) {
        guard let button = item.customView as? UIButton else { return }

        var configuration = UIButton.Configuration.plain()
        configuration.image = image
        configuration.title = title

        // Apply colors based on display settings and selection state. On the frosted capsules (iOS 26+),
        // only the icon is green: green text on the light capsule is below the 4.5:1 contrast text needs.
        let tintColor = isSelected ? UIAppColor.primary : .label
        if #available(iOS 26, *) {
            let iconColor = isSelected ? FrostedCapsule.selectedColor : .label
            configuration.baseForegroundColor = .label
            configuration.imageColorTransformer = UIConfigurationColorTransformer { _ in iconColor }
        } else {
            configuration.baseForegroundColor = tintColor
        }
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
        // Not `sizeToFit()`: it measures the button at its current width, so a slightly wider count gets clipped
        // to that width instead of the button growing.
        button.frame.size = button.sizeThatFits(UIView.layoutFittingCompressedSize)
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
            if (isLoggedIn() && post.commentsOpen) || commentCount > 0 {
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

    /// Which of the optional buttons the toolbar shows.
    struct Layout: Equatable {
        /// Hidden when the user can't reblog the post: signed out, or a private site.
        let showsReblogButton: Bool
        let showsCommentButton: Bool
        let showsLikeButton: Bool
    }

    struct Buttons {
        let saveForLater: UIBarButtonItem
        let reblog: UIBarButtonItem?
        let comment: UIBarButtonItem?
        let like: UIBarButtonItem?

        /// iOS 26+: the buttons grouped on frosted capsules, which replace the shared Liquid Glass background.
        let capsules: [UIBarButtonItem]

        init(
            saveForLater: UIBarButtonItem,
            reblog: UIBarButtonItem?,
            comment: UIBarButtonItem?,
            like: UIBarButtonItem?
        ) {
            self.saveForLater = saveForLater
            self.reblog = reblog
            self.comment = comment
            self.like = like

            if #available(iOS 26, *) {
                capsules = [[saveForLater, reblog].compactMap { $0 }, [comment, like].compactMap { $0 }]
                    .filter { !$0.isEmpty }
                    .map { group in
                        let item = UIBarButtonItem(customView: FrostedCapsule(views: group.compactMap(\.customView)))
                        item.hidesSharedBackground = true
                        return item
                    }
            } else {
                capsules = []
            }
        }

        var layout: Layout {
            Layout(showsReblogButton: reblog != nil, showsCommentButton: comment != nil, showsLikeButton: like != nil)
        }

        var toolbarItems: [UIBarButtonItem] {
            if #available(iOS 26, *) {
                return [capsules[0], .flexibleSpace()] + capsules.dropFirst()
            }

            var items: [UIBarButtonItem] = []

            if #unavailable(iOS 26) {
                items.append(.flexibleSpace())
            }

            items.append(saveForLater)

            if let reblog {
                if #unavailable(iOS 26) {
                    items.append(.flexibleSpace())
                }
                items.append(reblog)
            }

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

// MARK: - Frosted Capsule

/// A frosted background for a group of toolbar buttons (iOS 26+).
///
/// The shared Liquid Glass background takes its colour from the content under it, and over some images
/// it ends up close in brightness to the icons. This material stays near white or near black, and switches
/// together with the icons, so they stay legible over any content.
private final class FrostedCapsule: UIView {
    private static let height: CGFloat = 48
    private static let spacing: CGFloat = 6
    private static let inset: CGFloat = 8

    /// The color of a selected icon (liked, saved). One shade darker than the regular light mode color,
    /// which falls just below 3:1 on the light capsule over dark or saturated content.
    static let selectedColor = UIColor(light: UIAppColor.primary(.shade50), dark: UIAppColor.primary(.shade30))

    private let views: [UIView]
    private let widths: [NSLayoutConstraint]

    init(views: [UIView]) {
        self.views = views
        self.widths = views.map { $0.widthAnchor.constraint(equalToConstant: 0) }
        super.init(frame: .zero)

        let background = UIVisualEffectView(effect: UIBlurEffect(style: .systemThickMaterial))
        background.clipsToBounds = true
        background.layer.cornerRadius = Self.height / 2
        background.layer.cornerCurve = .continuous

        let stack = UIStackView(arrangedSubviews: views)
        stack.spacing = Self.spacing
        stack.alignment = .center

        addSubview(background)
        addSubview(stack)
        background.translatesAutoresizingMaskIntoConstraints = false
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate(
            widths + [
                background.leadingAnchor.constraint(equalTo: leadingAnchor),
                background.trailingAnchor.constraint(equalTo: trailingAnchor),
                background.topAnchor.constraint(equalTo: topAnchor),
                background.bottomAnchor.constraint(equalTo: bottomAnchor),
                stack.centerYAnchor.constraint(equalTo: centerYAnchor),
                stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Self.inset),
                stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Self.inset),
                heightAnchor.constraint(equalToConstant: Self.height)
            ]
        )
        contentDidChange()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        let content = widths.reduce(0) { $0 + $1.constant } + Self.spacing * CGFloat(max(0, widths.count - 1))
        return CGSize(width: content + 2 * Self.inset, height: Self.height)
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        intrinsicContentSize
    }

    /// Resizes the capsule after its buttons change, e.g. when a count gets wider.
    ///
    /// A button's intrinsic content size lags behind a new configuration until its next layout pass, and the
    /// stack view would size it from that stale value and clip the new title. `sizeThatFits(_:)` is current,
    /// so pin each button to it.
    func contentDidChange() {
        for (view, width) in zip(views, widths) {
            width.constant = ceil(view.sizeThatFits(UIView.layoutFittingCompressedSize).width)
        }
        invalidateIntrinsicContentSize()
        sizeToFit()
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
