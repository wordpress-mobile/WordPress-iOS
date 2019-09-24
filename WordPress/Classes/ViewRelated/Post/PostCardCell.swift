import UIKit
import Gridicons

class PostCardCell: UITableViewCell, ConfigurablePostView {
    @IBOutlet weak var featuredImageStackView: UIStackView!
    @IBOutlet weak var featuredImage: CachedAnimatedImageView!
    @IBOutlet weak var featuredImageHeight: NSLayoutConstraint!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var snippetLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet weak var separatorLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var statusView: UIStackView!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var editButton: UIButton!
    @IBOutlet weak var retryButton: UIButton!
    @IBOutlet weak var cancelAutoUploadButton: UIButton!
    @IBOutlet weak var publishButton: UIButton!
    @IBOutlet weak var viewButton: UIButton!
    @IBOutlet weak var trashButton: UIButton!
    @IBOutlet weak var moreButton: UIButton!
    @IBOutlet weak var actionBarView: UIStackView!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var upperBorder: UIView!
    @IBOutlet weak var bottomBorder: UIView!
    @IBOutlet weak var actionBarSeparator: UIView!
    @IBOutlet weak var topPadding: NSLayoutConstraint!
    @IBOutlet weak var contentStackView: UIStackView!
    @IBOutlet weak var ghostStackView: UIStackView!
    @IBOutlet weak var ghostHolder: UIView!

    lazy var imageLoader: ImageLoader = {
        return ImageLoader(imageView: featuredImage, gifStrategy: .mediumGIFs)
    }()

    private var post: Post?
    private var viewModel: PostCardStatusViewModel?
    private var currentLoadedFeaturedImage: String?
    private weak var interactivePostViewDelegate: InteractivePostViewDelegate?
    private weak var actionSheetDelegate: PostActionSheetDelegate?
    var isAuthorHidden: Bool = false {
        didSet {
            authorLabel.isHidden = isAuthorHidden
            separatorLabel.isHidden = isAuthorHidden
        }
    }

