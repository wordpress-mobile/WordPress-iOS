import Foundation
import WordPressShared

open class AppIconViewController: UITableViewController {

    // MARK: - Data

    private let viewModel: AppIconListViewModelType = AppIconListViewModel()

    private var icons: [AppIconListSection] {
        return viewModel.icons
    }

    // MARK: - Init

    public init() {
        super.init(style: .insetGrouped)
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Lifecycle

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
        return icons[section].title
    }

    open override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return icons[section].items.count
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

    open override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 89
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
        UserPersistentStoreFactory.instance().hasShownCustomAppIconUpgradeAlert = true

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
        return icons[indexPath.section][indexPath.row].isPrimary
    }

    private enum Constants {
        static let rowHeight: CGFloat = 76.0
        static let cornerRadius: CGFloat = 13.0
        static let iconBorderColor: UIColor? = UITableView().separatorColor

        static let cellIdentifier = "IconCell"
    }
}
