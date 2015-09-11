import Foundation

@objc public class ReaderSiteStreamHeader: UIView, ReaderStreamHeader
{
    @IBOutlet private weak var avatarImageView: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var detailLabel: UILabel!
    @IBOutlet private weak var followButton: PostMetaButton!
    @IBOutlet private weak var followCountLabel: UILabel!
    @IBOutlet private weak var descriptionLabel: UILabel!
    @IBOutlet private weak var descriptionBottomConstraint: NSLayoutConstraint!
    @IBOutlet private weak var followCountBottomConstraint: NSLayoutConstraint!
    public var delegate: ReaderStreamHeaderDelegate?
    private var defaultBlavatar = "blavatar-default"

    // MARK: - Lifecycle Methods

    public override func awakeFromNib() {
        super.awakeFromNib()

        applyStyles()
    }

    func applyStyles() {
        backgroundColor = WPStyleGuide.greyLighten30()
        WPStyleGuide.applyReaderStreamHeaderTitleStyle(titleLabel)
        WPStyleGuide.applyReaderStreamHeaderDetailStyle(detailLabel)
        WPStyleGuide.applyReaderSiteStreamDescriptionStyle(descriptionLabel)
        WPStyleGuide.applyReaderSiteStreamCountStyle(followCountLabel)
    }


   // MARK: - Configuration

    public func configureHeader(topic: ReaderAbstractTopic) {
        assert(topic.isKindOfClass(ReaderSiteTopic), "Topic must be a site topic")

        let siteTopic = topic as! ReaderSiteTopic

        avatarImageView.setImageWithURL(NSURL(), placeholderImage: UIImage(named: defaultBlavatar))
        titleLabel.text = siteTopic.title
        detailLabel.text = "site.com"
        if siteTopic.following {
            WPStyleGuide.applyReaderStreamHeaderFollowingStyle(followButton)
        } else {
            WPStyleGuide.applyReaderStreamHeaderNotFollowingStyle(followButton)
        }

        followCountLabel.text = "\(siteTopic.subscriberCount)"

        let attributes = WPStyleGuide.readerStreamHeaderDescriptionAttributes() as! [String: AnyObject]
        let attributedText = NSAttributedString(string: siteTopic.siteDescription, attributes: attributes)
        descriptionLabel.attributedText = attributedText
    }


    // MARK: - Actions

    @IBAction func didTapFollowButton(sender: UIButton) {
        delegate?.handleFollowActionForHeader(self)
    }
}
