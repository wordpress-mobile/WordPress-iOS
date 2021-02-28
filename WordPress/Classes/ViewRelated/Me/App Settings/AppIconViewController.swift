import Foundation
import WordPressShared

open class AppIconViewController: UITableViewController {

    private enum Constants {
        static let rowHeight: CGFloat = 58.0
        static let cornerRadius: CGFloat = 4.0
        static let iconBorderColor: UIColor? = UITableView().separatorColor
        static let iconBorderWidth: CGFloat = 0.5

        static let cellIdentifier = "IconCell"

        static let iconPreviewBaseName = "icon_40pt"
        static let defaultIconName = "WordPress"
        static let jetpackIconName = "Jetpack Green"

        static let infoPlistBundleIconsKey = "CFBundleIcons"
        static let infoPlistAlternateIconsKey = "CFBundleAlternateIcons"
        static let infoPlistRequiresBorderKey = "WPRequiresBorder"
    }

    private var icons: [String] = []
    private var borderedIcons: [String] = []

    convenience init() {
        self.init(style: .grouped)

        loadIcons()
        loadBorderedIcons()
    }

    open override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("App Icon", comment: "Title of screen to change the app's icon")

        WPStyleGuide.configureColors(view: view, tableView: tableView)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: Constants.cellIdentifier)
        tableView.rowHeight = Constants.rowHeight
    }

    // MARK: - UITableview Data Source

    open override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return icons.count
    }

    open override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let icon = icons[indexPath.row]

        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.cellIdentifier, for: indexPath)

        cell.textLabel?.text = icon

        if let imageView = cell.imageView {
            let image = UIImage(named: previewImageName(for: icon))
            imageView.image = image
            imageView.layer.cornerRadius = Constants.cornerRadius
            imageView.layer.masksToBounds = true
            imageView.layer.borderColor = Constants.iconBorderColor?.cgColor
            imageView.layer.borderWidth = borderedIcons.contains(icon) ? Constants.iconBorderWidth : 0
        }

        let isDefaultIconInUse = UIApplication.shared.alternateIconName == nil
        if (isDefaultIconInUse && indexPath.row == 0) || UIApplication.shared.alternateIconName == icon {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }

        return cell
    }

    private func previewImageName(for icon: String) -> String {
        let lowered = icon.lowercased().replacingMatches(of: " ", with: "_")
        return "\(lowered)_\(Constants.iconPreviewBaseName)"
    }

    open override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let isOriginalIconRow = (indexPath.row == 0)
        let icon = isOriginalIconRow ? nil : icons[indexPath.row]

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
        var icons = [Constants.defaultIconName]

        // Load the names of the alternative app icons from the info plist
        guard let iconDict = infoPlistIconsDict else {
            self.icons = icons
            return
        }

        // Add them (sorted) to the default key – first any prefixed with WordPress, then the rest.
        let keys = Set(iconDict.keys)
        let wordPressKeys = keys.filter({$0.hasPrefix("WordPress")}).sorted()
        let otherKeys = keys.subtracting(wordPressKeys).sorted()
        icons.append(contentsOf: (wordPressKeys + otherKeys))

        // Only show the Jetpack icon if the user has a Jetpack-connected site in the app.
        if !shouldShowJetpackIcon {
            icons.removeAll(where: { $0 == Constants.jetpackIconName })
        }

        self.icons = icons
    }

    private var shouldShowJetpackIcon: Bool {
        let context = ContextManager.shared.mainContext
        let hasJetpackSite = BlogService(managedObjectContext: context).hasAnyJetpackBlogs()
        let hasWPComSite = (try? WPAccount.lookupDefaultWordPressComAccount(in: context)) != nil

        return hasJetpackSite || hasWPComSite
    }

    private func loadBorderedIcons() {
        guard let iconDict = infoPlistIconsDict else {
            return
        }

        var icons: [String] = []

        // Find any icons that require a border – they have the `WPRequiresBorder` key set to YES.
        for (key, value) in iconDict {
            if let value = value as? [String: Any],
                let requiresBorder = value[Constants.infoPlistRequiresBorderKey] as? Bool,
                requiresBorder == true {
                icons.append(key)
            }
        }

        self.borderedIcons = icons
    }

    private var infoPlistIconsDict: [String: Any]? {
        guard let bundleDict = Bundle.main.object(forInfoDictionaryKey: Constants.infoPlistBundleIconsKey) as? [String: Any],
            let iconDict = bundleDict[Constants.infoPlistAlternateIconsKey] as? [String: Any] else {
                return nil
        }

        return iconDict
    }
}
