import UIKit

protocol ReaderDetailToolbarDelegate: AnyObject {
    func didTapLikeButton(isLiked: Bool)
}

class ReaderDetailToolbar: UIView, NibLoadable {
    @IBOutlet weak var dividerView: UIView!
    @IBOutlet weak var saveForLaterButton: UIButton!
    @IBOutlet weak var reblogButton: PostMetaButton!
    @IBOutlet weak var commentButton: PostMetaButton!
    @IBOutlet weak var likeButton: PostMetaButton!

    /// These are added to dynamically apply changes based on the `readerImprovements` feature flag.
    /// Once the flag is removed, we should remove these and apply the changes directly on the XIB file.
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var stackViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var stackViewTrailingConstraint: NSLayoutConstraint!

    /// The reader post that the toolbar interacts with
    private var post: ReaderPost?

    /// The VC where the toolbar is inserted
    private weak var viewController: UIViewController?

    /// An observer of the number of likes of the post
    private var likeCountObserver: NSKeyValueObservation?

    /// An observer of the number of likes of the post
    private var commentCountObserver: NSKeyValueObservation?

    /// If we should hide the comments button
    var shouldHideComments = false

    weak var delegate: ReaderDetailToolbarDelegate? = nil

    private var likeButtonTitle: String {
        guard let post,
              FeatureFlag.readerImprovements.enabled else {
            return likeLabel(count: likeCount)
        }
        return post.isLiked ? Constants.likedButtonTitle : Constants.likeButtonTitle
    }

    private var likeCount: Int {
        post?.likeCount.intValue ?? 0
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        applyStyles()

        adjustInsetsForTextDirection()

        prepareActionButtonsForVoiceOver()
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

        likeCountObserver = post.observe(\.likeCount, options: [.old, .new]) { [weak self] updatedPost, change in
            // ensure that we only update the like button when there's actual change.
            let oldValue = change.oldValue??.intValue ?? 0
            let newValue = change.newValue??.intValue ?? 0
            guard oldValue != newValue else {
                return
            }

            self?.configureLikeActionButton(true)
            self?.delegate?.didTapLikeButton(isLiked: updatedPost.isLiked)
        }

        commentCountObserver = post.observe(\.commentCount, options: [.old, .new]) { [weak self] _, change in
            // ensure that we only update the like button when there's actual change.
            let oldValue = change.oldValue??.intValue ?? 0
            let newValue = change.newValue??.intValue ?? 0
            guard oldValue != newValue else {
                return
            }

            self?.configureCommentActionButton()
        }

        configureActionButtons()
    }

    deinit {
        likeCountObserver?.invalidate()
        commentCountObserver?.invalidate()
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
        guard let post = post, let viewController = viewController else {
            return
        }

        ReaderReblogAction().execute(readerPost: post, origin: viewController, reblogSource: .detail)
    }

    @IBAction func didTapComment(_ sender: Any) {
        guard let post = post, let viewController = viewController else {
            return
        }

        ReaderCommentAction().execute(post: post, origin: viewController, source: .postDetails)
    }

