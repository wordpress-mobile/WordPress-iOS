import Gridicons

struct PluginListRow: ImmuTableRow {
    static let cell = ImmuTableCell.class(WPTableViewCellSubtitle.self)
    let name: String
    let state: String
    let action: ImmuTableAction?

    func configureCell(_ cell: UITableViewCell) {
        WPStyleGuide.configureTableViewSmallSubtitleCell(cell)
        cell.textLabel?.text = name
        cell.detailTextLabel?.text = state
        cell.imageView?.image = Gridicon.iconOfType(.plugins)
        cell.selectionStyle = .default
        cell.accessoryType = .disclosureIndicator
    }
}
