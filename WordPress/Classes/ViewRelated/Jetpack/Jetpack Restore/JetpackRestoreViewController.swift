import Foundation
import CocoaLumberjack
import WordPressShared

/// Represents the ways in which a user can restore a site
enum JetpackRestoreAction {
    /// restore: Restore a site to a particular point in time
    case restore
    /// downloadBackup: Download a backup and restore manually
    case downloadBackup
}

class JetpackRestoreViewController: UITableViewController {

    // MARK: - Private Properties

    private let site: JetpackSiteRef
    private let activity: FormattableActivity
    private let restoreAction: JetpackRestoreAction
    private lazy var handler: ImmuTableViewHandler = {
       return ImmuTableViewHandler(takeOver: self)
    }()

    // MARK: - Initializer

    init(site: JetpackSiteRef, activity: FormattableActivity, restoreAction: JetpackRestoreAction) {
        self.site = site
        self.activity = activity
        self.restoreAction = restoreAction
        super.init(style: .grouped)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        configureTitle()
        configureNavigation()
        configureTableView()
        reloadViewModel()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.layoutHeaderView()
    }

    // MARK: - Configure

    private func configureTitle() {
        switch restoreAction {
        case .restore:
            title = NSLocalizedString("Restore", comment: "Title for the Jetpack Restore Site Screen")
        case .downloadBackup:
            title = NSLocalizedString("Download Backup", comment: "Title for the Jetpack Download Backup Site Screen")
        }
    }

    private func configureNavigation() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel,
                                                           target: self,
                                                           action: #selector(cancelTapped))
    }

    private func configureTableView() {
        WPStyleGuide.configureColors(view: view, tableView: tableView)

        ImmuTable.registerRows([SwitchRow.self], tableView: tableView)

        let headerView = JetpackRestoreHeaderView.loadFromNib()
        headerView.configure(site: site, formattableActivity: activity, restoreAction: restoreAction)
        self.tableView.tableHeaderView = headerView
    }

    // MARK: - Private Helpers

    @objc private func cancelTapped() {
        self.dismiss(animated: true)
    }

    // MARK: - Model

    private func reloadViewModel() {
        handler.viewModel = tableViewModel()
    }

    private func tableViewModel() -> ImmuTable {
        return ImmuTable(
            sections: [
                generalSection(),
                contentSection(),
                databaseSection()
            ]
        )
    }

    private func generalSection() -> ImmuTableSection {
        let themesRow = SwitchRow(
            title: NSLocalizedString("WordPress Themes", comment: "Downloadable/Restorable items: WordPress Themes"),
            value: true,
            onChange: { _ in }
        )
        let pluginsRow = SwitchRow(
            title: NSLocalizedString("WordPress Plugins", comment: "Downloadable/Restorable items: WordPress Plugins"),
            value: true,
            onChange: { _ in }
        )
        let mediaUploadsRow = SwitchRow(
            title: NSLocalizedString("Media Uploads", comment: "Downloadable/Restorable items: Media Uploads"),
            value: true,
            onChange: { _ in }
        )
        let rootRow = SwitchRow(
            title: NSLocalizedString("WordPress root", comment: "Downloadable/Restorable items: WordPress root"),
            value: true,
            onChange: { _ in }
        )

        let headerText: String
        switch restoreAction {
        case .restore:
            headerText = NSLocalizedString("Choose the items to restore", comment: "Restorable items: general section title")
        case .downloadBackup:
            headerText = NSLocalizedString("Choose the items to download", comment: "Downloadable items: general section title")
        }
        return ImmuTableSection(
            headerText: headerText,
            rows: [
                themesRow,
                pluginsRow,
                mediaUploadsRow,
                rootRow
            ],
            footerText: NSLocalizedString("Includes wp-config.php and any non WordPress files", comment: "Downloadable/Restorable items: general section footer text")
        )
    }

    private func contentSection() -> ImmuTableSection {
        let contentRow = SwitchRow(
            title: NSLocalizedString("WP-content directory", comment: "Downloadable/Restorable items: WP-content directory"),
            value: true,
            onChange: { _ in }
        )

        return ImmuTableSection(
            headerText: "",
            rows: [contentRow],
            footerText: NSLocalizedString("Excludes themes, plugins, and uploads", comment: "Downloadable/Restorable items: content section footer text")
        )
    }

    private func databaseSection() -> ImmuTableSection {
        let databaseRow = SwitchRow(
            title: NSLocalizedString("Site database", comment: "Downloadable/Restorable items: Site Database"),
            value: true,
            onChange: { _ in }
        )

        return ImmuTableSection(
            headerText: "",
            rows: [databaseRow],
            footerText: nil
        )
    }
}
