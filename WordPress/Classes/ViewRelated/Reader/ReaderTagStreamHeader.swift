import Foundation
import WordPressShared

@objc open class ReaderTagStreamHeader: UIView, ReaderStreamHeader {
    @IBOutlet fileprivate weak var titleLabel: UILabel!
    @IBOutlet fileprivate weak var followButton: UIButton!

    open var delegate: ReaderStreamHeaderDelegate?

    // MARK: - Lifecycle Methods
    open override func awakeFromNib() {
        super.awakeFromNib()

        applyStyles()
        adjustInsetsForTextDirection()
    }

    @objc func applyStyles() {
        WPStyleGuide.applyReaderStreamHeaderTitleStyle(titleLabel)
    }

    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            WPStyleGuide.applyReaderFollowButtonStyle(followButton)
        }
    }


    // MARK: - Configuration

    @objc open func configureHeader(_ topic: ReaderAbstractTopic) {
        titleLabel.text = topic.title
        followButton.isSelected = topic.following
        WPStyleGuide.applyReaderFollowButtonStyle(followButton)
    }

    @objc open func enableLoggedInFeatures(_ enable: Bool) {

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
        followButton.isUserInteractionEnabled = false

        delegate?.handleFollowActionForHeader(self, completion: { [weak self] in
            self?.followButton.isUserInteractionEnabled = true
        })
    }
}
