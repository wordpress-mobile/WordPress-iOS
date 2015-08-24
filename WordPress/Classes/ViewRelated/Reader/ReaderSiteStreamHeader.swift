import Foundation

@objc public class ReaderSiteStreamHeader: UIView, ReaderStreamHeader
{
    @IBOutlet private weak var avatarImageView: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var detailLabel: UILabel!
    @IBOutlet private weak var followButton: UIButton!
    @IBOutlet private weak var followCountLabel: UILabel!
    @IBOutlet private weak var descriptionLabel: UILabel!
    @IBOutlet private weak var descriptionBottomConstraint: NSLayoutConstraint!
    @IBOutlet private weak var followCountBottomConstraint: NSLayoutConstraint!
    public var delegate: ReaderStreamHeaderDelegate?


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
        titleLabel.text = topic.title
// TODO: Wire up when supported by the topic
//        detailLabel.text = "sites . followers"
//        followCountLabel.text = "100 sites"
//        var attributes = WPStyleGuide.readerStreamHeaderDescriptionAttributes()
//        var attributedText = NSAttributedString(string: topic.description, attributes: attributes)
//        descriptionLabel.attributedText = attributedText
//
//        if topic.isSubscribed {
//            WPStyleGuide.applyReaderStreamHeaderFollowingStyle(followButton)
//        } else {
//            WPStyleGuide.applyReaderStreamHeaderNotFollowingStyle(followButton)
//        }
    }


    // MARK: - Actions

    @IBAction func didTapFollowButton(sender: UIButton) {
        if delegate == nil {
            return
        }
        if delegate!.respondsToSelector(Selector("handleFollowActionForHeader")) {
            delegate!.handleFollowActionForHeader!(self)
        }
    }
}
