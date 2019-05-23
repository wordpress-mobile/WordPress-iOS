import UIKit
import Gridicons

class PostCell: UITableViewCell, ConfigurablePostView {
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
    @IBOutlet weak var viewButton: UIButton!
    @IBOutlet weak var moreButton: UIButton!
    @IBOutlet weak var actionBarView: UIStackView!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var upperBorder: UIView!
    @IBOutlet weak var bottomBorder: UIView!
    @IBOutlet weak var topPadding: NSLayoutConstraint!
    @IBOutlet weak var contentStackView: UIStackView!
    @IBOutlet weak var titleAndSnippetView: UIStackView!
    @IBOutlet weak var topMargin: NSLayoutConstraint!

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

        configureItself()
        configureFeaturedImage()
        configureTitleAndSnippetView()
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
        guard let button = sender as? UIButton, let post = post else {
            return
        }

        actionSheetDelegate?.showActionSheet(post, from: button)
    }

    @IBAction func retry() {
        guard let post = post else {
            return
        }

        interactivePostViewDelegate?.retry(post)
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

        setupActionBar()
        setupFeaturedImage()
        setupBorders()
        setupLabels()
        setupSeparatorLabel()
        setupSelectedBackgroundView()
        setupReadableGuideForiPad()
    }

    private func setupFeaturedImage() {
        featuredImageHeight.constant = Constants.featuredImageHeightConstant
    }

    private func configureItself() {
        isUserInteractionEnabled = true
        contentStackView.spacing = Constants.contentSpacing
        titleAndSnippetView.spacing = Constants.titleAndSnippetSpacing
        actionBarView.layer.opacity = Constants.actionBarOpacity
    }

    private func configureFeaturedImage() {
        guard let post = post?.latest() else {
            return
        }

        if let url = post.featuredImageURLForDisplay(),
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

    private func configureTitleAndSnippetView() {
        titleAndSnippetView.setLayoutMargin(top: Constants.titleTopMargin, bottom: 0)
    }

    private func configureTitle() {
        guard let post = post?.latest() else {
            return
        }

        if let titleForDisplay = post.titleForDisplay() {
            titleLabel.attributedText = NSAttributedString(string: titleForDisplay, attributes: WPStyleGuide.postCardTitleAttributes() as? [NSAttributedString.Key: Any])
            titleLabel.lineBreakMode = .byTruncatingTail
        }
    }

    private func configureSnippet() {
        guard let post = post?.latest() else {
            return
        }

        if let contentPreviewForDisplay = post.contentPreviewForDisplay(),
            !contentPreviewForDisplay.isEmpty {
            snippetLabel.attributedText = NSAttributedString(string: contentPreviewForDisplay, attributes: WPStyleGuide.postCardSnippetAttributes() as? [NSAttributedString.Key: Any])
            snippetLabel.isHidden = false
            snippetLabel.lineBreakMode = .byTruncatingTail
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
        guard let post = post else {
            return
        }

        retryButton.isHidden = !post.isFailed
        viewButton.isHidden = post.isFailed
    }

    private func setupBorders() {
        [upperBorder, bottomBorder].forEach { border in
            border?.heightAnchor.constraint(equalToConstant: Constants.borderHeight).isActive = true
            border?.backgroundColor = WPStyleGuide.postCardBorderColor()
        }
    }

    private func setupActionBar() {
        actionBarView.subviews.compactMap({ $0 as? UIButton }).forEach { button in
            button.flipInsetsForRightToLeftLayoutDirection()
            button.setImage(button.imageView?.image?.imageWithTintColor(WPStyleGuide.grey()), for: .normal)
            button.setTitleColor(WPStyleGuide.grey(), for: .normal)
            button.setTitleColor(WPStyleGuide.darkGrey(), for: .highlighted)
            button.setTitleColor(WPStyleGuide.darkGrey(), for: .selected)
        }

        actionBarView.changeLayoutMargins(top: Constants.margin - contentStackView.spacing)
    }

    private func setupLabels() {
        retryButton.setTitle(NSLocalizedString("Retry", comment: "Label for the retry post upload button. Tapping attempts to upload the post again."), for: .normal)
        retryButton.setImage(Gridicon.iconOfType(.refresh, withSize: CGSize(width: 18, height: 18)), for: .normal)
        retryButton.isHidden = true

        editButton.setTitle(NSLocalizedString("Edit", comment: "Label for the edit post button. Tapping displays the editor."), for: .normal)

        viewButton.setTitle(NSLocalizedString("View", comment: "Label for the view post button. Tapping displays the post as it appears on the web."), for: .normal)

        moreButton.setTitle(NSLocalizedString("More", comment: "Label for the more post button. Tapping displays an action sheet with post options."), for: .normal)
    }

    private func setupSelectedBackgroundView() {
        if let selectedBackgroundView = selectedBackgroundView {
            let marginMask = UIView()
            selectedBackgroundView.addSubview(marginMask)
            marginMask.translatesAutoresizingMaskIntoConstraints = false
            marginMask.leadingAnchor.constraint(equalTo: selectedBackgroundView.leadingAnchor).isActive = true
            marginMask.topAnchor.constraint(equalTo: selectedBackgroundView.topAnchor).isActive = true
            marginMask.trailingAnchor.constraint(equalTo: selectedBackgroundView.trailingAnchor).isActive = true
            marginMask.heightAnchor.constraint(equalToConstant: Constants.margin).isActive = true
            marginMask.backgroundColor = WPStyleGuide.greyLighten30()
        }
    }

    private func setupReadableGuideForiPad() {
        guard WPDeviceIdentification.isiPad() else { return }

        contentStackView.leadingAnchor.constraint(equalTo: readableContentGuide.leadingAnchor).isActive = true
        contentStackView.trailingAnchor.constraint(equalTo: readableContentGuide.trailingAnchor).isActive = true

        contentStackView.subviews.forEach { $0.changeLayoutMargins(left: 0, right: 0) }

        topMargin.constant = Constants.margin
    }

    private func setupSeparatorLabel() {
        separatorLabel.text = Constants.separator
    }

    private func adjustInsetsForTextDirection() {
        actionBarView.subviews.compactMap({ $0 as? UIButton }).forEach {
            $0.flipInsetsForRightToLeftLayoutDirection()
        }
    }

    func setActionSheetDelegate(_ delegate: PostActionSheetDelegate) {
        actionSheetDelegate = delegate
    }

    private enum Constants {
        static let separator = " · "
        static let margin: CGFloat = WPDeviceIdentification.isiPad() ? 20 : 16
        static let paddingWithoutImage: CGFloat = 8
        static let titleTopMargin: CGFloat = WPDeviceIdentification.isiPad() ? 6 : 2
        static let featuredImageHeightConstant: CGFloat = WPDeviceIdentification.isiPad() ? 226 : 100
        static let borderHeight: CGFloat = 1.0 / UIScreen.main.scale
        static let contentSpacing: CGFloat = 8
        static let titleAndSnippetSpacing: CGFloat = 3
        static let actionBarOpacity: Float = 1
    }
}

extension PostCell: InteractivePostView {
    func setInteractionDelegate(_ delegate: InteractivePostViewDelegate) {
        interactivePostViewDelegate = delegate
    }
}

extension PostCell: GhostableView {
    func ghostAnimationWillStart() {
        WPStyleGuide.configureLabel(titleLabel, textStyle: .headline)
        WPStyleGuide.configureLabel(snippetLabel, textStyle: .subheadline)
        WPStyleGuide.configureLabel(dateLabel, textStyle: .subheadline)
        WPStyleGuide.configureLabel(spacingLabel, textStyle: .subheadline)

        featuredImageStackView.isHidden = true
        titleLabel.attributedText = NSAttributedString(string: GhostConstants.textPlaceholder)
        snippetLabel.isHidden = false
        snippetLabel.attributedText = NSAttributedString(string: GhostConstants.textPlaceholder)
        dateLabel.attributedText = NSAttributedString(string: GhostConstants.snippetPlaceholder)
        authorLabel.isHidden = true
        statusView.isHidden = true
        progressView.isHidden = true
        actionBarView.layer.opacity = GhostConstants.actionBarOpacity
        isUserInteractionEnabled = false

        topPadding.constant = Constants.margin
        contentStackView.spacing = 0
        titleAndSnippetView.spacing = Constants.contentSpacing * 2
        titleAndSnippetView.setLayoutMargin(top: 0, bottom: Constants.contentSpacing)

        actionBarView.isGhostableDisabled = true
        upperBorder.isGhostableDisabled = true
        bottomBorder.isGhostableDisabled = true
    }

    private enum GhostConstants {
        static let actionBarOpacity: Float = 0.5
        static let spacing: CGFloat = 0
        static let textPlaceholder = " "
        static let snippetPlaceholder = "                                    "
    }
}
