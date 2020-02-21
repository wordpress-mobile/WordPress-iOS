import Foundation
import Gridicons

class PageListTableViewCell: BasePageListCell {
    private static let pageListTableViewCellTagLabelRadius = CGFloat(2)
    private static let featuredImageSize = CGFloat(120)

    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var badgesLabel: UILabel!
    @IBOutlet private var featuredImageView: CachedAnimatedImageView!
    @IBOutlet private var menuButton: UIButton!
    @IBOutlet private var labelsContainerTrailing: NSLayoutConstraint!
    @IBOutlet private var leadingContentConstraint: NSLayoutConstraint!

    private lazy var featuredImageLoader: ImageLoader = {
        return ImageLoader(imageView: self.featuredImageView, gifStrategy: .largeGIFs)
    }()

    private lazy var dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.doesRelativeDateFormatting = true
        dateFormatter.dateStyle = .none
        dateFormatter.timeStyle = .short

        return dateFormatter
    }()

    private var privateIndentationWidth: CGFloat = 0
    private var privateIndentationLevel: Int = 0

    override var indentationWidth: CGFloat {
        get {
            return privateIndentationWidth
        }

        set {
            privateIndentationWidth = newValue
            updateLeadingContentConstraint()
        }
    }

    override var indentationLevel: Int {
        get {
            return privateIndentationLevel
        }

        set {
            privateIndentationLevel = newValue
            updateLeadingContentConstraint()
        }
    }

    // MARK: - Lifecycle

    override func awakeFromNib() {
        super.awakeFromNib()

        applyStyles()
        setupAccessibility()
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        applyStyles()
        featuredImageLoader.prepareForReuse()
        setNeedsDisplay()
    }

    // MARK: - Configuration

    override func configureCell(_ post: AbstractPost) {
        super.configureCell(post)

        configureTitle()
        configureForStatus()
        configureBadges()
        configureFeaturedImage()
        accessibilityIdentifier = post.slugForDisplay()
    }

    private func applyStyles() {
        WPStyleGuide.configureTableViewCell(self)
        WPStyleGuide.configureLabel(badgesLabel, textStyle: .subheadline)

        titleLabel.font = WPStyleGuide.notoBoldFontForTextStyle(.headline)
        titleLabel.adjustsFontForContentSizeCategory = true

        titleLabel.textColor = .text
        badgesLabel.textColor = .textSubtle
        menuButton.tintColor = .textSubtle
        menuButton.setImage(Gridicon.iconOfType(.ellipsis), for: .normal)

        backgroundColor = UIColor.neutral(.shade5)
        contentView.backgroundColor = .neutral(.shade5)

        featuredImageView.layer.cornerRadius = PageListTableViewCell.pageListTableViewCellTagLabelRadius
    }

    private func configureTitle() {
        let postForTitle = self.post?.hasRevision() == true ? self.post?.revision : self.post
        titleLabel.text = postForTitle?.titleForDisplay() ?? ""
    }

    private func configureForStatus() {
        guard let post = post else {
            return
        }

        if post.isFailed && !post.hasLocalChanges() {
            titleLabel.textColor = .error
            menuButton.tintColor = .error
        }
    }

    private func updateLeadingContentConstraint() {
        leadingContentConstraint.constant = CGFloat(indentationLevel) * indentationWidth
    }

    private func configureBadges() {
        guard let page = self.post as? Page else {
            return
        }

        var badges = [String]()

        if let dateCreated = page.dateCreated {
            let timeStamp = page.isScheduled() ? dateFormatter.string(from: dateCreated) : dateCreated.mediumString()
            badges.append(timeStamp)
        }

        if page.hasPrivateState {
            badges.append(NSLocalizedString("Private", comment: "Title of the Private Badge"))
        } else if page.hasPendingReviewState {
            badges.append(NSLocalizedString("Pending review", comment: "Title of the Pending Review Badge"))
        }

        if page.hasLocalChanges() {
            badges.append(NSLocalizedString("Local changes", comment: "Title of the Local Changes Badge"))
        }

        badgesLabel.text = badges.joined(separator: " · ")
    }

    private func configureFeaturedImage() {
        guard let page = post as? Page else {
            return
        }

        let hideFeaturedImage = page.featuredImage == nil
        featuredImageView.isHidden = hideFeaturedImage
        labelsContainerTrailing.isActive = !hideFeaturedImage

        if !hideFeaturedImage,
            let media = page.featuredImage {

            featuredImageLoader.loadImage(media: media,
                                          preferredSize: CGSize(
                                            width: PageListTableViewCell.featuredImageSize,
                                            height: PageListTableViewCell.featuredImageSize),
                                          placeholder: nil,
                                          success: nil) { error in
                                            DDLogError("Failed to load the media: %@", level: .error)
            }
        }
    }

    private func setupAccessibility() {
        menuButton.accessibilityLabel = NSLocalizedString("More", comment: "Accessibility label for the More button in Page List.")
    }
}
