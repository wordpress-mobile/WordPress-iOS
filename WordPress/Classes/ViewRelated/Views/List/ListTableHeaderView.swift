/// Renders a table header view with bottom separator, and meant to be used
/// alongside `ListTableViewCell`.
///
/// This is used in Comments and Notifications as part of the Comments
/// Unification project.
///
class ListTableHeaderView: UITableViewHeaderFooterView, NibReusable {
    // MARK: IBOutlets

    @IBOutlet private weak var separatorsView: SeparatorsView!
    @IBOutlet private weak var titleLabel: UILabel!

    // MARK: Properties

    /// Added to provide objc support, since NibReusable protocol methods aren't accessible from objc.
    /// This should be removed when the caller is rewritten in Swift.
    @objc static let reuseIdentifier = defaultReuseID

    @objc static let estimatedRowHeight = 26

    @objc var title: String? {
        get {
            titleLabel.text
        }
        set {
            titleLabel.text = newValue?.localizedUppercase ?? String()
            accessibilityLabel = newValue
        }
    }

    // MARK: Initialization

    override func awakeFromNib() {
        super.awakeFromNib()

        // Hide text label to prevent values being shown due to interaction with
        // NSFetchedResultsController. By default, the results controller assigns the
        // value of sectionNameKeyPath to UITableHeaderFooterView's textLabel.
        textLabel?.isHidden = true

        // Set background color.
        // Note that we need to set it through `backgroundView`, or Xcode will lash out a warning.
        backgroundView = {
            let view = UIView(frame: self.bounds)
            view.backgroundColor = Style.sectionHeaderBackgroundColor
            return view
        }()

        // configure title label
        titleLabel.font = Style.sectionHeaderFont
        titleLabel.textColor = Style.sectionHeaderTitleColor

        // configure separators view
        separatorsView.bottomColor = Style.separatorColor
        separatorsView.bottomVisible = true
    }

    // MARK: Convenience

    private typealias Style = WPStyleGuide.List
}
