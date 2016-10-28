import Foundation
import WordPressShared

@objc public class ReaderSiteStreamHeader: UIView, ReaderStreamHeader
{
    @IBOutlet private weak var borderedView: UIView!
    @IBOutlet private weak var avatarImageView: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var detailLabel: UILabel!
    @IBOutlet private weak var followButton: PostMetaButton!
    @IBOutlet private weak var followCountLabel: UILabel!
    @IBOutlet private weak var descriptionLabel: UILabel!

    public var delegate: ReaderStreamHeaderDelegate?
    private var defaultBlavatar = "blavatar-default"

    // MARK: - Lifecycle Methods

    public override func awakeFromNib() {
        super.awakeFromNib()

        applyStyles()
    }

    func applyStyles() {
        backgroundColor = WPStyleGuide.greyLighten30()
        borderedView.layer.borderColor = WPStyleGuide.readerCardCellBorderColor().CGColor
        borderedView.layer.borderWidth = 1.0
        WPStyleGuide.applyReaderStreamHeaderTitleStyle(titleLabel)
        WPStyleGuide.applyReaderStreamHeaderDetailStyle(detailLabel)
        WPStyleGuide.applyReaderSiteStreamDescriptionStyle(descriptionLabel)
        WPStyleGuide.applyReaderSiteStreamCountStyle(followCountLabel)
    }


    // MARK: - Configuration

    public func configureHeader(topic: ReaderAbstractTopic) {
        assert(topic.isKindOfClass(ReaderSiteTopic), "Topic must be a site topic")

        let siteTopic = topic as! ReaderSiteTopic

        configureHeaderImage(siteTopic.siteBlavatar)

        titleLabel.text = siteTopic.title
        detailLabel.text = NSURL(string: siteTopic.siteURL)?.host
        if siteTopic.following {
            WPStyleGuide.applyReaderStreamHeaderFollowingStyle(followButton)
        } else {
            WPStyleGuide.applyReaderStreamHeaderNotFollowingStyle(followButton)
        }

        descriptionLabel.attributedText = attributedSiteDescriptionForTopic(siteTopic)
        followCountLabel.text = formattedFollowerCountForTopic(siteTopic)

        if descriptionLabel.attributedText?.length > 0 {
            descriptionLabel.hidden = false
        } else {
            descriptionLabel.hidden = true
        }
    }

    func configureHeaderImage(siteBlavatar: String?) {
        let placeholder = UIImage(named: defaultBlavatar)

        var path = ""
        if siteBlavatar != nil {
            path = siteBlavatar!
        }

        let url = NSURL(string: path)
        if url != nil {
            avatarImageView.setImageWithURL(url!, placeholderImage: placeholder)
        } else {
            avatarImageView.image = placeholder
        }
    }

    func formattedFollowerCountForTopic(topic:ReaderSiteTopic) -> String {
        let numberFormatter = NSNumberFormatter()
        numberFormatter.numberStyle = .DecimalStyle
        let count = numberFormatter.stringFromNumber(topic.subscriberCount)
        let pattern = NSLocalizedString("%@ followers", comment: "The number of followers of a site. The '%@' is a placeholder for the numeric value. Example: `1000 followers`")
        let str = String(format: pattern, count!)
        return str
    }

    func attributedSiteDescriptionForTopic(topic:ReaderSiteTopic) -> NSAttributedString {
        return NSAttributedString(string: topic.siteDescription, attributes: WPStyleGuide.readerStreamHeaderDescriptionAttributes())
    }

    public func enableLoggedInFeatures(enable: Bool) {
        followButton.hidden = !enable
    }


    // MARK: - Actions

    @IBAction func didTapFollowButton(sender: UIButton) {
        delegate?.handleFollowActionForHeader(self)
    }
}
