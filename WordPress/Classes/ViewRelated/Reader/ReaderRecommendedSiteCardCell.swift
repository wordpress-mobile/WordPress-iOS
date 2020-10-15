import UIKit

class ReaderRecommendedSiteCardCell: UITableViewCell {
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var blogNameLabel: UILabel!
    @IBOutlet weak var hostNameLabel: UILabel!
    @IBOutlet weak var followButton: UIButton!
    @IBOutlet weak var descriptionLabel: UILabel!

    weak var topic: ReaderSiteTopic? = nil

    override func awakeFromNib() {
        super.awakeFromNib()

        applyStyles()
    }

    func configure(_ topic: ReaderSiteTopic) {
        self.topic = topic

        followButton.isSelected = topic.following
        blogNameLabel.text = topic.title
        hostNameLabel.text = URL(string: topic.siteURL)?.host
        descriptionLabel.text = topic.siteDescription
        descriptionLabel.isHidden = topic.siteDescription.isEmpty

        configureHeaderImage()
    }

    func configureHeaderImage() {
        let placeholder = UIImage.siteIconPlaceholder

        guard
            let path = topic?.siteBlavatar,
            let url = URL(string: path)
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
