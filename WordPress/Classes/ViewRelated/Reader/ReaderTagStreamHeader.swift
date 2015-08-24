import Foundation

@objc public class ReaderTagStreamHeader: UIView, ReaderStreamHeader
{
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var followButton: UIButton!
    public var delegate: ReaderStreamHeaderDelegate?


    // MARK: - Lifecycle Methods

    public override func awakeFromNib() {
        super.awakeFromNib()

        applyStyles()
    }

    func applyStyles() {
        WPStyleGuide.applyReaderStreamHeaderTitleStyle(titleLabel)
    }
    
    
    // MARK: - Configuration

    public func configureHeader(topic: ReaderTopic) {
        titleLabel.text = topic.title
        if topic.isSubscribed {
            WPStyleGuide.applyReaderStreamHeaderFollowingStyle(followButton)
        } else {
            WPStyleGuide.applyReaderStreamHeaderNotFollowingStyle(followButton)
        }
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
