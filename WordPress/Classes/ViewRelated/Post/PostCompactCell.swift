import UIKit
import Gridicons

class PostCompactCell: UITableViewCell, ConfigurablePostView {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var timestampLabel: UILabel!
    @IBOutlet weak var badgesLabel: UILabel!
    @IBOutlet weak var menuButton: UIButton!
    @IBOutlet weak var featuredImageView: CachedAnimatedImageView!
    @IBOutlet weak var headerStackView: UIStackView!
    @IBOutlet weak var innerView: UIView!
    @IBOutlet weak var contentStackView: UIStackView!
    @IBOutlet weak var ghostView: UIView!
    @IBOutlet weak var progressView: UIProgressView!
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
    private var progressViewController: PostUploadProgressViewController? = nil

    func configure(with post: Post) {
        self.post = post

        progressViewController = PostUploadProgressViewController(with: post, onUploadComplete: { [weak self] in
            self?.configure()
        })

        configure()
    }

    private func configure() {
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
        setupAccessibility()
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
    }

    private func configureFeaturedImage() {
        if let post = post, let url = post.featuredImageURL {
            featuredImageView.isHidden = false
            imageLoader.loadImage(with: url, from: post, preferredSize: CGSize(width: featuredImageView.frame.width, height: featuredImageView.frame.height))
        } else {
            featuredImageView.isHidden = true
        }
    }

    private func configureTitle() {
        titleLabel.text = post?.titleForDisplay()
    }

    private func configureDate() {
        guard let post = post else {
            return
        }

        timestampLabel.text = post.latest().dateStringForDisplay()
        timestampLabel.isHidden = false
    }

    private func configureStatus() {
        guard let viewModel = viewModel else {
            return
        }

        badgesLabel.textColor = viewModel.statusColor
        badgesLabel.text = viewModel.statusAndBadges(separatedBy: Constants.separator)
        if badgesLabel.text?.isEmpty ?? true {
            badgesLabel.isHidden = true
        } else {
            badgesLabel.isHidden = false
        }
    }

    private func configureProgressView() {
        guard let progressViewController = progressViewController else {
            return
        }

        progressViewController.configure(progressView)
    }

    private func setupAccessibility() {
        menuButton.accessibilityLabel =
            NSLocalizedString("More", comment: "Accessibility label for the More button in Post List (compact view).")
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
        contentStackView.isHidden = visible
    }

    private enum GhostConstants {
        static let opacity: Float = 0.5
    }
}
