import UIKit
import WordPressShared

// MARK: - SiteInfoHeaderView
//
class SiteInfoHeaderView: UIView {

    // MARK: - Outlets
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var subtitleLabel: UILabel!
    @IBOutlet private var blavatarImageView: UIImageView!

    // MARK: - Properties

    /// Site Title
    ///
    var title: String? {
        get {
            return titleLabel.text
        }
        set {
            titleLabel.text = newValue
        }
    }

    /// Site Subtitle
    ///
    var subtitle: String? {
        get {
            return subtitleLabel.text
        }
        set {
            subtitleLabel.text = newValue
        }
    }

    /// When enabled, the Subtitle won't be rendered.
    ///
    var subtitleIsHidden: Bool = true {
        didSet {
            refreshLabelStyles()
        }
    }

    /// When enabled, renders a border around the Blavatar.
    ///
    var blavatarBorderIsHidden: Bool = false {
        didSet {
            refreshBlavatarStyle()
        }
    }

    /// Returns (or sets) the Site's Blavatar Image.
    ///
    var blavatarImage: UIImage? {
        get {
            return blavatarImageView.image
        }
        set {
            blavatarImageView.image = newValue
        }
    }

    /// Downloads the Blavatar Image at the specified URL.
    ///
    func downloadBlavatar(at path: String) {
        blavatarImageView.image = .siteIconPlaceholderImage

        if let url = URL(string: path) {
            blavatarImageView.downloadImage(from: url)
        }
    }

    // MARK: - Overriden Methods

    override func awakeFromNib() {
        super.awakeFromNib()
        refreshLabelStyles()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        guard previousTraitCollection?.preferredContentSizeCategory != traitCollection.preferredContentSizeCategory else {
            return
        }

        refreshLabelStyles()
    }
}

// MARK: - Private
//
private extension SiteInfoHeaderView {

    func refreshLabelStyles() {
        let titleWeight: UIFont.Weight = subtitleIsHidden ? .regular : .semibold
        titleLabel.font = WPStyleGuide.fontForTextStyle(.subheadline, fontWeight: titleWeight)
        titleLabel.textColor = WPStyleGuide.darkGrey()

        subtitleLabel.isHidden = subtitleIsHidden
        subtitleLabel.font = WPStyleGuide.fontForTextStyle(.footnote)
        subtitleLabel.textColor = WPStyleGuide.darkGrey()
    }

    func refreshBlavatarStyle() {
        if blavatarBorderIsHidden {
            blavatarImageView.layer.borderWidth = 0
            blavatarImageView.tintColor = WordPressAuthenticator.shared.style.placeholderColor
        } else {
            blavatarImageView.layer.borderColor = WordPressAuthenticator.shared.style.instructionColor.cgColor
            blavatarImageView.layer.borderWidth = 1
            blavatarImageView.tintColor = WordPressAuthenticator.shared.style.placeholderColor
        }
    }
}
