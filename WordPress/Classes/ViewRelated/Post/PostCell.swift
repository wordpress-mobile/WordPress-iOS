import UIKit

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
    @IBOutlet weak var upperBorder: UIView!
    @IBOutlet weak var bottomBorder: UIView!
    @IBOutlet weak var topSpace: NSLayoutConstraint!

    private let topSpaceWithImage: CGFloat = 16
    private let topSpaceWithoutImage: CGFloat = 8
    private let separator = "·"

    lazy var imageLoader: ImageLoader = {
        return ImageLoader(imageView: featuredImage, gifStrategy: .mediumGIFs)
    }()

    var post: Post!
    var viewModel: PostCardStatusViewModel!

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
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        WPStyleGuide.applyPostCardStyle(self)
        WPStyleGuide.applyPostTitleStyle(titleLabel)
        WPStyleGuide.applyPostSnippetStyle(snippetLabel)
        WPStyleGuide.applyPostDateStyle(dateLabel)
        WPStyleGuide.applyPostDateStyle(authorLabel)

        [upperBorder, bottomBorder].forEach { border in
            border?.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
            border?.backgroundColor = WPStyleGuide.postCardBorderColor()
        }

        stickyLabel.text = NSLocalizedString("Sticky", comment: "Label text that defines a post marked as sticky")
        statusAndStickySeparator.text = " \(separator) "
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageLoader.prepareForReuse()
        setNeedsDisplay()
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
            titleLabel.attributedText = NSAttributedString(string: titleForDisplay, attributes: WPStyleGuide.postCardTitleAttributes() as? [NSAttributedString.Key : Any])
            titleLabel.lineBreakMode = .byTruncatingTail
        }
    }

    private func configureSnippet() {
        let post = self.post.latest()
        if let contentPreviewForDisplay = post.contentPreviewForDisplay() {
            snippetLabel.attributedText = NSAttributedString(string: contentPreviewForDisplay, attributes: WPStyleGuide.postCardSnippetAttributes() as? [NSAttributedString.Key : Any])
            snippetLabel.lineBreakMode = .byTruncatingTail
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
        stickyLabel.isHidden = !post.isStickyPost
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
}
