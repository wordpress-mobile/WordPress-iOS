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
    @IBOutlet var labelsContainerTrailing: NSLayoutConstraint!
    @IBOutlet var timestampTrailing: NSLayoutConstraint!

    static var height: CGFloat = 60

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

    private func applyStyles() {
        WPStyleGuide.configureTableViewCell(self)
        WPStyleGuide.configureLabel(timestampLabel, textStyle: UIFont.TextStyle.subheadline)
        WPStyleGuide.configureLabel(badgesLabel, textStyle: UIFont.TextStyle.subheadline)
        WPStyleGuide.applyPostProgressViewStyle(progressView)

        titleLabel.font = WPStyleGuide.notoBoldFontForTextStyle(UIFont.TextStyle.headline)
        titleLabel.adjustsFontForContentSizeCategory = true

        titleLabel.textColor = WPStyleGuide.darkGrey()
        timestampLabel.textColor = WPStyleGuide.grey()
        menuButton.tintColor = WPStyleGuide.greyLighten10()

        menuButton.setImage(Gridicon.iconOfType(.ellipsis), for: .normal)

        backgroundColor = WPStyleGuide.greyLighten30()

        featuredImageView.layer.cornerRadius = 2
    }

    private func setupReadableGuideForiPad() {
        guard WPDeviceIdentification.isiPad() else { return }

        innerView.leadingAnchor.constraint(equalTo: readableContentGuide.leadingAnchor).isActive = true
        innerView.trailingAnchor.constraint(equalTo: readableContentGuide.trailingAnchor).isActive = true

        labelsLeadingConstraint.constant = -8
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
        timestampTrailing.constant = isUploadingOrFailed ? 0 : 8
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
}

extension PostCompactCell: InteractivePostView {
    func setInteractionDelegate(_ delegate: InteractivePostViewDelegate) {
        
    }

    func setActionSheetDelegate(_ delegate: PostActionSheetDelegate) {
        actionSheetDelegate = delegate
    }
}
