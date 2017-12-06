import Gridicons

struct PluginListRow: ImmuTableRow {
    static let cell = ImmuTableCell.class(WPTableViewCellSubtitle.self)
    let name: String
    let state: String
    let iconURL: URL?
    let action: ImmuTableAction?

    func configureCell(_ cell: UITableViewCell) {
        WPStyleGuide.configureTableViewSmallSubtitleCell(cell)
        cell.textLabel?.text = name
        cell.detailTextLabel?.text = state
        let iconPlaceholder = Gridicon.iconOfType(.plugins)
        if let iconURL = iconURL {
            cell.imageView?.setImageWith(iconURL, placeholderImage: iconPlaceholder)
        } else {
            cell.imageView?.image = iconPlaceholder
        }
        cell.selectionStyle = .default
        cell.accessoryType = .disclosureIndicator
    }
}
