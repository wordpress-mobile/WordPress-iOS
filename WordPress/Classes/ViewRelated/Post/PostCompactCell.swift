import UIKit
import Gridicons

class PostCompactCell: UITableViewCell, ConfigurablePostView {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var timestampLabel: UILabel!
    @IBOutlet weak var badgesLabel: UILabel!
    @IBOutlet weak var menuButton: UIButton!
    @IBOutlet weak var featuredImageView: CachedAnimatedImageView!
    @IBOutlet weak var innerView: UIView!
    @IBOutlet weak var ghostView: UIView!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var labelsLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var timestampTrailing: NSLayoutConstraint!
    @IBOutlet var labelsContainerTrailing: NSLayoutConstraint!
    @IBOutlet weak var separator: UIView!

    private weak var actionSheetDelegate: PostActionSheetDelegate?

    lazy var imageLoader: ImageLoader = {
        return ImageLoader(imageView: featuredImageView, gifStrategy: .mediumGIFs)
    }()

    private var post: Post? {
        didSet {
            guard let post = post, post != oldValue else {
                return
            }

            viewModel = PostCardStatusViewModel(post: post)
        }
    }
    private var viewModel: PostCardStatusViewModel?

    func configure(with post: Post) {
        self.post = post

        resetGhostStyles()
        configureTitle()
        configureDate()
        configureStatus()
        configureFeaturedImage()
        configureProgressView()
    }

    @IBAction func more(_ sender: Any) {
        guard let viewModel = viewModel, let button = sender as? UIButton else {
            return
        }

        actionSheetDelegate?.showActionSheet(viewModel, from: button)
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        applyStyles()
        setupReadableGuideForiPad()
        setupSeparator()
    }

    private func resetGhostStyles() {
        toggleGhost(visible: false)
        menuButton.layer.opacity = Constants.opacity
    }

    private func applyStyles() {
        WPStyleGuide.configureTableViewCell(self)
        WPStyleGuide.applyPostCardStyle(self)
        WPStyleGuide.applyPostProgressViewStyle(progressView)
        WPStyleGuide.configureLabel(timestampLabel, textStyle: .subheadline)
        WPStyleGuide.configureLabel(badgesLabel, textStyle: .subheadline)

        titleLabel.font = WPStyleGuide.notoBoldFontForTextStyle(.headline)
        titleLabel.adjustsFontForContentSizeCategory = true

        titleLabel.textColor = .text
        timestampLabel.textColor = .textSubtle
        menuButton.tintColor = .textSubtle

        menuButton.setImage(Gridicon.iconOfType(.ellipsis), for: .normal)

        featuredImageView.layer.cornerRadius = Constants.imageRadius

        innerView.backgroundColor = .listForeground
        backgroundColor = .listForeground
        contentView.backgroundColor = .listForeground
    }

    private func setupSeparator() {
        WPStyleGuide.applyBorderStyle(separator)
    }

    private func setupReadableGuideForiPad() {
        guard WPDeviceIdentification.isiPad() else { return }

        innerView.leadingAnchor.constraint(equalTo: readableContentGuide.leadingAnchor).isActive = true
        innerView.trailingAnchor.constraint(equalTo: readableContentGuide.trailingAnchor).isActive = true

        labelsLeadingConstraint.constant = -Constants.contentSpacing
    }

    private func configureFeaturedImage() {
        if let post = post, let url = post.featuredImageURL {
            featuredImageView.isHidden = false
            labelsContainerTrailing.isActive = true
            imageLoader.loadImage(with: url, from: post, preferredSize: CGSize(width: featuredImageView.frame.width, height: featuredImageView.frame.height))
        } else {
            featuredImageView.isHidden = true
            labelsContainerTrailing.isActive = false
        }
    }

    private func configureTitle() {
        titleLabel.text = post?.titleForDisplay()
    }

    private func configureDate() {
        guard let post = post, let viewModel = viewModel else {
            return
        }

        let isUploadingOrFailed = viewModel.isUploadingOrFailed
        timestampLabel.text = isUploadingOrFailed ? "" : post.latest().dateStringForDisplay()
        timestampTrailing.constant = isUploadingOrFailed ? 0 : Constants.contentSpacing
        timestampLabel.isHidden = isUploadingOrFailed
    }

    private func configureStatus() {
        guard let viewModel = viewModel else {
            return
        }

        badgesLabel.textColor = viewModel.statusColor
        badgesLabel.text = viewModel.statusAndBadges(separatedBy: Constants.separator)
        badgesLabel.numberOfLines = viewModel.isUploadingOrFailed ? 0 : 1
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

    private enum Constants {
        static let separator = " · "
        static let contentSpacing: CGFloat = 8
        static let imageRadius: CGFloat = 2
        static let labelsVerticalAlignment: CGFloat = -1
        static let opacity: Float = 1
    }
}

extension PostCompactCell: InteractivePostView {
    func setInteractionDelegate(_ delegate: InteractivePostViewDelegate) {

    }

    func setActionSheetDelegate(_ delegate: PostActionSheetDelegate) {
        actionSheetDelegate = delegate
    }
}

extension PostCompactCell: GhostableView {
    func ghostAnimationWillStart() {
        toggleGhost(visible: true)
        menuButton.layer.opacity = GhostConstants.opacity
    }

    private func toggleGhost(visible: Bool) {
        isUserInteractionEnabled = !visible
        menuButton.isGhostableDisabled = true
        separator.isGhostableDisabled = true
        ghostView.isHidden = !visible
        ghostView.backgroundColor = .listForeground
        featuredImageView.isHidden = true
    }

    private enum GhostConstants {
        static let opacity: Float = 0.5
    }
}
