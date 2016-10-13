import Foundation
import WordPressShared

@objc public class ReaderTagStreamHeader: UIView, ReaderStreamHeader
{
    @IBOutlet private weak var borderedView: UIView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var followButton: PostMetaButton!

    public var delegate: ReaderStreamHeaderDelegate?


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
    }


    // MARK: - Configuration

    public func configureHeader(topic: ReaderAbstractTopic) {
        titleLabel.text = topic.title
        if topic.following {
            WPStyleGuide.applyReaderStreamHeaderFollowingStyle(followButton)
        } else {
            WPStyleGuide.applyReaderStreamHeaderNotFollowingStyle(followButton)
        }
    }

    public func enableLoggedInFeatures(enable: Bool) {
        followButton.hidden = !enable
    }


    // MARK: - Actions

    @IBAction func didTapFollowButton(sender: UIButton) {
        delegate?.handleFollowActionForHeader(self)
    }
}