    func configure(with post: Post) {
        if post != self.post {
            viewModel = PostCardStatusViewModel(post: post)
        }

        self.post = post

        resetGhost()
        configureFeaturedImage()
        configureTitle()
        configureSnippet()
        configureDate()
        configureAuthor()
        configureStatusLabel()
        configureProgressView()
        configureActionBar()
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        applyStyles()
        adjustInsetsForTextDirection()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if previousTraitCollection?.preferredContentSizeCategory != traitCollection.preferredContentSizeCategory {
            applyStyles()
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageLoader.prepareForReuse()
        setNeedsDisplay()
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        // Don't respond to taps in margins.
        if !containerView.frame.contains(point) {
            return nil
        }
        return super.hitTest(point, with: event)
    }

    @IBAction func edit() {
        guard let post = post else {
            return
        }

        interactivePostViewDelegate?.edit(post)
    }

    @IBAction func view() {
        guard let post = post else {
            return
        }

        interactivePostViewDelegate?.view(post)
    }

    @IBAction func more(_ sender: Any) {
        guard let button = sender as? UIButton, let viewModel = viewModel else {
            return
        }

        actionSheetDelegate?.showActionSheet(viewModel, from: button)
    }

    @IBAction func retry() {
        guard let post = post else {
            return
        }

        interactivePostViewDelegate?.retry(post)
    }

    @IBAction func cancelAutoUpload() {
        if let post = post {
            interactivePostViewDelegate?.cancelAutoUpload(post)
        }
    }

    @IBAction func publish() {
        if let post = post {
            interactivePostViewDelegate?.publish(post)
        }
    }

    @IBAction func trash() {
        if let post = post {
            interactivePostViewDelegate?.trash(post)
        }
    }

    private func applyStyles() {
        WPStyleGuide.applyPostCardStyle(self)
        WPStyleGuide.applyPostTitleStyle(titleLabel)
        WPStyleGuide.applyPostSnippetStyle(snippetLabel)
        WPStyleGuide.applyPostDateStyle(dateLabel)
        WPStyleGuide.applyPostDateStyle(separatorLabel)
        WPStyleGuide.applyPostDateStyle(authorLabel)
        WPStyleGuide.configureLabel(statusLabel, textStyle: UIFont.TextStyle.subheadline)
        WPStyleGuide.applyPostProgressViewStyle(progressView)
        WPStyleGuide.applyPostButtonStyle(editButton)
        WPStyleGuide.applyPostButtonStyle(retryButton)
        WPStyleGuide.applyPostButtonStyle(viewButton)
        WPStyleGuide.applyPostButtonStyle(moreButton)
        WPStyleGuide.applyPostButtonStyle(cancelAutoUploadButton)
        WPStyleGuide.applyPostButtonStyle(publishButton)
        WPStyleGuide.applyPostButtonStyle(trashButton)

        setupActionBar()
        setupFeaturedImage()
        setupBorders()
        setupBackgrounds()
        setupLabels()
        setupSeparatorLabel()
        setupSelectedBackgroundView()
        setupReadableGuideForiPad()
    }

    private func setupFeaturedImage() {
        featuredImageHeight.constant = Constants.featuredImageHeightConstant
    }

    private func resetGhost() {
        isUserInteractionEnabled = true
        actionBarView.layer.opacity = Constants.actionBarOpacity
        toggleGhost(visible: false)
    }

    private func configureFeaturedImage() {
        guard let post = post?.latest() else {
            return
        }

        if let url = post.featuredImageURL,
            let desiredWidth = UIApplication.shared.keyWindow?.frame.size.width {
            featuredImageStackView.isHidden = false
            topPadding.constant = Constants.margin
            loadFeaturedImageIfNeeded(url, preferredSize: CGSize(width: desiredWidth, height: featuredImage.frame.height))
        } else {
            featuredImageStackView.isHidden = true
            topPadding.constant = Constants.paddingWithoutImage
        }
    }

    private func loadFeaturedImageIfNeeded(_ url: URL, preferredSize: CGSize) {
        guard let post = post else {
            return
        }

        if currentLoadedFeaturedImage != url.absoluteString {
            currentLoadedFeaturedImage = url.absoluteString
            imageLoader.loadImage(with: url, from: post, preferredSize: preferredSize)
        }
    }

    private func configureTitle() {
        guard let post = post?.latest() else {
            return
        }

        if let titleForDisplay = post.titleForDisplay() {
            WPStyleGuide.applyPostTitleStyle(titleForDisplay, into: titleLabel)
        }
    }

    private func configureSnippet() {
        guard let post = post?.latest() else {
            return
        }

        if let contentPreviewForDisplay = post.contentPreviewForDisplay(),
            !contentPreviewForDisplay.isEmpty {
            WPStyleGuide.applyPostSnippetStyle(contentPreviewForDisplay, into: snippetLabel)
            snippetLabel.isHidden = false
        } else {
            snippetLabel.isHidden = true
        }
    }

    private func configureDate() {
        guard let post = post?.latest() else {
            return
        }

        dateLabel.text = post.dateStringForDisplay()
    }

    private func configureAuthor() {
        guard let viewModel = viewModel else {
            return
        }

        authorLabel.text = viewModel.author
    }

    private func configureStatusLabel() {
        guard let viewModel = viewModel else {
            return
        }

        let status = viewModel.statusAndBadges(separatedBy: Constants.separator)
        statusLabel.textColor = viewModel.statusColor
        statusLabel.text = status
        statusView.isHidden = status.isEmpty
    }

    private func configureProgressView() {
        guard let viewModel = viewModel else {
            return
        }

        let shouldHide = viewModel.shouldHideProgressView

        progressView.isHidden = shouldHide

        progressView.progress = viewModel.progress

        if !shouldHide && viewModel.progressBlock == nil {
            viewModel.progressBlock = { [weak self] progress in
                self?.progressView.setProgress(progress, animated: true)
                if progress >= 1.0, let post = self?.post {
                    self?.configure(with: post)
                }
            }
        }
    }

    private func configureActionBar() {
        guard let viewModel = viewModel else {
            return
        }

        // Convert to Set for O(1) complexity of contains()
        let primaryButtons = Set(viewModel.buttonGroups.primary)

        editButton.isHidden = !primaryButtons.contains(.edit)
        retryButton.isHidden = !primaryButtons.contains(.retry)
        cancelAutoUploadButton.isHidden = !primaryButtons.contains(.cancelAutoUpload)
        publishButton.isHidden = !primaryButtons.contains(.publish)
        viewButton.isHidden = !primaryButtons.contains(.view)
        moreButton.isHidden = !primaryButtons.contains(.more)
        trashButton.isHidden = !primaryButtons.contains(.trash)
    }

    private func setupBorders() {
        WPStyleGuide.applyBorderStyle(upperBorder)
        WPStyleGuide.applyBorderStyle(bottomBorder)
        WPStyleGuide.applyBorderStyle(actionBarSeparator)
    }

    private func setupBackgrounds() {
        containerView.backgroundColor = .listForeground
        titleLabel.backgroundColor = .listForeground
        snippetLabel.backgroundColor = .listForeground
        dateLabel.backgroundColor = .listForeground
        authorLabel.backgroundColor = .listForeground
        separatorLabel.backgroundColor = .listForeground
        ghostHolder.backgroundColor = .listForeground
    }

    private func setupActionBar() {
        actionBarView.subviews.compactMap({ $0 as? UIButton }).forEach { button in
            WPStyleGuide.applyActionBarButtonStyle(button)
        }
    }

    private func setupLabels() {
        retryButton.setTitle(NSLocalizedString("Retry", comment: "Label for the retry post upload button. Tapping attempts to upload the post again."), for: .normal)
        retryButton.setImage(Gridicon.iconOfType(.refresh, withSize: CGSize(width: 18, height: 18)), for: .normal)

        cancelAutoUploadButton.setTitle(NSLocalizedString("Cancel", comment: "Label for the auto-upload cancelation button in the post list. Tapping will prevent the app from auto-uploading the post."),
                                        for: .normal)

        editButton.setTitle(NSLocalizedString("Edit", comment: "Label for the edit post button. Tapping displays the editor."), for: .normal)

        viewButton.setTitle(NSLocalizedString("View", comment: "Label for the view post button. Tapping displays the post as it appears on the web."), for: .normal)

        moreButton.setTitle(NSLocalizedString("More", comment: "Label for the more post button. Tapping displays an action sheet with post options."), for: .normal)
    }

    private func setupSelectedBackgroundView() {
        if let selectedBackgroundView = selectedBackgroundView {
            WPStyleGuide.insertSelectedBackgroundSubview(selectedBackgroundView, topMargin: Constants.margin)
        }
    }

    private func setupReadableGuideForiPad() {
        guard WPDeviceIdentification.isiPad() else { return }

        contentStackView.leadingAnchor.constraint(equalTo: readableContentGuide.leadingAnchor).isActive = true
        contentStackView.trailingAnchor.constraint(equalTo: readableContentGuide.trailingAnchor).isActive = true

        contentStackView.subviews.forEach { $0.changeLayoutMargins(left: 0, right: 0) }
    }

    private func setupSeparatorLabel() {
        separatorLabel.text = Constants.separator
    }

    private func adjustInsetsForTextDirection() {
        actionBarView.subviews.compactMap({ $0 as? UIButton }).forEach {
            $0.flipInsetsForRightToLeftLayoutDirection()
        }
    }

    private enum Constants {
        static let separator = " · "
        static let margin: CGFloat = 16
        static let paddingWithoutImage: CGFloat = 8
        static let featuredImageHeightConstant: CGFloat = WPDeviceIdentification.isiPad() ? 226 : 100
        static let actionBarOpacity: Float = 1
    }
}

extension PostCardCell: InteractivePostView {
    func setInteractionDelegate(_ delegate: InteractivePostViewDelegate) {
        interactivePostViewDelegate = delegate
    }

    func setActionSheetDelegate(_ delegate: PostActionSheetDelegate) {
        actionSheetDelegate = delegate
    }
}

extension PostCardCell: GhostableView {
    func ghostAnimationWillStart() {
        progressView.isHidden = true
        actionBarView.layer.opacity = GhostConstants.actionBarOpacity
        isUserInteractionEnabled = false

        topPadding.constant = Constants.margin

        toggleGhost(visible: true)

        actionBarView.isGhostableDisabled = true
        upperBorder.isGhostableDisabled = true
        bottomBorder.isGhostableDisabled = true
    }

    private func toggleGhost(visible: Bool) {
        contentStackView.subviews.forEach { $0.isHidden = visible }
        ghostStackView.isHidden = !visible
        actionBarView.isHidden = false
    }

    private enum GhostConstants {
        static let actionBarOpacity: Float = 0.5
    }
}
