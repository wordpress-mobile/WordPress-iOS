import Foundation
import WordPressShared

/// This class renders a view with top and bottom separators, meant to be used as UITableView section
/// header in NotificationsViewController.
///
class NoteTableHeaderView: UIView
{
    // MARK: - Public Properties
    var title: String? {
        set {
            // For layout reasons, we need to ensure that the titleLabel uses an exact Paragraph Height!
            let unwrappedTitle = newValue?.uppercaseStringWithLocale(NSLocale.currentLocale()) ?? String()
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
            layoutView.bottomColor = newValue ?? UIColor.clearColor()
            layoutView.topColor = newValue ?? UIColor.clearColor()
        }
        get {
            return layoutView.bottomColor
        }
    }



    // MARK: - Convenience Initializers
    convenience init() {
        self.init(frame: CGRectZero)
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
    private func setupView() {
        NSBundle.mainBundle().loadNibNamed("NoteTableHeaderView", owner: self, options: nil)
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
        backgroundColor = UIColor.clearColor()

        layoutView.backgroundColor = Style.sectionHeaderBackgroundColor
        layoutView.bottomVisible = true
        layoutView.topVisible = true
    }



    // MARK: - Aliases
    typealias Style = WPStyleGuide.Notifications

    // MARK: - Static Properties
    static let headerHeight  = CGFloat(26)

    // MARK: - Outlets
    @IBOutlet private var contentView: UIView!
    @IBOutlet private var layoutView: SeparatorsView!
    @IBOutlet private var imageView: UIImageView!
    @IBOutlet private var titleLabel: UILabel!
}
