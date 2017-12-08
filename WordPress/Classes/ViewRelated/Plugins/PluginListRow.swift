import Gridicons

struct PluginListRow: ImmuTableRow {
    static let cell = ImmuTableCell.class(WPTableViewCellSubtitle.self)
    let name: String
    let state: String
    let iconURL: URL?
    let updateState: PluginState.UpdateState
    let action: ImmuTableAction?
    private let iconSize = CGSize(width: 40, height: 40)

    func configureCell(_ cell: UITableViewCell) {
        WPStyleGuide.configureTableViewSmallSubtitleCell(cell)
        cell.textLabel?.text = name
        cell.detailTextLabel?.text = state
        let iconPlaceholder = Gridicon.iconOfType(.plugins, withSize: iconSize)
        cell.imageView?.downloadResizedImage(iconURL, placeholderImage: iconPlaceholder, pointSize: iconSize)
        cell.selectionStyle = .default
        switch updateState {
        case .available(_):
            cell.accessoryView = UIImageView(image: #imageLiteral(resourceName: "gridicon-sync-circled"))
        case .updating(_):
            // It woudld be nice to show the image spinning while updating
            cell.accessoryView = UIImageView(image: #imageLiteral(resourceName: "gridicon-sync-circled"))
        case .updated:
            cell.accessoryType = .disclosureIndicator
        }
    }
}
