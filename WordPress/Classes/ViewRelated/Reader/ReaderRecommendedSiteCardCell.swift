import UIKit

class ReaderRecommendedSiteCardCell: UITableViewCell {
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var blogNameLabel: UILabel!
    @IBOutlet weak var hostNameLabel: UILabel!
    @IBOutlet weak var followButton: UIButton!
    @IBOutlet weak var iPadFollowButton: UIButton!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var infoTrailingConstraint: NSLayoutConstraint!

    var delegate: ReaderRecommendedSitesCardCellDelegate?

    override func awakeFromNib() {
        super.awakeFromNib()

        applyStyles()
    }

    func configure(_ topic: ReaderSiteTopic) {
        separatorInset = UIEdgeInsets.zero

        followButton.isSelected = topic.following
        iPadFollowButton.isSelected = topic.following

        blogNameLabel.text = topic.title
        hostNameLabel.text = URL(string: topic.siteURL)?.host
        descriptionLabel.text = topic.siteDescription
        descriptionLabel.isHidden = topic.siteDescription.isEmpty

        configureSiteIcon(topic)
        configureFollowButtonVisibility()
    }

    @IBAction func didTapFollowButton(_ sender: Any) {
        // Optimistically change the value
        followButton.isSelected = !followButton.isSelected
        iPadFollowButton.isSelected = !iPadFollowButton.isSelected

        configureFollowButtonVisibility()

        WPStyleGuide.applyReaderFollowButtonStyle(iPadFollowButton)

        delegate?.handleFollowActionForCell(self)
    }

    private func configureFollowButtonVisibility() {
        let isLoggedIn = ReaderHelpers.isLoggedIn()

        guard isLoggedIn else {
            followButton.isHidden = true
            iPadFollowButton.isHidden = true
            return
        }

        let isCompact = traitCollection.horizontalSizeClass == .compact

        followButton.isHidden = !isCompact
        iPadFollowButton.isHidden = isCompact

        // Update the info trailing constraint to prevent clipping
        let button = isCompact ? followButton : iPadFollowButton
        let width = button?.frame.size.width ?? 0
        infoTrailingConstraint.constant = width + Constants.buttonMargin
    }

    private func configureSiteIcon(_ topic: ReaderSiteTopic) {
        let placeholder = UIImage.siteIconPlaceholder

        guard
            !topic.siteBlavatar.isEmpty,
            let url = URL(string: topic.siteBlavatar)
        else {
            iconImageView.image = placeholder
            return
        }

        iconImageView.downloadImage(from: url, placeholderImage: placeholder)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        configureFollowButtonVisibility()

        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            WPStyleGuide.applyReaderFollowButtonStyle(iPadFollowButton)
        }
    }

    private func applyStyles() {
        backgroundColor = .listForeground

        // Blog Name
        blogNameLabel.font = WPStyleGuide.fontForTextStyle(.subheadline, fontWeight: .semibold)
        blogNameLabel.textColor = .text

        // Host Label
        hostNameLabel.font = WPStyleGuide.fontForTextStyle(.footnote)
        hostNameLabel.textColor = .textSubtle

        // Description Label
        descriptionLabel.font = WPStyleGuide.fontForTextStyle(.subheadline)
        descriptionLabel.textColor = .text

        WPStyleGuide.applyReaderFollowButtonStyle(iPadFollowButton)
        WPStyleGuide.applyReaderIconFollowButtonStyle(followButton)
    }

    private struct Constants {
        static let buttonMargin: CGFloat = 8
    }
}

protocol ReaderRecommendedSitesCardCellDelegate {
    func handleFollowActionForCell(_ cell: ReaderRecommendedSiteCardCell)
}
