import Foundation
import WordPressShared

open class AppIconViewController: UITableViewController {
    
    private static let iconBaseName = "icon_40pt"
    
    private enum Constants {
        static let rowHeight: CGFloat = 58.0
        static let cornerRadius: CGFloat = 4.0
        static let cellIdentifier = "IconCell"
        static let defaultIconName = "WordPress"
        static let jetpackIconName = "Jetpack"
        static let infoPlistBundleIconsKey = "CFBundleIcons"
        static let infoPlistAlternateIconsKey = "CFBundleAlternateIcons"
    }
    
    private let icons: [String] = {
        var icons = [Constants.defaultIconName]

        // Load the names of the alternative app icons from the info plist
        guard let bundleDict = Bundle.main.object(forInfoDictionaryKey: Constants.infoPlistBundleIconsKey) as? [String:Any],
            let iconDict = bundleDict[Constants.infoPlistAlternateIconsKey] as? [String:Any] else {
                return icons
        }

        // Add them to the default key
        icons.append(contentsOf: iconDict.keys.sorted())

        // Only show the Jetpack icon if the user has a Jetpack-connected site in the app.
        if BlogService(managedObjectContext: ContextManager.shared.mainContext).hasAnyJetpackBlogs() == false {
            icons.removeAll(where: { $0 == Constants.jetpackIconName })
        }
        
        return icons
    }()

    convenience init() {
        self.init(style: .grouped)
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
        return 1
    }
    
    open override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return icons.count
    }
    
    open override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let icon = icons[indexPath.row]

        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.cellIdentifier, for: indexPath)
        cell.imageView?.image = UIImage(named: previewImageName(for: icon))
        cell.imageView?.layer.cornerRadius = Constants.cornerRadius
        cell.imageView?.layer.masksToBounds = true

        cell.textLabel?.text = icon
        
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
        return "\(lowered)_\(AppIconViewController.iconBaseName)"
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
}
