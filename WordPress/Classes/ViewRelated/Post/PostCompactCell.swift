import AutomatticTracks
import UIKit
import Gridicons
import WordPressShared
import WordPressUI

class PostCompactCell: UITableViewCell {
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

    @IBOutlet weak var trailingContentConstraint: NSLayoutConstraint!

    private var iPadReadableLeadingAnchor: NSLayoutConstraint?
    private var iPadReadableTrailingAnchor: NSLayoutConstraint?

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
        configureMenuInteraction()
    }

    @IBAction func more(_ sender: Any) {
        // Do nothing. The compact cell is only shown in the dashboard, where the more button is hidden.
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

        titleLabel.font = AppStyleGuide.prominentFont(textStyle: .headline, weight: .bold)
        titleLabel.adjustsFontForContentSizeCategory = true

        titleLabel.textColor = .text
        timestampLabel.textColor = .textSubtle
        menuButton.tintColor = .textSubtle

        menuButton.setImage(.gridicon(.ellipsis), for: .normal)

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

        iPadReadableLeadingAnchor = innerView.leadingAnchor.constraint(equalTo: readableContentGuide.leadingAnchor)
        iPadReadableTrailingAnchor = innerView.trailingAnchor.constraint(equalTo: readableContentGuide.trailingAnchor)

        iPadReadableLeadingAnchor?.isActive = true
        iPadReadableTrailingAnchor?.isActive = true
    }

    private func configureFeaturedImage() {
        if let post = post, let url = post.featuredImageURL {
            featuredImageView.isHidden = false

            let host = MediaHost(with: post, failure: { error in
                // We'll log the error, so we know it's there, but we won't halt execution.
                WordPressAppDelegate.crashLogging?.logError(error)
            })

            imageLoader.loadImage(with: url, from: host, preferredSize: CGSize(width: featuredImageView.frame.width, height: featuredImageView.frame.height))
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

    private func configureExcerpt() {
        guard let post = post else {
            return
        }

        timestampLabel.text = post.contentPreviewForDisplay()
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

    private func configureMenuInteraction() {
        guard let viewModel = viewModel else {
            return
        }

        let isProgressBarVisible = !viewModel.shouldHideProgressView

        if isProgressBarVisible {
            menuButton.isEnabled = false
            menuButton.alpha = 0.3
        } else {
            menuButton.isEnabled = true
            menuButton.alpha = 1.0
        }
    }

    private func setupAccessibility() {
        menuButton.accessibilityLabel =
            NSLocalizedString("More", comment: "Accessibility label for the More button in Post List (compact view).")
    }

    private enum Constants {
        static let separator = " · "
        static let imageRadius: CGFloat = 2
        static let opacity: Float = 1
        static let margin: CGFloat = 16
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

extension PostCompactCell: NibReusable { }

// MARK: - For display on the Posts Card (Dashboard)

extension PostCompactCell {
    /// Configure the cell to be displayed in the Posts Card
    /// No "more" button and show a description, instead of a date
    func configureForDashboard(with post: Post) {
        configure(with: post)
        separator.isHidden = true
        menuButton.isHidden = true
        trailingContentConstraint.constant = Constants.margin
        headerStackView.spacing = Constants.margin

        disableiPadReadableMargin()

        if !post.isScheduled() {
            configureExcerpt()
        }
    }

    func disableiPadReadableMargin() {
        iPadReadableLeadingAnchor?.isActive = false
        iPadReadableTrailingAnchor?.isActive = false
    }
}
