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
        configureTableHeaderView()
        reloadViewModel()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.layoutHeaderView()
    }

    // MARK: - Configure

    private func configureTitle() {
        title = Strings.title(restoreAction)
    }

    private func configureNavigation() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel,
                                                           target: self,
                                                           action: #selector(cancelTapped))
    }

    private func configureTableView() {
        WPStyleGuide.configureColors(view: view, tableView: tableView)
        ImmuTable.registerRows([SwitchRow.self], tableView: tableView)
    }

    private func configureTableHeaderView() {
        let headerView = JetpackRestoreHeaderView.loadFromNib()
        headerView.configure(site: site,
                             formattableActivity: activity,
                             restoreAction: restoreAction,
                             actionButtonHandler: { [weak self] _ in
                                self?.actionButtonTapped()
                             })
        self.tableView.tableHeaderView = headerView
    }

    // MARK: - Private Helpers

    private func actionButtonTapped() {
        switch restoreAction {
        case .restore:
            let warningVC = JetpackRestoreWarningViewController()
            self.navigationController?.pushViewController(warningVC, animated: true)
        case .downloadBackup:
            let statusVC = JetpackRestoreStatusViewController()
            self.navigationController?.pushViewController(statusVC, animated: true)
        }
    }

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
            title: Strings.themesRowTitle,
            value: true,
            onChange: { _ in }
        )
        let pluginsRow = SwitchRow(
            title: Strings.pluginsRowTitle,
            value: true,
            onChange: { _ in }
        )
        let mediaUploadsRow = SwitchRow(
            title: Strings.mediaUploadsRowTitle,
            value: true,
            onChange: { _ in }
        )
        let rootRow = SwitchRow(
            title: Strings.rootRowTitle,
            value: true,
            onChange: { _ in }
        )

        return ImmuTableSection(
            headerText: Strings.generalSectionHeaderText(restoreAction),
            rows: [
                themesRow,
                pluginsRow,
                mediaUploadsRow,
                rootRow
            ],
            footerText: Strings.generalSectionFooterText
        )
    }

    private func contentSection() -> ImmuTableSection {
        let contentRow = SwitchRow(
            title: Strings.contentRowTitle,
            value: true,
            onChange: { _ in }
        )

        return ImmuTableSection(
            headerText: "",
            rows: [contentRow],
            footerText: Strings.contentSectionFooterText
        )
    }

    private func databaseSection() -> ImmuTableSection {
        let databaseRow = SwitchRow(
            title: Strings.databaseRowTitle,
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

extension JetpackRestoreViewController {

    private enum Strings {
        static func title(_ restoreAction: JetpackRestoreAction) -> String {
            switch restoreAction {
            case .restore:
                return NSLocalizedString("Restore", comment: "Title for the Jetpack Restore Site Screen")
            case .downloadBackup:
                return NSLocalizedString("Download Backup", comment: "Title for the Jetpack Download Backup Site Screen")
            }
        }

        static func generalSectionHeaderText(_ restoreAction: JetpackRestoreAction) -> String {
            switch restoreAction {
            case .restore:
                return NSLocalizedString("Choose the items to restore", comment: "Restorable items: general section title")
            case .downloadBackup:
                return NSLocalizedString("Choose the items to download", comment: "Downloadable items: general section title")
            }
        }

        static let themesRowTitle = NSLocalizedString("WordPress Themes", comment: "Downloadable/Restorable items: WordPress Themes")
        static let pluginsRowTitle = NSLocalizedString("WordPress Plugins", comment: "Downloadable/Restorable items: WordPress Plugins")
        static let mediaUploadsRowTitle = NSLocalizedString("Media Uploads", comment: "Downloadable/Restorable items: Media Uploads")
        static let rootRowTitle = NSLocalizedString("WordPress root", comment: "Downloadable/Restorable items: WordPress root")
        static let generalSectionFooterText = NSLocalizedString("Includes wp-config php and any non WordPress files", comment: "Downloadable/Restorable items: general section footer text")
        static let contentRowTitle = NSLocalizedString("WP-content directory", comment: "Downloadable/Restorable items: WP-content directory")
        static let contentSectionFooterText = NSLocalizedString("Excludes themes, plugins, and uploads", comment: "Downloadable/Restorable items: content section footer text")
        static let databaseRowTitle = NSLocalizedString("Site database", comment: "Downloadable/Restorable items: Site Database")
    }
}