    @IBAction func didTapLike(_ sender: Any) {
        guard let post = post else {
            return
        }

        if !post.isLiked {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }

        let service = ReaderPostService(coreDataStack: ContextManager.shared)
        service.toggleLiked(for: post, success: { [weak self] in
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
        backgroundColor = .listForeground
        dividerView.backgroundColor = .divider

        WPStyleGuide.applyReaderCardActionButtonStyle(commentButton)
        WPStyleGuide.applyReaderCardActionButtonStyle(likeButton)

        // TODO: Apply changes on the XIB directly once the `readerImprovements` flag is removed.
        if FeatureFlag.readerImprovements.enabled {
            stackView.distribution = .fillEqually
            stackView.spacing = 16.0
            stackViewLeadingConstraint.constant = 16.0
            stackViewTrailingConstraint.constant = 16.0
        }
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
        let disabledColor = UIColor(light: .muriel(color: .gray, .shade10),
                                    dark: .textQuaternary)

        WPStyleGuide.applyReaderActionButtonStyle(button,
                                                  titleColor: .textSubtle,
                                                  imageColor: .textSubtle,
                                                  disabledColor: disabledColor)

        /// Configure the UIButton so it displays the button image on top of the title label.
        /// Previously, this would be achieved through titleEdgeInsets and imageEdgeInsets, but these
        /// will be deprecated soon. The new way to do this is through `UIButton.Configuration`, by setting
        /// `imagePlacement` to `.top`.
        ///
        /// TODO: remove unused styles once the `readerImprovements` flag is removed.
        guard FeatureFlag.readerImprovements.enabled else {
            return
        }

        var configuration = UIButton.Configuration.plain()

        // Vertically stack the button's image and title.
        configuration.imagePlacement = .top
        configuration.contentInsets = Constants.buttonContentInsets
        configuration.imagePadding = Constants.buttonImagePadding

        /// Override the button's title label font.
        /// When the button's configuration exists, updating the font via `titleLabel` no longer works somehow.
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = WPStyleGuide.fontForTextStyle(.footnote)
            return outgoing
        }

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
        guard let post = post else {
            return
        }

        let selected = post.isLiked
        likeButton.isEnabled = (ReaderHelpers.isLoggedIn() || likeCount > 0) && !post.isExternal

        configureActionButton(likeButton,
                              title: likeButtonTitle,
                              image: Constants.likeImage,
                              highlightedImage: Constants.likedImage,
                              selected: selected)

        if animated {
            playLikeButtonAnimation()
        }
    }

    /// Uses the configuration in WPStyleGuide for the reblog button
    private func configureReblogButton() {
        guard let post = post else {
            return
        }

        reblogButton.isEnabled = ReaderHelpers.isLoggedIn() && !post.isPrivate()
        WPStyleGuide.applyReaderReblogActionButtonStyle(reblogButton, showTitle: false)

        configureActionButtonStyle(reblogButton)
    }

    private func playLikeButtonAnimation() {
        guard let likeImageView = likeButton.imageView else {
            return
        }

        let animationDuration = 0.3
        let imageView = UIImageView(image: Constants.likedImage)

        if FeatureFlag.readerImprovements.enabled {
            /// When using `UIButton.Configuration`, calling `bringSubviewToFront` somehow does not work.
            /// To work around this, let's add the faux image to the image view instead, so it can be
            /// properly placed in front of the masking view.
            imageView.translatesAutoresizingMaskIntoConstraints = false
            likeImageView.addSubview(imageView)
            likeImageView.pinSubviewAtCenter(imageView)
        } else {
            likeButton.addSubview(imageView)
        }

        if likeButton.isSelected {
            // Prep a mask to hide the likeButton's image, since changes to visibility and alpha are ignored
            let mask = UIView(frame: frame)
            mask.backgroundColor = backgroundColor
            likeImageView.addSubview(mask)
            likeImageView.pinSubviewToAllEdges(mask)
            mask.translatesAutoresizingMaskIntoConstraints = false

            if FeatureFlag.readerImprovements.enabled {
                likeImageView.bringSubviewToFront(imageView)
            } else {
                likeButton.bringSubviewToFront(imageView)
            }

            // Configure starting state
            imageView.alpha = 0.0
            let angle = (-270.0 * CGFloat.pi) / 180.0
            let rotate = CGAffineTransform(rotationAngle: angle)
            let scale = CGAffineTransform(scaleX: 3.0, y: 3.0)
            imageView.transform = rotate.concatenating(scale)

            // Perform the animations
            UIView.animate(withDuration: animationDuration,
                animations: { () in
                    let angle = (1.0 * CGFloat.pi) / 180.0
                    let rotate = CGAffineTransform(rotationAngle: angle)
                    let scale = CGAffineTransform(scaleX: 0.75, y: 0.75)
                    imageView.transform = rotate.concatenating(scale)
                    imageView.alpha = 1.0
                    imageView.center = likeImageView.center // In case the button's imageView shifted position
                },
                completion: { (_) in
                    UIView.animate(withDuration: animationDuration,
                        animations: { () in
                            imageView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
                        },
                        completion: { (_) in
                            mask.removeFromSuperview()
                            imageView.removeFromSuperview()
                    })
            })

        } else {

            UIView .animate(withDuration: animationDuration,
                animations: { () -> Void in
                    let angle = (120.0 * CGFloat.pi) / 180.0
                    let rotate = CGAffineTransform(rotationAngle: angle)
                    let scale = CGAffineTransform(scaleX: 3.0, y: 3.0)
                    imageView.transform = rotate.concatenating(scale)
                    imageView.alpha = 0
                },
                completion: { (_) in
                    imageView.removeFromSuperview()
            })

        }
    }

    private func configureCommentActionButton() {
        commentButton.isEnabled = shouldShowCommentActionButton

        commentButton.setImage(Constants.commentImage, for: .normal)
        commentButton.setImage(Constants.commentSelectedImage, for: .selected)
        commentButton.setImage(Constants.commentSelectedImage, for: .highlighted)
        commentButton.setImage(Constants.commentSelectedImage, for: [.highlighted, .selected])
        commentButton.setImage(Constants.commentImage, for: .disabled)

        configureActionButtonStyle(commentButton)
    }

    private var shouldShowCommentActionButton: Bool {
        // Show comments if logged in and comments are enabled, or if comments exist.
        // But only if it is from wpcom (jetpack and external is not yet supported).
        // Nesting this conditional cos it seems clearer that way
        guard let post = post else {
            return false
        }

        if (post.isWPCom || post.isJetpack) && !shouldHideComments {
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

        saveForLaterButton.isSelected = post?.isSavedForLater ?? false

        configureActionButtonStyle(saveForLaterButton)
    }

    private func adjustInsetsForTextDirection() {
        let buttonsToAdjust: [UIButton] = [
            likeButton,
            commentButton,
            saveForLaterButton,
            reblogButton]
        for button in buttonsToAdjust {
            button.flipInsetsForRightToLeftLayoutDirection()
        }
    }

    fileprivate func configureButtonTitles() {
        guard let post = post else {
            return
        }

        let commentCount = post.commentCount()?.intValue ?? 0
        let commentTitle = FeatureFlag.readerImprovements.enabled ? Constants.commentButtonTitle : commentLabel(count: commentCount)
        let showTitle: Bool = FeatureFlag.readerImprovements.enabled || traitCollection.horizontalSizeClass != .compact

        likeButton.setTitle(likeButtonTitle, for: .normal)
        likeButton.setTitle(likeButtonTitle, for: .highlighted)

        commentButton.setTitle(commentTitle, for: .normal)
        commentButton.setTitle(commentTitle, for: .highlighted)

        WPStyleGuide.applyReaderSaveForLaterButtonTitles(saveForLaterButton, showTitle: showTitle)
        WPStyleGuide.applyReaderReblogActionButtonTitle(reblogButton, showTitle: showTitle)
    }

    private func commentLabel(count: Int) -> String {
        if traitCollection.horizontalSizeClass == .compact {
            return count > 0 ? String(count) : ""
        } else {
            return WPStyleGuide.commentCountForDisplay(count)
        }
    }

    private func likeLabel(count: Int) -> String {
        if traitCollection.horizontalSizeClass == .compact {
            return count > 0 ? String(count) : ""
        } else {
            return WPStyleGuide.likeCountForDisplay(count)
        }
    }

    // MARK: - Analytics

    private func trackArticleDetailsLikedOrUnliked() {
        guard let post = post else {
            return
        }

        let stat: WPAnalyticsStat  = post.isLiked
            ? .readerArticleDetailLiked
            : .readerArticleDetailUnliked

        var properties = [AnyHashable: Any]()
        properties[WPAppAnalyticsKeyBlogID] = post.siteID
        properties[WPAppAnalyticsKeyPostID] = post.postID
        WPAnalytics.track(stat, withProperties: properties)
    }

    // MARK: - Voice Over

    private func prepareActionButtonsForVoiceOver() {
        let isSavedForLater = post?.isSavedForLater ?? false
        saveForLaterButton.accessibilityLabel = isSavedForLater ? NSLocalizedString("Saved Post", comment: "Accessibility label for the 'Save Post' button when a post has been saved.") : NSLocalizedString("Save post", comment: "Accessibility label for the 'Save Post' button.")
        saveForLaterButton.accessibilityHint = isSavedForLater ? NSLocalizedString("Remove this post from my saved posts.", comment: "Accessibility hint for the 'Save Post' button when a post is already saved.") : NSLocalizedString("Saves this post for later.", comment: "Accessibility hint for the 'Save Post' button.")

        let isLiked = post?.isLiked ?? false
        likeButton.accessibilityHint = isLiked ? Constants.likedButtonHint : Constants.likeButtonHint

        commentButton.accessibilityHint = Constants.commentButtonHint
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
        static let buttonContentInsets = NSDirectionalEdgeInsets(top: 2.0, leading: 0, bottom: 0, trailing: 0)
        static let buttonImagePadding: CGFloat = 4.0

        static var likeImage: UIImage? {
            if FeatureFlag.readerImprovements.enabled {
                // reduce gridicon images to 20x20 since they don't have intrinsic padding.
                return UIImage(named: "icon-reader-like")?
                    .resizedImage(WPStyleGuide.Detail.actionBarIconSize, interpolationQuality: .default)
                    .withRenderingMode(.alwaysTemplate)
            }
            return UIImage(named: "icon-reader-like")
        }

        static var likedImage: UIImage? {
            if FeatureFlag.readerImprovements.enabled {
                // reduce gridicon images to 20x20 since they don't have intrinsic padding.
                return UIImage(named: "icon-reader-liked")?
                    .resizedImage(WPStyleGuide.Detail.actionBarIconSize, interpolationQuality: .default)
                    .withRenderingMode(.alwaysTemplate)
            }
            return UIImage(named: "icon-reader-liked")
        }

        static let commentImage = UIImage(named: "icon-reader-comment-outline")?
            .imageFlippedForRightToLeftLayoutDirection()
            .resizedImage(WPStyleGuide.Detail.actionBarIconSize, interpolationQuality: .high)
            .withRenderingMode(.alwaysTemplate)

        static let commentSelectedImage = UIImage(named: "icon-reader-comment-outline-highlighted")?
            .imageFlippedForRightToLeftLayoutDirection()
            .resizedImage(WPStyleGuide.Detail.actionBarIconSize, interpolationQuality: .high)
            .withRenderingMode(.alwaysTemplate)

        // MARK: Strings

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
            value: "Tap to like this post",
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
            value: "Tap to unlike this post",
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

        static let commentButtonHint = NSLocalizedString(
            "reader.detail.toolbar.comment.button.a11y.hint",
            value: "Tap to view comments for this post",
            comment: """
                Accessibility hint for the Comment button.
                Tapping on the button takes the user to the comment threads for the post.
                """
        )
    }
}
