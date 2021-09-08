import Foundation
import WordPressShared
import Gridicons

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
    @IBOutlet fileprivate weak var descriptionLabelTopConstraint: NSLayoutConstraint!

    open var delegate: ReaderStreamHeaderDelegate?
    fileprivate var defaultBlavatar = "blavatar-default"

    // MARK: - Lifecycle Methods

    open override func awakeFromNib() {
        super.awakeFromNib()

        applyStyles()
    }

    private func applyStyles() {
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

        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            WPStyleGuide.applyReaderFollowButtonStyle(followButton)
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

        configureHeaderImage(siteTopic)

        WPStyleGuide.applyReaderFollowButtonStyle(followButton)

        if siteTopic.siteDescription.isEmpty {
            descriptionLabelTopConstraint.constant = 0.0
        }
    }

    private func configureHeaderImage(_ siteTopic: ReaderSiteTopic) {
        let placeholder = UIImage.siteIconPlaceholder

        guard let url = upscaledImageURL(urlString: siteTopic.siteBlavatar) else {
            if siteTopic.isP2Type {
                avatarImageView.tintColor = UIColor.listIcon
                avatarImageView.layer.borderColor = UIColor.divider.cgColor
                avatarImageView.layer.borderWidth = .hairlineBorderWidth
                avatarImageView.image = UIImage.gridicon(.p2)
                return
            }

            avatarImageView.image = placeholder
            return
        }

        avatarImageView.downloadImage(from: url, placeholderImage: placeholder)
    }

    private func formattedFollowerCountForTopic(_ topic: ReaderSiteTopic) -> String {
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
        followButton.isUserInteractionEnabled = false

        delegate?.handleFollowActionForHeader(self) { [weak self] in
            self?.followButton.isUserInteractionEnabled = true
        }
    }

    // MARK: - Private: Helpers

    /// Replaces the width query item (w) with an upscaled one for the image view
    private func upscaledImageURL(urlString: String) -> URL? {
        guard
            let url = URL(string: urlString),
            var components = URLComponents(url: url, resolvingAgainstBaseURL: true),
            let host = components.host
        else {
            return nil
        }

        // WP.com uses `w` and Gravatar uses `s` for the resizing query key
        let widthKey = host.contains("gravatar") ? "s" : "w"
        let width = Int(avatarImageView.bounds.width * UIScreen.main.scale)
        let item = URLQueryItem(name: widthKey, value: "\(width)")

        var queryItems = components.queryItems ?? []

        // Remove any existing size queries
        queryItems.removeAll(where: { $0.name == widthKey})

        queryItems.append(item)
        components.queryItems = queryItems

        return components.url
    }
}
