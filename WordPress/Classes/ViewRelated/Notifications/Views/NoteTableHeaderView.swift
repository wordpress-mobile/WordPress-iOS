import Foundation
import WordPressShared

/// This class renders a view with top and bottom separators, meant to be used as UITableView section
/// header in NotificationsViewController.
///
class NoteTableHeaderView: UIView {
    // MARK: - Public Properties
    @objc var title: String? {
        set {
            // For layout reasons, we need to ensure that the titleLabel uses an exact Paragraph Height!
            let unwrappedTitle = newValue?.localizedUppercase ?? String()
            let attributes = Style.sectionHeaderRegularStyle
            titleLabel.attributedText = NSAttributedString(string: unwrappedTitle, attributes: attributes)

            contentView.accessibilityLabel = unwrappedTitle
        }
        get {
            return titleLabel.text
        }
    }

    @objc var separatorColor: UIColor? {
        set {
            contentView.bottomColor = newValue ?? UIColor.clear
            contentView.topColor = newValue ?? UIColor.clear
        }
        get {
            return contentView.bottomColor
        }
    }

    @objc class func makeFromNib() -> NoteTableHeaderView {
        return Bundle.main.loadNibNamed("NoteTableHeaderView", owner: self, options: nil)?.first as! NoteTableHeaderView
    }

    // MARK: - Convenience Initializers
    override func awakeFromNib() {
        super.awakeFromNib()

        // Make sure the Outlets are loaded
        assert(contentView != nil)
        assert(titleLabel != nil)

        // Background + Separators
        backgroundColor = UIColor.clear

        contentView.backgroundColor = Style.sectionHeaderBackgroundColor
        contentView.bottomVisible = true
        contentView.topVisible = true
    }


    // MARK: - Aliases
    typealias Style = WPStyleGuide.Notifications

    // MARK: - Static Properties
    @objc static let estimatedHeight = CGFloat(26)

    // MARK: - Outlets
    @IBOutlet fileprivate var contentView: SeparatorsView!
    @IBOutlet fileprivate var titleLabel: UILabel!
}
