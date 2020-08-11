import UIKit

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

    /// If we should hide the comments button
    var shouldHideComments = false

    override func awakeFromNib() {
        super.awakeFromNib()

        applyStyles()

        adjustInsetsForTextDirection()

        prepareActionButtonsForVoiceOver()
    }

    func configure(for post: ReaderPost, in viewController: UIViewController) {
        self.post = post
        self.viewController = viewController

        likeCountObserver = post.observe(\.likeCount, options: .new) { [weak self] _, _ in
            self?.configureLikeActionButton(true)
        }

        commentCountObserver = post.observe(\.commentCount, options: .new) { [weak self] _, _ in
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

        ReaderCommentAction().execute(post: post, origin: viewController)
    }

    @IBAction func didTapLike(_ sender: Any) {
        guard let post = post else {
            return
        }

        if !post.isLiked {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }

        let service = ReaderPostService(managedObjectContext: post.managedObjectContext!)
        service.toggleLiked(for: post, success: nil, failure: { [weak self] (error: Error?) in
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
    }

    // MARK: - Configuration

    private func configureActionButtons() {
        resetActionButton(likeButton)
        resetActionButton(commentButton)
        resetActionButton(saveForLaterButton)
        resetActionButton(reblogButton)

        guard let post = post else {
            return
        }

        // Show likes if logged in, or if likes exist, but not if external
        if (ReaderHelpers.isLoggedIn() || post.likeCount.intValue > 0) && !post.isExternal {
            configureLikeActionButton()
        }

        // Show comments if logged in and comments are enabled, or if comments exist.
        // But only if it is from wpcom (jetpack and external is not yet supported).
        // Nesting this conditional cos it seems clearer that way
        if (post.isWPCom || post.isJetpack) && !shouldHideComments {
            let commentCount = post.commentCount?.intValue ?? 0
            if (ReaderHelpers.isLoggedIn() && post.commentsOpen) || commentCount > 0 {
                configureCommentActionButton()
            }
        }
        // Show reblog only if logged in
        if ReaderHelpers.isLoggedIn(), !post.isPrivate() {
            configureReblogButton()
        }
        configureSaveForLaterButton()
    }

    private func resetActionButton(_ button: UIButton) {
        button.setTitle(nil, for: UIControl.State())
        button.setTitle(nil, for: .highlighted)
        button.setTitle(nil, for: .disabled)
        button.setImage(nil, for: UIControl.State())
        button.setImage(nil, for: .highlighted)
        button.setImage(nil, for: .disabled)
        button.isSelected = false
        button.isHidden = true
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
        button.isHidden = false

        WPStyleGuide.applyReaderActionButtonStyle(button)
    }

    private func configureLikeActionButton(_ animated: Bool = false) {
        likeButton.isEnabled = ReaderHelpers.isLoggedIn()
        // as by design spec, only display like counts
        let likeCount = post?.likeCount()?.intValue ?? 0
        let title = likeCount > 0 ? "\(likeCount)" : ""

        let selected = post?.isLiked ?? false
        let likeImage = UIImage(named: "icon-reader-like")
        let likedImage = UIImage(named: "icon-reader-liked")

        configureActionButton(likeButton, title: title, image: likeImage, highlightedImage: likedImage, selected: selected)

        if animated {
            playLikeButtonAnimation()
        }
    }

    /// Uses the configuration in WPStyleGuide for the reblog button
    private func configureReblogButton() {
        reblogButton.isHidden = false
        WPStyleGuide.applyReaderReblogActionButtonStyle(reblogButton, showTitle: false)
    }

    private func playLikeButtonAnimation() {
        let likeImageView = likeButton.imageView!
        let frame = likeButton.convert(likeImageView.frame, from: likeImageView)

        let imageView = UIImageView(image: UIImage(named: "icon-reader-liked"))
        imageView.frame = frame
        likeButton.addSubview(imageView)

        let animationDuration = 0.3

        if likeButton.isSelected {
            // Prep a mask to hide the likeButton's image, since changes to visiblility and alpha are ignored
            let mask = UIView(frame: frame)
            mask.backgroundColor = backgroundColor
            likeButton.addSubview(mask)
            likeButton.bringSubviewToFront(imageView)

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
        guard let commentCount = post?.commentCount else {
            return
        }

        let title = commentCount.stringValue
        let image = UIImage(named: "icon-reader-comment")?.imageFlippedForRightToLeftLayoutDirection()
        let highlightImage = UIImage(named: "icon-reader-comment-highlight")?.imageFlippedForRightToLeftLayoutDirection()
        configureActionButton(commentButton, title: title, image: image, highlightedImage: highlightImage, selected: false)
    }

    private func configureSaveForLaterButton() {
        WPStyleGuide.applyReaderSaveForLaterButtonStyle(saveForLaterButton)
        WPStyleGuide.applyReaderSaveForLaterButtonTitles(saveForLaterButton, showTitle: false)

        saveForLaterButton.isHidden = false
        saveForLaterButton.isSelected = post?.isSavedForLater ?? false
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
    }

    private func prepareReblogForVoiceOver() {
        reblogButton.accessibilityLabel = NSLocalizedString("Reblog post", comment: "Accessibility label for the reblog button.")
        reblogButton.accessibilityHint = NSLocalizedString("Reblog this post", comment: "Accessibility hint for the reblog button.")
        reblogButton.accessibilityTraits = UIAccessibilityTraits.button
    }
}
