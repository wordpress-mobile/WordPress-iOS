import Foundation
import WordPressShared

@objc public class ReaderTagStreamHeader: UIView, ReaderStreamHeader
{
    @IBOutlet private weak var innerContentView: UIView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var followButton: PostMetaButton!
    @IBOutlet private weak var contentIPadTopConstraint: NSLayoutConstraint?
    @IBOutlet private weak var contentBottomConstraint: NSLayoutConstraint!

    public var delegate: ReaderStreamHeaderDelegate?


    // MARK: - Lifecycle Methods

    public override func awakeFromNib() {
        super.awakeFromNib()

        applyStyles()
    }

    func applyStyles() {
        backgroundColor = WPStyleGuide.greyLighten30()
        WPStyleGuide.applyReaderStreamHeaderTitleStyle(titleLabel)
    }

    public override func sizeThatFits(size: CGSize) -> CGSize {
        var height = innerContentView.frame.size.height
        if UIDevice.isPad() && contentIPadTopConstraint != nil {
            height += contentIPadTopConstraint!.constant
        }
        height += contentBottomConstraint.constant
        return CGSize(width: size.width, height: height)
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
