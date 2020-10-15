import UIKit

class ReaderRecommendedSiteCardCell: UITableViewCell {
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var blogNameLabel: UILabel!
    @IBOutlet weak var hostNameLabel: UILabel!
    @IBOutlet weak var followButton: UIButton!
    @IBOutlet weak var descriptionLabel: UILabel!

    var delegate: ReaderRecommendedSitesCardCellDelegate?

    override func awakeFromNib() {
        super.awakeFromNib()

        applyStyles()
    }

    func configure(_ topic: ReaderSiteTopic) {
        followButton.isSelected = topic.following
        followButton.isHidden = !ReaderHelpers.isLoggedIn()

        blogNameLabel.text = topic.title
        hostNameLabel.text = URL(string: topic.siteURL)?.host
        descriptionLabel.text = topic.siteDescription
        descriptionLabel.isHidden = topic.siteDescription.isEmpty

        configureSiteIcon(topic)
    }

    @IBAction func didTapFollowButton(_ sender: Any) {
        // Optimistically change the value
        followButton.isSelected = !followButton.isSelected

        delegate?.handleFollowActionForCell(self)
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

    private func applyStyles() {
        backgroundColor = .listForeground

        // Blog Name
        blogNameLabel.font = WPStyleGuide.fontForTextStyle(.subheadline, fontWeight: .semibold)
        blogNameLabel.textColor = .text

        // Host Label
        hostNameLabel.font = WPStyleGuide.fontForTextStyle(.footnote)
        hostNameLabel.textColor = .textSubtle

        // Host Label
        descriptionLabel.font = WPStyleGuide.fontForTextStyle(.subheadline)
        descriptionLabel.textColor = .text

        WPStyleGuide.applyReaderIconFollowButtonStyle(followButton)
    }
}

protocol ReaderRecommendedSitesCardCellDelegate {
    func handleFollowActionForCell(_ cell: ReaderRecommendedSiteCardCell)
}
