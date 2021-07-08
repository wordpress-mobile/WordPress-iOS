/// Renders a table header view with bottom separator, and meant to be used
/// alongside `SnippetTableViewCell`.
///
/// This is used in Comments and Notifications as part of the Comments
/// Unification project.
///
class SnippetTableHeaderView: UITableViewHeaderFooterView, NibReusable {
    // MARK: IBOutlets

    @IBOutlet private weak var separatorsView: SeparatorsView!
    @IBOutlet private weak var titleLabel: UILabel!

    // MARK: Properties

    @objc var title: String? {
        get {
            titleLabel.text
        }
        set {
            titleLabel.text = newValue?.localizedUppercase ?? String()
        }
    }

    // MARK: Initialization

    override func awakeFromNib() {
        super.awakeFromNib()

        // Hide text label to prevent values being overwritten due to interaction with
        // NSFetchedResultsController. By default, the results controller assigns the
        // value of sectionNameKeyPath to UITableHeaderFooterView's textLabel.
        textLabel?.isHidden = true

        // configure title label
        titleLabel.font = WPStyleGuide.fontForTextStyle(.footnote, fontWeight: .semibold)
        titleLabel.textColor = .textSubtle

        // configure separators view
        separatorsView.backgroundColor = .systemBackground
        separatorsView.bottomVisible = true
    }
}
