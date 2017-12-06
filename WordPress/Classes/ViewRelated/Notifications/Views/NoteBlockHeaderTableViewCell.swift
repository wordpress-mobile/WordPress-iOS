import Foundation
import WordPressShared.WPStyleGuide


// MARK: - NoteBlockHeaderTableViewCell
//
class NoteBlockHeaderTableViewCell: NoteBlockTableViewCell {

    // MARK: - Private
    private var gravatarURL: URL?
    private typealias Style = WPStyleGuide.Notifications

    // MARK: - IBOutlets
    @IBOutlet private var gravatarImageView: UIImageView!
    @IBOutlet private var headerTitleLabel: UILabel!
    @IBOutlet private var headerDetailsLabel: UILabel!

    // MARK: - Public Properties
    @objc var headerTitle: String? {
        set {
            headerTitleLabel.text  = newValue
        }
        get {
            return headerTitleLabel.text
        }
    }

    @objc var attributedHeaderTitle: NSAttributedString? {
        set {
            headerTitleLabel.attributedText  = newValue
        }
        get {
            return headerTitleLabel.attributedText
        }
    }

    @objc var headerDetails: String? {
        set {
            headerDetailsLabel.text = newValue
        }
        get {
            return headerDetailsLabel.text
        }
    }


    // MARK: - Public Methods
    @objc func downloadGravatar(with url: URL?) {
        guard url != gravatarURL else {
            return
        }

        if let siteIconUrl = url?.absoluteString {
            gravatarImageView.setImageWithSiteIcon(siteIconUrl, placeholderImage: Style.gravatarPlaceholderImage)
        }

        gravatarURL = url
    }

    // MARK: - View Methods
    override func awakeFromNib() {
        super.awakeFromNib()

        accessoryType = .disclosureIndicator
        backgroundColor = Style.blockBackgroundColor

        headerTitleLabel.font = Style.headerTitleBoldFont
        headerTitleLabel.textColor = Style.headerTitleColor
        headerDetailsLabel.font = Style.headerDetailsRegularFont
        headerDetailsLabel.textColor = Style.headerDetailsColor
        gravatarImageView.image = Style.gravatarPlaceholderImage
    }

    // MARK: - Overriden Methods
    override func refreshSeparators() {
        separatorsView.bottomVisible = true
        separatorsView.bottomInsets = UIEdgeInsets.zero
    }
}
