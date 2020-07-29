import Foundation
import WordPressShared
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T: Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T: Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


@objc open class ReaderSiteStreamHeader: UIView, ReaderStreamHeader {
    @IBOutlet fileprivate weak var avatarImageView: UIImageView!
    @IBOutlet fileprivate weak var titleLabel: UILabel!
    @IBOutlet fileprivate weak var detailLabel: UILabel!
    @IBOutlet fileprivate weak var followButton: UIButton!
    @IBOutlet fileprivate weak var followCountLabel: UILabel!
    @IBOutlet fileprivate weak var descriptionLabel: UILabel!

    open var delegate: ReaderStreamHeaderDelegate?
    fileprivate var defaultBlavatar = "blavatar-default"

    // MARK: - Lifecycle Methods

    open override func awakeFromNib() {
        super.awakeFromNib()

        applyStyles()
    }

    @objc func applyStyles() {
        WPStyleGuide.applyReaderStreamHeaderTitleStyle(titleLabel)
        WPStyleGuide.applyReaderStreamHeaderDetailStyle(detailLabel)
        WPStyleGuide.applyReaderSiteStreamDescriptionStyle(descriptionLabel)
        WPStyleGuide.applyReaderSiteStreamCountStyle(followCountLabel)
    }

    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if previousTraitCollection?.preferredContentSizeCategory != traitCollection.preferredContentSizeCategory {
                   preferredContentSizeDidChange()
        }

        if #available(iOS 13.0, *) {
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                WPStyleGuide.applyReaderFollowButtonStyle(followButton)
            }
        }
    }

    // MARK: - Configuration

    @objc open func configureHeader(_ topic: ReaderAbstractTopic) {
        guard let siteTopic = topic as? ReaderSiteTopic else {
            DDLogError("Topic must be a site topic")
            return
        }

        followButton.isSelected = topic.following
        titleLabel.text = siteTopic.title
        descriptionLabel.text = siteTopic.siteDescription
        followCountLabel.text = formattedFollowerCountForTopic(siteTopic)
        detailLabel.text = URL(string: siteTopic.siteURL)?.host

        configureHeaderImage(siteTopic.siteBlavatar)

        WPStyleGuide.applyReaderFollowButtonStyle(followButton)

        if descriptionLabel.attributedText?.length > 0 {
            descriptionLabel.isHidden = false
        } else {
            descriptionLabel.isHidden = true
        }
    }

    @objc func configureHeaderImage(_ siteBlavatar: String?) {
        let placeholder = UIImage(named: defaultBlavatar)

        var path = ""
        if siteBlavatar != nil {
            path = siteBlavatar!
        }

        let url = URL(string: path)
        if url != nil {
            avatarImageView.downloadImage(from: url, placeholderImage: placeholder)
        } else {
            avatarImageView.image = placeholder
        }
    }

    @objc func formattedFollowerCountForTopic(_ topic: ReaderSiteTopic) -> String {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal

        let count = numberFormatter.string(from: topic.subscriberCount) ?? "0"
        let pattern = NSLocalizedString("%@ followers", comment: "The number of followers of a site. The '%@' is a placeholder for the numeric value. Example: `1000 followers`")
        let str = String(format: pattern, count)

        return str
    }

    @objc open func enableLoggedInFeatures(_ enable: Bool) {
        followButton.isHidden = !enable
    }

    func preferredContentSizeDidChange() {
        applyStyles()
    }

    // MARK: - Actions

    @IBAction func didTapFollowButton(_ sender: UIButton) {
        delegate?.handleFollowActionForHeader(self)
    }
}
