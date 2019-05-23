import UIKit
import Gridicons

class PostCompactCell: UITableViewCell, ConfigurablePostView {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var timestampLabel: UILabel!
    @IBOutlet weak var badgesLabel: UILabel!
    @IBOutlet weak var menuButton: UIButton!
    @IBOutlet weak var featuredImageView: CachedAnimatedImageView!
    @IBOutlet weak var innerView: UIView!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var labelsLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var timestampTrailing: NSLayoutConstraint!
    @IBOutlet var labelsContainerTrailing: NSLayoutConstraint!
    @IBOutlet var titleAndTimestampSpacing: NSLayoutConstraint!
    @IBOutlet var labelsCenter: NSLayoutConstraint!

    static let height: CGFloat = 60

    private weak var actionSheetDelegate: PostActionSheetDelegate?

    lazy var imageLoader: ImageLoader = {
        return ImageLoader(imageView: featuredImageView, gifStrategy: .mediumGIFs)
    }()

    private var post: Post! {
        didSet {
            if post != oldValue {
                viewModel = PostCardStatusViewModel(post: post)
            }
        }
    }
    private var viewModel: PostCardStatusViewModel!

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
        guard let button = sender as? UIButton else { return }
        actionSheetDelegate?.showActionSheet(post, from: button)
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        applyStyles()
        setupReadableGuideForiPad()
    }

    private func resetGhostStyles() {
        isUserInteractionEnabled = true
        labelsCenter.constant = Constants.labelsVerticalAlignment
        badgesLabel.isHidden = false
        titleAndTimestampSpacing.constant = Constants.titleAndTimestampSpacing
        menuButton.layer.opacity = Constants.opacity
        configureLabels()
    }

    private func applyStyles() {
        WPStyleGuide.configureTableViewCell(self)
        WPStyleGuide.applyPostProgressViewStyle(progressView)

        configureLabels()

        titleLabel.textColor = WPStyleGuide.darkGrey()
        timestampLabel.textColor = WPStyleGuide.grey()
        menuButton.tintColor = WPStyleGuide.greyLighten10()

        menuButton.setImage(Gridicon.iconOfType(.ellipsis), for: .normal)

        backgroundColor = WPStyleGuide.greyLighten30()

        featuredImageView.layer.cornerRadius = Constants.imageRadius
    }

    private func configureLabels() {
        WPStyleGuide.configureLabel(timestampLabel, textStyle: .subheadline)
        WPStyleGuide.configureLabel(badgesLabel, textStyle: .subheadline)

        titleLabel.font = WPStyleGuide.notoBoldFontForTextStyle(.headline)
        titleLabel.adjustsFontForContentSizeCategory = true
    }

    private func setupReadableGuideForiPad() {
        guard WPDeviceIdentification.isiPad() else { return }

        innerView.leadingAnchor.constraint(equalTo: readableContentGuide.leadingAnchor).isActive = true
        innerView.trailingAnchor.constraint(equalTo: readableContentGuide.trailingAnchor).isActive = true

        labelsLeadingConstraint.constant = -Constants.contentSpacing
    }

    private func configureFeaturedImage() {
        if let url = post.featuredImageURLForDisplay(),
            let desiredWidth = UIApplication.shared.keyWindow?.frame.size.width {
            featuredImageView.isHidden = false
            labelsContainerTrailing.isActive = true
            imageLoader.loadImage(with: url, from: post, preferredSize: CGSize(width: desiredWidth, height: featuredImageView.frame.height))
        } else {
            featuredImageView.isHidden = true
            labelsContainerTrailing.isActive = false
        }
    }

    private func configureTitle() {
        titleLabel.text = post.titleForDisplay()
    }

    private func configureDate() {
        let isUploadingOrFailed = viewModel.isUploadingOrFailed
        timestampLabel.text = isUploadingOrFailed ? "" : post.latest().dateStringForDisplay()
        timestampTrailing.constant = isUploadingOrFailed ? 0 : Constants.contentSpacing
        timestampLabel.isHidden = isUploadingOrFailed
    }

    private func configureStatus() {
        badgesLabel.textColor = viewModel.statusColor
        badgesLabel.text = viewModel.statusAndBadges
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

    private enum Constants {
        static let contentSpacing: CGFloat = 8
        static let imageRadius: CGFloat = 2
        static let labelsVerticalAlignment: CGFloat = -1
        static let titleAndTimestampSpacing: CGFloat = 2
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
        isUserInteractionEnabled = false
        featuredImageView.isHidden = true
        labelsContainerTrailing.isActive = false
        timestampLabel.text = GhostConstants.timestampPlaceholder
        menuButton.isGhostableDisabled = true
        menuButton.layer.opacity = GhostConstants.opacity
        titleAndTimestampSpacing.constant = GhostConstants.titleAndTimestampSpacing
        labelsCenter.constant = GhostConstants.labelsVerticalAlignment
        badgesLabel.isHidden = true

        titleLabel.font = WPStyleGuide.notoBoldFontForTextStyle(.caption1)
        WPStyleGuide.configureLabel(timestampLabel, textStyle: .caption2)
    }

    private enum GhostConstants {
        static let labelsVerticalAlignment: CGFloat = 0
        static let titleAndTimestampSpacing: CGFloat = 8
        static let opacity: Float = 0.5
        static let timestampPlaceholder = "                                    "
    }
}
