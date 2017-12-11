import Gridicons

struct PluginListRow: ImmuTableRow {
    static let cell = ImmuTableCell.class(WPTableViewCellSubtitle.self)
    let name: String
    let state: String
    let iconURL: URL?
    let updateState: PluginState.UpdateState
    let action: ImmuTableAction?

    private let iconSize = CGSize(width: 40, height: 40)
    private let spinningAnimationKey = "spinning"

    func configureCell(_ cell: UITableViewCell) {
        WPStyleGuide.configureTableViewSmallSubtitleCell(cell)
        cell.textLabel?.text = name
        cell.detailTextLabel?.text = state
        let iconPlaceholder = Gridicon.iconOfType(.plugins, withSize: iconSize)
        cell.imageView?.downloadResizedImage(iconURL, placeholderImage: iconPlaceholder, pointSize: iconSize)
        cell.selectionStyle = .default
        switch updateState {
        case .available:
            cell.accessoryView = UIImageView(image: #imageLiteral(resourceName: "gridicon-sync-circled"))
        case .updating:
            cell.accessoryView = spinningImageView(image: #imageLiteral(resourceName: "gridicon-sync-circled"))
        case .updated:
            cell.accessoryType = .disclosureIndicator
        }
    }

    private func spinningImageView(image: UIImage?) -> UIImageView {
        let animation = CABasicAnimation(keyPath: "transform.rotation")
        animation.duration = 1
        animation.repeatCount = Float.infinity
        animation.fromValue = 0.0
        animation.toValue = Float(Float.pi * 2.0)
        let imageView = UIImageView(image: image)
        imageView.layer.add(animation, forKey: spinningAnimationKey)
        return imageView
    }
}
