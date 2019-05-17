import UIKit
import Gridicons

class PostCell: UITableViewCell, ConfigurablePostView {
    @IBOutlet weak var featuredImage: CachedAnimatedImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var snippetLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet weak var stickyLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var statusAndStickySeparator: UILabel!
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
    @IBOutlet weak var topSpace: NSLayoutConstraint!

    private let topSpaceWithImage: CGFloat = 16
    private let topSpaceWithoutImage: CGFloat = 0
    private let separator = "·"

    lazy var imageLoader: ImageLoader = {
        return ImageLoader(imageView: featuredImage, gifStrategy: .mediumGIFs)
    }()

    private var post: Post!
    private var viewModel: PostCardStatusViewModel!
    private weak var interactivePostViewDelegate: InteractivePostViewDelegate?
    private weak var actionSheetDelegate: PostActionSheetDelegate?
    var isAuthorHidden: Bool = false {
        didSet {
            authorLabel.isHidden = isAuthorHidden
        }
    }

    func configure(with post: Post) {
        if post != self.post {
            viewModel = PostCardStatusViewModel(post: post)
        }

        self.post = post

        configureFeaturedImage()
        configureTitle()
        configureSnippet()
        configureDate()
        configureAuthor()
        configureStatusLabel()
        configureStickyPost()
        configureStatusView()
        configureProgressView()
        configureActionBar()
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        applyStyles()
        applyBorder()
        setLabels()
        configureSelectedBackgroundView()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
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
        if !containerView.frame.contains(point) {
            return nil
        }
        return super.hitTest(point, with: event)
    }

    @IBAction func edit() {
        interactivePostViewDelegate?.edit(post)
    }

    @IBAction func view() {
        interactivePostViewDelegate?.view(post)
    }

    @IBAction func more(_ sender: Any) {
        guard let button = sender as? UIButton else { return }
        actionSheetDelegate?.showActionSheet(post, from: button)
    }

    @IBAction func retry() {
        interactivePostViewDelegate?.retry(post)
    }

    private func applyStyles() {
        WPStyleGuide.applyPostCardStyle(self)
        WPStyleGuide.applyPostTitleStyle(titleLabel)
        WPStyleGuide.applyPostSnippetStyle(snippetLabel)
        WPStyleGuide.applyPostDateStyle(dateLabel)
        WPStyleGuide.applyPostDateStyle(authorLabel)
        WPStyleGuide.applyPostDateStyle(statusLabel)
        WPStyleGuide.applyPostDateStyle(statusAndStickySeparator)
        WPStyleGuide.applyPostDateStyle(stickyLabel)
        WPStyleGuide.applyPostProgressViewStyle(progressView)
        WPStyleGuide.applyPostButtonStyle(editButton)
        WPStyleGuide.applyPostButtonStyle(retryButton)
        WPStyleGuide.applyPostButtonStyle(viewButton)
        WPStyleGuide.applyPostButtonStyle(moreButton)
        applyActionBarStyle()
    }

    private func configureFeaturedImage() {
        let post = self.post.latest()

        if let url = post.featuredImageURLForDisplay(),
            let desiredWidth = UIApplication.shared.keyWindow?.frame.size.width {
            featuredImage.isHidden = false
            topSpace.constant = topSpaceWithImage
            imageLoader.loadImage(with: url, from: post, preferredSize: CGSize(width: desiredWidth, height: featuredImage.frame.height))
        } else {
            featuredImage.isHidden = true
            topSpace.constant = topSpaceWithoutImage
        }
    }

    private func configureTitle() {
        let post = self.post.latest()
        if let titleForDisplay = post.titleForDisplay() {
            titleLabel.attributedText = NSAttributedString(string: titleForDisplay, attributes: WPStyleGuide.postCardTitleAttributes() as? [NSAttributedString.Key: Any])
            titleLabel.lineBreakMode = .byTruncatingTail
        }
    }

    private func configureSnippet() {
        let post = self.post.latest()
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
        let post = self.post.latest()
        dateLabel.text = post.dateStringForDisplay()
    }

    private func configureAuthor() {
        guard let author = post.authorForDisplay() else { return }
        authorLabel.text = " \(separator) \(author)"
    }

    private func configureStickyPost() {
        stickyLabel.isHidden = !viewModel.shouldShowStickyLabel
        statusAndStickySeparator.isHidden = stickyLabel.isHidden || (statusLabel.text?.isEmpty ?? true)

    }

    private func configureStatusLabel() {
        statusLabel.text = viewModel.status
    }

    private func configureStatusView() {
        statusView.isHidden = viewModel.shouldHideStatusView

        [statusLabel, statusAndStickySeparator, stickyLabel].forEach { label in
            label?.textColor = viewModel.statusColor
        }
    }

    private func configureProgressView() {
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
        retryButton.isHidden = !post.isFailed
        viewButton.isHidden = post.isFailed
    }

    private func applyBorder() {
        [upperBorder, bottomBorder].forEach { border in
            border?.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
            border?.backgroundColor = WPStyleGuide.postCardBorderColor()
        }
    }

    private func applyActionBarStyle() {
        actionBarView.subviews.compactMap({ $0 as? UIButton }).forEach { button in
            button.setImage(button.imageView?.image?.imageWithTintColor(WPStyleGuide.grey()), for: .normal)
            button.setTitleColor(WPStyleGuide.grey(), for: .normal)
            button.setTitleColor(WPStyleGuide.darkGrey(), for: .highlighted)
            button.setTitleColor(WPStyleGuide.darkGrey(), for: .selected)
        }
    }

    private func setLabels() {
        stickyLabel.text = NSLocalizedString("Sticky", comment: "Label text that defines a post marked as sticky")
        statusAndStickySeparator.text = " \(separator) "

        retryButton.setTitle(NSLocalizedString("Retry", comment: "Label for the retry post upload button. Tapping attempts to upload the post again."), for: .normal)
        retryButton.setImage(Gridicon.iconOfType(.refresh, withSize: CGSize(width: 18, height: 18)), for: .normal)
        retryButton.isHidden = true

        editButton.setTitle(NSLocalizedString("Edit", comment: "Label for the edit post button. Tapping displays the editor."), for: .normal)

        viewButton.setTitle(NSLocalizedString("View", comment: "Label for the view post button. Tapping displays the post as it appears on the web."), for: .normal)

        moreButton.setTitle(NSLocalizedString("More", comment: "Label for the more post button. Tapping displays an action sheet with post options."), for: .normal)
    }

    private func configureSelectedBackgroundView() {
        if let selectedBackgroundView = selectedBackgroundView {
            let marginMask = UIView()
            selectedBackgroundView.addSubview(marginMask)
            marginMask.translatesAutoresizingMaskIntoConstraints = false
            marginMask.leadingAnchor.constraint(equalTo: selectedBackgroundView.leadingAnchor).isActive = true
            marginMask.topAnchor.constraint(equalTo: selectedBackgroundView.topAnchor).isActive = true
            marginMask.trailingAnchor.constraint(equalTo: selectedBackgroundView.trailingAnchor).isActive = true
            marginMask.heightAnchor.constraint(equalToConstant: topSpaceWithImage).isActive = true
            marginMask.backgroundColor = WPStyleGuide.greyLighten30()
        }
    }

    func setActionSheetDelegate(_ delegate: PostActionSheetDelegate) {
        actionSheetDelegate = delegate
    }
}

extension PostCell: InteractivePostView {
    func setInteractionDelegate(_ delegate: InteractivePostViewDelegate) {
        interactivePostViewDelegate = delegate
    }
}
