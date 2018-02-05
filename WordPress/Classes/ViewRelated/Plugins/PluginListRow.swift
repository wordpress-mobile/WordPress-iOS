import Gridicons

struct PluginListRow: ImmuTableRow {
    static let cell: ImmuTableCell = {
        let nib = UINib(nibName: "PluginListCell", bundle: Bundle(for: PluginListCell.self))
        return ImmuTableCell.nib(nib, PluginListCell.self)
    }()

    let name: String
    let author: String
    let iconURL: URL?
    let accessoryView: UIView
    let action: ImmuTableAction?

    private let iconSize = CGSize(width: 40, height: 40)

    func configureCell(_ cell: UITableViewCell) {
        guard let cell = cell as? PluginListCell else {
            return
        }
        
        cell.nameLabel?.text = name
        cell.authorLabel?.text = author

        let iconPlaceholder = Gridicon.iconOfType(.plugins, withSize: iconSize)
        cell.iconImageView?.cancelImageDownloadTask()
        cell.iconImageView?.downloadResizedImage(iconURL, placeholderImage: iconPlaceholder, pointSize: iconSize)

        cell.selectionStyle = .default
        cell.pluginAccessoryView = accessoryView
    }

}
