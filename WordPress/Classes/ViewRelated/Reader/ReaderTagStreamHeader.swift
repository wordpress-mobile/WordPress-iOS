import Foundation
import WordPressShared

@objc open class ReaderTagStreamHeader: UIView, ReaderStreamHeader {
    @IBOutlet fileprivate weak var borderedView: UIView!
    @IBOutlet fileprivate weak var titleLabel: UILabel!
    @IBOutlet fileprivate weak var followButton: PostMetaButton!

    open var delegate: ReaderStreamHeaderDelegate?


    // MARK: - Lifecycle Methods

    open override func awakeFromNib() {
        super.awakeFromNib()

        applyStyles()
        adjustInsetsForTextDirection()
    }

    @objc func applyStyles() {
        backgroundColor = .listBackground
        borderedView.backgroundColor = .listForeground
        borderedView.layer.borderColor = WPStyleGuide.readerCardCellBorderColor().cgColor
        borderedView.layer.borderWidth = .hairlineBorderWidth
        WPStyleGuide.applyReaderStreamHeaderTitleStyle(titleLabel)
    }


    // MARK: - Configuration

    @objc open func configureHeader(_ topic: ReaderAbstractTopic) {
        titleLabel.text = topic.title
        WPStyleGuide.applyReaderFollowButtonStyle(followButton)
        followButton.isSelected = topic.following
    }

    @objc open func enableLoggedInFeatures(_ enable: Bool) {
        followButton.isHidden = !enable
    }

    fileprivate func adjustInsetsForTextDirection() {
        guard userInterfaceLayoutDirection() == .rightToLeft else {
            return
        }

        followButton.contentEdgeInsets = followButton.contentEdgeInsets.flippedForRightToLeftLayoutDirection()
        followButton.imageEdgeInsets = followButton.imageEdgeInsets.flippedForRightToLeftLayoutDirection()
        followButton.titleEdgeInsets = followButton.titleEdgeInsets.flippedForRightToLeftLayoutDirection()
    }

    // MARK: - Actions

    @IBAction func didTapFollowButton(_ sender: UIButton) {
        delegate?.handleFollowActionForHeader(self)
    }
}
