import UIKit

class ReaderRecommendedSiteCardCell: UITableViewCell {
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var blogNameLabel: UILabel!
    @IBOutlet weak var hostNameLabel: UILabel!
    @IBOutlet weak var followButton: UIButton!
    @IBOutlet weak var descriptionLabel: UILabel?
    @IBOutlet weak var headerStackView: UIStackView!

    weak var delegate: ReaderRecommendedSitesCardCellDelegate?

    private var readerImprovements: Bool {
        RemoteFeatureFlag.readerImprovements.enabled()
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        applyStyles()
    }

    func configure(_ topic: ReaderSiteTopic) {
        separatorInset = UIEdgeInsets.zero

        followButton.isSelected = topic.following
        blogNameLabel.text = topic.title
        hostNameLabel.text = URL(string: topic.siteURL)?.host
        descriptionLabel?.text = topic.siteDescription
        descriptionLabel?.isHidden = topic.siteDescription.isEmpty

        configureSiteIcon(topic)
        configureFollowButtonVisibility()

        applyStyles()
    }

    @IBAction func didTapFollowButton(_ sender: Any) {
        // Optimistically change the value
        followButton.isSelected = !followButton.isSelected

        applyFollowButtonStyles()
        configureFollowButtonVisibility()

        delegate?.handleFollowActionForCell(self)
    }

    private func configureFollowButtonVisibility() {
        let isLoggedIn = ReaderHelpers.isLoggedIn()
        followButton.isHidden = !isLoggedIn
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
            applyFollowButtonStyles()
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

        if readerImprovements {
            descriptionLabel?.removeFromSuperview()
        } else {
            // Description Label
            descriptionLabel?.font = WPStyleGuide.fontForTextStyle(.subheadline)
            descriptionLabel?.textColor = .text
        }

        applyFollowButtonStyles()
        headerStackView.spacing = readerImprovements ? 12.0 : 8.0
    }

    private func applyFollowButtonStyles() {
        if UIDevice.current.userInterfaceIdiom == .pad {
            WPStyleGuide.applyReaderFollowButtonStyle(followButton)
        } else {
            WPStyleGuide.applyReaderIconFollowButtonStyle(followButton)
        }
    }

}

protocol ReaderRecommendedSitesCardCellDelegate: AnyObject {
    func handleFollowActionForCell(_ cell: ReaderRecommendedSiteCardCell)
}
