import Foundation
import WordPressShared

open class AppIconViewController: UITableViewController {

    private enum Section: Int {
        case currentColorfulBackground
        case currentLightBackground
        // Legacy icons are our v1 custom icons,
        // which will be removed at some point in the future.
        case legacy

        var title: String? {
            switch self {
            case .currentColorfulBackground:
                return NSLocalizedString("Colorful backgrounds", comment: "Title displayed for selection of custom app icons that have colorful backgrounds.")
            case .currentLightBackground:
                return NSLocalizedString("Light backgrounds", comment: "Title displayed for selection of custom app icons that have white backgrounds.")
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

        if isModal() {
            navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelTapped))
        }
    }

    @objc
    private func cancelTapped() {
        dismiss(animated: true, completion: nil)
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

        cell.textLabel?.text = icon.displayName

        if let imageView = cell.imageView {
            imageView.image = UIImage(named: icon.imageName)
            imageView.layer.cornerRadius = Constants.cornerRadius
            imageView.layer.masksToBounds = true
            imageView.layer.borderColor = Constants.iconBorderColor?.cgColor
            imageView.layer.borderWidth = icon.isBordered ? .hairlineBorderWidth : 0
            imageView.layer.cornerCurve = .continuous
        }

        cell.accessoryType = iconIsSelected(for: indexPath) ? .checkmark : .none

        return cell
    }

    private func iconIsSelected(for indexPath: IndexPath) -> Bool {
        let currentIconName = UIApplication.shared.alternateIconName

        // If there's no custom icon in use and we're checking the top (default) row
        let isDefaultIconInUse = currentIconName == nil
        if isDefaultIconInUse && isOriginalIcon(at: indexPath) {
            return true
        }

        let icon = icons[indexPath.section][indexPath.row]
        return currentIconName == icon.name
    }

    open override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard !iconIsSelected(for: indexPath) else {
            tableView.deselectRow(at: indexPath, animated: true)
            return
        }

        let isOriginalIcon = self.isOriginalIcon(at: indexPath)
        let iconName = isOriginalIcon ? nil : icons[indexPath.section][indexPath.row].name

        // Prevent showing the custom icon upgrade alert to a user
        // who's just set an icon for the first time.
        // We'll remove this alert after a couple of releases.
        UserDefaults.standard.hasShownCustomAppIconUpgradeAlert = true

        UIApplication.shared.setAlternateIconName(iconName, completionHandler: { [weak self] error in
            if error == nil {
                if isOriginalIcon {
                    WPAppAnalytics.track(.appIconReset)
                } else {
                    WPAppAnalytics.track(.appIconChanged, withProperties: ["icon_name": iconName ?? "default"])
                }
            }

            self?.tableView.reloadData()
        })
    }

    private func isOriginalIcon(at indexPath: IndexPath) -> Bool {
        return indexPath.section == Section.currentColorfulBackground.rawValue && indexPath.row == 0
    }

    // MARK: - Private helpers

    private func loadIcons() {
        let allIcons = AppIcon.allIcons

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
        let currentColorfulIcons = allIcons.filter({ $0.isLegacy == false && $0.isBordered == false })
                                           .sorted(by: sortWithPriority(toItemsWithPrefix: AppIcon.defaultIconName))
        let currentLightIcons = allIcons.filter({ $0.isLegacy == false && $0.isBordered == true })
                                        .sorted(by: sortWithPriority(toItemsWithPrefix: AppIcon.defaultIconName))
        let legacyIcons = allIcons.filter({ $0.isLegacy == true })
                                  .sorted(by: sortWithPriority(toItemsWithPrefix: AppIcon.defaultLegacyIconName))

        self.icons = [currentColorfulIcons, currentLightIcons, legacyIcons]
    }

    private enum Constants {
        static let rowHeight: CGFloat = 76.0
        static let cornerRadius: CGFloat = 13.0
        static let iconBorderColor: UIColor? = UITableView().separatorColor

        static let cellIdentifier = "IconCell"
    }
}
