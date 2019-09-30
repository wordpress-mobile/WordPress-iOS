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
    @IBOutlet fileprivate weak var borderedView: UIView!
    @IBOutlet fileprivate weak var avatarImageView: UIImageView!
    @IBOutlet fileprivate weak var titleLabel: UILabel!
    @IBOutlet fileprivate weak var detailLabel: UILabel!
    @IBOutlet fileprivate weak var followButton: PostMetaButton!
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
        backgroundColor = .listBackground
        borderedView.backgroundColor = .listForeground
        borderedView.layer.borderColor = WPStyleGuide.readerCardCellBorderColor().cgColor
        borderedView.layer.borderWidth = .hairlineBorderWidth
        WPStyleGuide.applyReaderStreamHeaderTitleStyle(titleLabel)
        WPStyleGuide.applyReaderStreamHeaderDetailStyle(detailLabel)
        WPStyleGuide.applyReaderSiteStreamDescriptionStyle(descriptionLabel)
        WPStyleGuide.applyReaderSiteStreamCountStyle(followCountLabel)
    }


    // MARK: - Configuration

    @objc open func configureHeader(_ topic: ReaderAbstractTopic) {
        assert(topic.isKind(of: ReaderSiteTopic.self), "Topic must be a site topic")

        let siteTopic = topic as! ReaderSiteTopic

        configureHeaderImage(siteTopic.siteBlavatar)

        titleLabel.text = siteTopic.title
        detailLabel.text = URL(string: siteTopic.siteURL)?.host

        WPStyleGuide.applyReaderFollowButtonStyle(followButton)
        followButton.isSelected = topic.following

        descriptionLabel.attributedText = attributedSiteDescriptionForTopic(siteTopic)
        followCountLabel.text = formattedFollowerCountForTopic(siteTopic)

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

    @objc func attributedSiteDescriptionForTopic(_ topic: ReaderSiteTopic) -> NSAttributedString {
        return NSAttributedString(string: topic.siteDescription, attributes: WPStyleGuide.readerStreamHeaderDescriptionAttributes())
    }

    @objc open func enableLoggedInFeatures(_ enable: Bool) {
        followButton.isHidden = !enable
    }

    override open func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if previousTraitCollection?.preferredContentSizeCategory != traitCollection.preferredContentSizeCategory {
            preferredContentSizeDidChange()
        }
    }

    func preferredContentSizeDidChange() {
        applyStyles()
    }

    // MARK: - Actions

    @IBAction func didTapFollowButton(_ sender: UIButton) {
        delegate?.handleFollowActionForHeader(self)
    }
}
