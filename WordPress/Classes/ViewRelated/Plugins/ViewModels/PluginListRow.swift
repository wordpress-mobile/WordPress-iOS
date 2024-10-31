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

        let iconPlaceholder = UIImage.gridicon(.plugins, size: iconSize)
        cell.iconImageView?.cancelImageDownload()

        if let iconURL = iconURL {
            cell.iconImageView?.downloadResizedImage(from: iconURL, placeholderImage: iconPlaceholder, pointSize: iconSize)
        } else {
            cell.iconImageView?.image = iconPlaceholder
        }

        cell.selectionStyle = .default
        cell.pluginAccessoryView = accessoryView
    }

}
