import Foundation
import WordPressShared

/// This class renders a view with top and bottom separators, meant to be used as UITableView section
/// header in NotificationsViewController.
///
class NoteTableHeaderView: UIView {
    // MARK: - Public Properties
    var title: String? {
        set {
            // For layout reasons, we need to ensure that the titleLabel uses an exact Paragraph Height!
            let unwrappedTitle = newValue?.uppercased(with: Locale.current) ?? String()
            let attributes = Style.sectionHeaderRegularStyle
            titleLabel.attributedText = NSAttributedString(string: unwrappedTitle, attributes: attributes)
            setNeedsLayout()
        }
        get {
            return titleLabel.text
        }
    }

    var separatorColor: UIColor? {
        set {
            layoutView.bottomColor = newValue ?? UIColor.clear
            layoutView.topColor = newValue ?? UIColor.clear
        }
        get {
            return layoutView.bottomColor
        }
    }



    // MARK: - Convenience Initializers
    convenience init() {
        self.init(frame: CGRect.zero)
    }

    required override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        setupView()
    }



    // MARK - Private Helpers
    fileprivate func setupView() {
        Bundle.main.loadNibNamed("NoteTableHeaderView", owner: self, options: nil)
        addSubview(contentView)

        // Make sure the Outlets are loaded
        assert(contentView != nil)
        assert(layoutView != nil)
        assert(imageView != nil)
        assert(titleLabel != nil)

        // Layout
        contentView.translatesAutoresizingMaskIntoConstraints = false
        pinSubviewToAllEdges(contentView)

        // Background + Separators
        backgroundColor = UIColor.clear

        layoutView.backgroundColor = Style.sectionHeaderBackgroundColor
        layoutView.bottomVisible = true
        layoutView.topVisible = true

        titleLabel.backgroundColor = Style.sectionHeaderBackgroundColor
    }



    // MARK: - Aliases
    typealias Style = WPStyleGuide.Notifications

    // MARK: - Static Properties
    static let headerHeight  = CGFloat(26)

    // MARK: - Outlets
    @IBOutlet fileprivate var contentView: UIView!
    @IBOutlet fileprivate var layoutView: SeparatorsView!
    @IBOutlet fileprivate var imageView: UIImageView!
    @IBOutlet fileprivate var titleLabel: UILabel!
}
