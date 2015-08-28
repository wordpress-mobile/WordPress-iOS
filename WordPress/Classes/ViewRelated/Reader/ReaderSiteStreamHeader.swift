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
        WPStyleGuide.applyReaderStreamHeaderTitleStyle(titleLabel)
        WPStyleGuide.applyReaderStreamHeaderDetailStyle(detailLabel)
        WPStyleGuide.applyReaderSiteStreamDescriptionStyle(descriptionLabel)
        WPStyleGuide.applyReaderSiteStreamCountStyle(followCountLabel)
    }


   // MARK: - Configuration

    public func configureHeader(topic: ReaderTopic) {
        // TODO: Wire up actual display when supported in core data        
        avatarImageView.setImageWithURL(nil, placeholderImage: UIImage(named: defaultBlavatar))
        titleLabel.text = topic.title
        detailLabel.text = "site.com"
        if topic.isSubscribed {
            WPStyleGuide.applyReaderStreamHeaderFollowingStyle(followButton)
        } else {
            WPStyleGuide.applyReaderStreamHeaderNotFollowingStyle(followButton)
        }

        followCountLabel.text = "100 followers"
        descriptionLabel.text = "Just another WordPress site"
//        var attributes = WPStyleGuide.readerStreamHeaderDescriptionAttributes()
//        var attributedText = NSAttributedString(string: topic.description, attributes: attributes)
//        descriptionLabel.attributedText = attributedText
    }


    // MARK: - Actions

    @IBAction func didTapFollowButton(sender: UIButton) {
        if delegate == nil {
            return
        }
        if delegate!.respondsToSelector(Selector("handleFollowActionForHeader")) {
            delegate!.handleFollowActionForHeader(self)
        }
    }
}
