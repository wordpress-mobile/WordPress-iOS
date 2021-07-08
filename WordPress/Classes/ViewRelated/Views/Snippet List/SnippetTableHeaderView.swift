import UIKit

/// Renders a table header view with bottom separator, and meant to be used
/// alongside `SnippetTableViewCell`.
///
/// This is used in Comments and Notifications as part of the Comments
/// Unification project.
///
class SnippetTableHeaderView: UITableViewHeaderFooterView, NibReusable {
    // MARK: IBOutlets

    @IBOutlet private weak var separatorsView: SeparatorsView!
    @IBOutlet weak var titleLabel: UILabel!

    // MARK: Initialization

    override func awakeFromNib() {
        super.awakeFromNib()

        // configure title label
        titleLabel.textColor = .textSubtle

        // configure separators view
        separatorsView.backgroundColor = .systemBackground
        separatorsView.bottomVisible = true
    }
}
