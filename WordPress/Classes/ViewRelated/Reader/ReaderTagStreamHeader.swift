import Foundation
import WordPressShared

@objc open class ReaderTagStreamHeader: UIView, ReaderStreamHeader {
    @IBOutlet fileprivate weak var titleLabel: UILabel!
    @IBOutlet fileprivate weak var followButton: UIButton!

    open weak var delegate: ReaderStreamHeaderDelegate?

    // MARK: - Lifecycle Methods
    open override func awakeFromNib() {
        super.awakeFromNib()

        applyStyles()
        adjustInsetsForTextDirection()
    }

    @objc func applyStyles() {
        WPStyleGuide.applyReaderStreamHeaderTitleStyle(titleLabel, usesNewStyle: RemoteFeatureFlag.readerImprovements.enabled())
    }

    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            WPStyleGuide.applyReaderFollowButtonStyle(followButton)
        }
    }


    // MARK: - Configuration

    @objc open func configureHeader(_ topic: ReaderAbstractTopic) {
        titleLabel.text = {
            guard RemoteFeatureFlag.readerImprovements.enabled() else {
                return topic.title
            }
            return topic.title.split(separator: "-").map { $0.capitalized }.joined(separator: " ")
        }()
        followButton.isSelected = topic.following
        WPStyleGuide.applyReaderFollowButtonStyle(followButton)
    }

    @objc open func enableLoggedInFeatures(_ enable: Bool) {

    }

    fileprivate func adjustInsetsForTextDirection() {
        followButton.flipInsetsForRightToLeftLayoutDirection()
    }

    // MARK: - Actions

    @IBAction func didTapFollowButton(_ sender: UIButton) {
        followButton.isUserInteractionEnabled = false

        delegate?.handleFollowActionForHeader(self, completion: { [weak self] in
            self?.followButton.isUserInteractionEnabled = true
        })
    }
}
