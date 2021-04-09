import Foundation
import WordPressShared

open class AppIconViewController: UITableViewController {

    private enum Section: Int {
        case current
        // Legacy icons are our v1 custom icons,
        // which will be removed at some point in the future.
        case legacy

        var title: String? {
            switch self {
            case .current:
                return nil
            case .legacy:
                return NSLocalizedString("Legacy Icons", comment: "Title displayed for selection of custom app icons that may be removed in a future release of the app.")
            }
        }
    }

    private var icons = [[AppIcon]]()
    private var borderedIcons = [String]()

    convenience init() {
        self.init(style: .grouped)

        loadIcons()
    }

    open override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("App Icon", comment: "Title of screen to change the app's icon")

        WPStyleGuide.configureColors(view: view, tableView: tableView)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: Constants.cellIdentifier)
        tableView.rowHeight = Constants.rowHeight
    }

    // MARK: - UITableview Data Source

    open override func numberOfSections(in tableView: UITableView) -> Int {
        return icons.count
    }

    open override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return Section(rawValue: section)?.title
    }

    open override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return icons[section].count
    }

    open override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let icon = icons[indexPath.section][indexPath.row]

        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.cellIdentifier, for: indexPath)

        cell.textLabel?.text = icon.name

        if let imageView = cell.imageView {
            imageView.image = UIImage(named: icon.imageName)
            imageView.layer.cornerRadius = Constants.cornerRadius
            imageView.layer.masksToBounds = true
            imageView.layer.borderColor = Constants.iconBorderColor?.cgColor
            imageView.layer.borderWidth = icon.isBordered ? Constants.iconBorderWidth : 0
            imageView.layer.cornerCurve = .continuous
        }

        cell.accessoryType = iconIsSelected(for: indexPath) ? .checkmark : .none

        return cell
    }

    private func iconIsSelected(for indexPath: IndexPath) -> Bool {
        let currentIconName = UIApplication.shared.alternateIconName

        // If there's no custom icon in use and we're checking the top (default) row
        let isDefaultIconInUse = currentIconName == nil
        if isDefaultIconInUse && indexPath.section == Section.current.rawValue && indexPath.row == 0 {
            return true
        }

        let icon = icons[indexPath.section][indexPath.row]
        return currentIconName == icon.name
    }

    open override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let isOriginalIconRow = (indexPath.section == Section.current.rawValue && indexPath.row == 0)
        let icon = isOriginalIconRow ? nil : icons[indexPath.section][indexPath.row].name

        UIApplication.shared.setAlternateIconName(icon, completionHandler: { [weak self] error in
            if error == nil {
                let event: WPAnalyticsStat = isOriginalIconRow ? .appIconReset : .appIconChanged
                WPAppAnalytics.track(event)
            }

            self?.tableView.reloadData()
        })
    }

    // MARK: - Private helpers

    private func loadIcons() {
        let defaultIcon = AppIcon(name: Constants.defaultIconName, isBordered: false, isLegacy: false)
        let iconDict = [defaultIcon] + infoPlistIconsDict

        // Produces a closure which sorts alphabetically, giving priority to items
        // beginning with the specified prefix.
        func sortWithPriority(toItemsWithPrefix prefix: String) -> ((AppIcon, AppIcon) -> Bool) {
            return { (first, second) in
                let firstIsDefault = first.name.hasPrefix(prefix)
                let secondIsDefault = second.name.hasPrefix(prefix)

                if firstIsDefault && !secondIsDefault {
                    return true
                } else if !firstIsDefault && secondIsDefault {
                    return false
                }

                return first.name < second.name
            }
        }

        // Filter out the current and legacy icon groups, with the Blue icons sorted to the top.
        let currentIcons = iconDict.filter({ $0.isLegacy == false })
                                   .sorted(by: sortWithPriority(toItemsWithPrefix: Constants.defaultIconName))
        let legacyIcons = iconDict.filter({ $0.isLegacy == true })
                                  .sorted(by: sortWithPriority(toItemsWithPrefix: Constants.defaultLegacyIconName))

        self.icons = [currentIcons, legacyIcons]
    }

    private var infoPlistIconsDict: [AppIcon] {
        guard let bundleDict = Bundle.main.object(forInfoDictionaryKey: Constants.infoPlistBundleIconsKey) as? [String: Any],
            let iconDict = bundleDict[Constants.infoPlistAlternateIconsKey] as? [String: Any] else {
                return []
        }

        return iconDict.compactMap { (key, value) -> AppIcon? in
            guard let value = value as? [String: Any] else {
                return nil
            }

            let isBordered = value[Constants.infoPlistRequiresBorderKey] as? Bool == true
            let isLegacy = value[Constants.infoPlistLegacyIconKey] as? Bool == true
            return AppIcon(name: key, isBordered: isBordered, isLegacy: isLegacy)
        }
    }

    private enum Constants {
        static let rowHeight: CGFloat = 76.0
        static let cornerRadius: CGFloat = 13.0
        static let iconBorderColor: UIColor? = UITableView().separatorColor
        static let iconBorderWidth: CGFloat = 0.5

        static let cellIdentifier = "IconCell"

        static let iconPreviewBaseName = "icon-app-60x60"
        static let defaultIconName = "Blue"
        static let defaultLegacyIconName = "WordPress"

        static let infoPlistBundleIconsKey = "CFBundleIcons"
        static let infoPlistAlternateIconsKey = "CFBundleAlternateIcons"
        static let infoPlistRequiresBorderKey = "WPRequiresBorder"
        static let infoPlistLegacyIconKey = "WPLegacyIcon"
    }
}

private struct AppIcon {
    let name: String
    let isBordered: Bool
    let isLegacy: Bool

    var imageName: String {
        let lowered = name.lowercased().replacingMatches(of: " ", with: "-")
        return "\(lowered)-\(AppIcon.imageBaseName)"
    }

    private static let imageBaseName = "icon-app-60x60"
}
