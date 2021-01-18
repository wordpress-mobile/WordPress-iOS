import Foundation
import CocoaLumberjack
import WordPressShared

struct JetpackRestoreOptionsConfiguration {
    let title: String
    let iconImage: UIImage
    let messageTitle: String
    let messageDescription: String
    let generalSectionHeaderText: String
    let buttonTitle: String
}

class BaseRestoreOptionsViewController: UITableViewController {

    // MARK: - Private Properties

    private(set) var site: JetpackSiteRef
    private(set) var activity: Activity
    private(set) var restoreTypes = JetpackRestoreTypes()
    private let configuration: JetpackRestoreOptionsConfiguration

    private lazy var handler: ImmuTableViewHandler = {
       return ImmuTableViewHandler(takeOver: self)
    }()

    private lazy var dateFormatter: DateFormatter = {
        return ActivityDateFormatting.mediumDateFormatterWithTime(for: site)
    }()

    private lazy var headerView: JetpackRestoreHeaderView = {
        return JetpackRestoreHeaderView.loadFromNib()
    }()

    // MARK: - Initialization

    init(site: JetpackSiteRef, activity: Activity) {
        fatalError("A configuration struct needs to be provided")
    }

    init(site: JetpackSiteRef,
         activity: Activity,
         configuration: JetpackRestoreOptionsConfiguration) {
        self.site = site
        self.activity = activity
        self.configuration = configuration
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

    // MARK: - Public

    func actionButtonTapped() {
        fatalError("Must override in subclass")
    }

    // MARK: - Configure

    private func configureTitle() {
        title = configuration.title
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
        let publishedDate = dateFormatter.string(from: activity.published)

        headerView.configure(
            iconImage: configuration.iconImage,
            title: configuration.messageTitle,
            description: String(format: configuration.messageDescription, publishedDate),
            buttonTitle: configuration.buttonTitle
        )

        headerView.actionButtonHandler = { [weak self] in
            self?.actionButtonTapped()
        }

        self.tableView.tableHeaderView = headerView
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
            value: restoreTypes.themes,
            onChange: toggleThemes(value:)
        )
        let pluginsRow = SwitchRow(
            title: Strings.pluginsRowTitle,
            value: restoreTypes.plugins,
            onChange: togglePlugins(value:)
        )
        let mediaUploadsRow = SwitchRow(
            title: Strings.mediaUploadsRowTitle,
            value: restoreTypes.uploads,
            onChange: toggleUploads(value:)
        )
        let rootRow = SwitchRow(
            title: Strings.rootRowTitle,
            value: restoreTypes.roots,
            onChange: toggleRoots(value:)
        )

        return ImmuTableSection(
            headerText: configuration.generalSectionHeaderText,
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
            value: restoreTypes.contents,
            onChange: toggleContents(value:)
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
            value: restoreTypes.sqls,
            onChange: toggleSqls(value:)
        )

        return ImmuTableSection(
            headerText: "",
            rows: [databaseRow],
            footerText: nil
        )
    }


    // MARK: - Private Helpers

    @objc private func cancelTapped() {
        self.dismiss(animated: true)
    }

    private func toggleThemes(value: Bool) {
        restoreTypes.themes = value
        updateHeaderView()
    }

    private func togglePlugins(value: Bool) {
        restoreTypes.plugins = value
        updateHeaderView()
    }

    private func toggleUploads(value: Bool) {
        restoreTypes.uploads = value
        updateHeaderView()
    }

    private func toggleRoots(value: Bool) {
        restoreTypes.roots = value
        updateHeaderView()
    }

    private func toggleContents(value: Bool) {
        restoreTypes.contents = value
        updateHeaderView()
    }

    private func toggleSqls(value: Bool) {
        restoreTypes.sqls = value
        updateHeaderView()
    }

    private func updateHeaderView() {
        let isItemSelectionEmpty =
            restoreTypes.themes == false &&
            restoreTypes.plugins == false &&
            restoreTypes.uploads == false &&
            restoreTypes.roots == false &&
            restoreTypes.contents == false &&
            restoreTypes.sqls == false

        headerView.toggleActionButton(isEnabled: !isItemSelectionEmpty)
    }
}

extension BaseRestoreOptionsViewController {

    private enum Strings {
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
