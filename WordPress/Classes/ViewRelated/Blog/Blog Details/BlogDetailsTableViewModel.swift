import Foundation
import UIKit
import WordPressLegacy
import WordPressShared
import WordPressSharedObjC
import WordPressUI

private struct Section {
    let title: String?
    let rows: [Row]
    let footerTitle: String?
    let category: SectionCategory

    init(
        title: String? = nil,
        rows: [Row],
        footerTitle: String? = nil,
        category: SectionCategory
    ) {
        self.title = title
        self.rows = rows
        self.footerTitle = footerTitle
        self.category = category
    }
}

@objc public final class BlogDetailsTableViewModel: NSObject {
    private var blog: Blog
    private weak var tableView: UITableView?
    private weak var viewController: BlogDetailsViewController?
    private var sections: [Section] = []

    var restorableSelectedRow: BlogDetailsRowKind? {
        didSet {
            if let row = restorableSelectedRow,
               let section = sections.first(where: { $0.rows.contains { $0.kind == row } }),
               [.jetpackBrandingCard, .domainCredit].contains(section.category) {
                restorableSelectedRow = nil
            }
        }
    }

    var restorableSelectedIndexPath: IndexPath? {
        restorableSelectedRow.flatMap(indexPath(for:))
    }

    var gravatarIcon: UIImage? {
        didSet {
            if let indexPath = self.indexPath(for: .me) {
                tableView?.reloadRows(at: [indexPath], with: .automatic)
            }
        }
    }

    var useSiteMenuStyle = false

    @objc public init(blog: Blog, viewController: BlogDetailsViewController) {
        self.blog = blog
        self.viewController = viewController
        super.init()
    }

    @objc public func configure(tableView: UITableView) {
        self.tableView = tableView

        // Register standard cells
        tableView.register(WPTableViewCell.self, forCellReuseIdentifier: CellIdentifiers.standard)
        tableView.register(WPTableViewCellValue1.self, forCellReuseIdentifier: CellIdentifiers.plan)
        tableView.register(WPTableViewCellValue1.self, forCellReuseIdentifier: CellIdentifiers.settings)
        tableView.register(WPTableViewCell.self, forCellReuseIdentifier: CellIdentifiers.removeSite)

        // Register header/footer views
        tableView.register(BlogDetailsSectionFooterView.self, forHeaderFooterViewReuseIdentifier: CellIdentifiers.sectionFooter)

        // Register special card cells
        tableView.register(MigrationSuccessCell.self, forCellReuseIdentifier: CellIdentifiers.migrationSuccess)
        tableView.register(JetpackBrandingMenuCardCell.self, forCellReuseIdentifier: CellIdentifiers.jetpackBrandingCard)
        tableView.register(JetpackRemoteInstallTableViewCell.self, forCellReuseIdentifier: CellIdentifiers.jetpackInstall)
        tableView.register(SotWTableViewCell.self, forCellReuseIdentifier: CellIdentifiers.sotWCard)

        tableView.delegate = self
        tableView.dataSource = self
    }

    @objc public func viewWillAppear() {
        if !isSplitViewDisplayed {
            restorableSelectedRow = nil
        }
    }

    @objc public func configureTableViewData() {
        guard let viewController else { return }

        var newSections: [Section] = []

        if viewController.shouldShowSotW2023Card() {
            newSections.append(Section(rows: [], category: .sotW2023Card))
        }

        if viewController.shouldShowJetpackInstallCard() {
            newSections.append(Section(rows: [], category: .jetpackInstallCard))
        }

        if viewController.shouldShowTopJetpackBrandingMenuCard {
            newSections.append(Section(rows: [], category: .jetpackBrandingCard))
        }

        if viewController.isDashboardEnabled() && isSplitViewDisplayed {
            newSections.append(buildHomeSection())
        }

        if AppConfiguration.isWordPress {
            if viewController.shouldAddJetpackSection() {
                newSections.append(buildJetpackSection())
            }

            if viewController.shouldAddGeneralSection() {
                newSections.append(buildGeneralSection())
            }

            newSections.append(buildPublishTypeSection())

            if viewController.shouldAddPersonalizeSection() {
                newSections.append(buildPersonalizeSection())
            }

            newSections.append(buildConfigurationSection())
            newSections.append(buildExternalSection())
        } else {
            newSections.append(buildContentSection())

            if let trafficSection = buildTrafficSection() {
                newSections.append(trafficSection)
            }

            newSections.append(contentsOf: buildMaintenanceSections())
        }

        if blog.supports(.removable) {
            newSections.append(buildRemoveSiteSection())
        }

        if viewController.shouldShowBottomJetpackBrandingMenuCard {
            newSections.append(Section(rows: [], category: .jetpackBrandingCard))
        }

        sections = newSections
    }

    private var isSplitViewDisplayed: Bool {
        viewController?.isSidebarModeEnabled ?? false
    }

    func defaultSubsection() -> BlogDetailsRowKind {
        if !JetpackFeaturesRemovalCoordinator.jetpackFeaturesEnabled() {
            return .posts
        }
        if let viewController, viewController.isDashboardEnabled() {
            return .home
        }
        return .stats
    }

    func optimumScrollPosition(for indexPath: IndexPath) -> UITableView.ScrollPosition {
        guard let tableView, !isSplitViewDisplayed else { return .none }

        let cellRect = tableView.rectForRow(at: indexPath)
        return CGRectContainsRect(tableView.bounds, cellRect) ? .none : .middle
    }

    @objc public func reloadTableViewPreservingSelection() {
        guard let tableView else { return }

        let previousSelection = tableView.indexPathForSelectedRow
        tableView.reloadData()

        if isSplitViewDisplayed, let indexPath = restorableSelectedIndexPath {
            tableView.selectRow(at: indexPath, animated: false, scrollPosition: optimumScrollPosition(for: indexPath))

            if previousSelection != indexPath {
                sections[indexPath.section].rows[indexPath.row].action?([:])
            }
        }
    }

    @objc public func showInitialDetailsForBlog() {
        guard isSplitViewDisplayed else { return }

        let row = defaultSubsection()
        self.restorableSelectedRow = row

        self.showDetailView(for: row)
    }

    @objc func numberOfSections() -> Int {
        sections.count
    }

    func showDetailViewForMe(userInfo: [String: Any]) -> MeViewController {
        guard let viewController else {
            wpAssertionFailure("The view controller should not be nil")
            return MeViewController()
        }
        restorableSelectedRow = .me
        return viewController.showMe()
    }

    func showDetailView(for row: BlogDetailsRowKind, userInfo: [String: Any] = [:]) {
        for (sectionIndex, section) in sections.enumerated() {
            for (rowIndex, rowItem) in section.rows.enumerated() where rowItem.kind == row {
                let indexPath = IndexPath(row: rowIndex, section: sectionIndex)

                if rowItem.showsSelectionState {
                    restorableSelectedRow = row

                    tableView?.selectRow(at: indexPath, animated: false, scrollPosition: optimumScrollPosition(for: indexPath))
                }

                // Call the row's action
                rowItem.action?(userInfo)
                return
            }
        }
    }

    func indexPath(for row: BlogDetailsRowKind) -> IndexPath? {
        for (sectionIndex, section) in sections.enumerated() {
            for (rowIndex, rowItem) in section.rows.enumerated() where rowItem.kind == row {
                return IndexPath(row: rowIndex, section: sectionIndex)
            }
        }
        return nil
    }
}

extension BlogDetailsTableViewModel: UITableViewDataSource {
    public func numberOfSections(in tableView: UITableView) -> Int {
        sections.count
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard section < sections.count else { return 0 }

        switch sections[section].category {
        case .sotW2023Card, .jetpackInstallCard, .migrationSuccess, .jetpackBrandingCard:
            // The "card" sections do not set the `rows` property. It's hard-coded to show specific types of cards.
            wpAssert(sections[section].rows.count == 0)
            return 1
        default:
            return sections[section].rows.count
        }
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard indexPath.section < sections.count else {
            return UITableViewCell()
        }

        let section = sections[indexPath.section]
        let cell: UITableViewCell

        switch section.category {
        case .sotW2023Card:
            cell = configureSotWCell(tableView: tableView)
        case .jetpackInstallCard:
            cell = configureJetpackInstallCell(tableView: tableView)
        case .migrationSuccess:
            cell = configureMigrationSuccessCell(tableView: tableView)
        case .jetpackBrandingCard:
            cell = configureJetpackBrandingCell(tableView: tableView)
        default:
            if indexPath.row < section.rows.count {
                let row = section.rows[indexPath.row]
                cell = configureStandardCell(tableView: tableView, indexPath: indexPath, row: row)
            } else {
                cell = UITableViewCell()
            }
        }

        if useSiteMenuStyle {
            configureForDisplayingOnSiteMenu(cell)
        }

        return cell
    }

    public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard section < sections.count else { return nil }
        return sections[section].title
    }

    private func configureForDisplayingOnSiteMenu(_ cell: UITableViewCell) {
        cell.textLabel?.font = .preferredFont(forTextStyle: .body)
        cell.backgroundColor = .clear
        cell.selectedBackgroundView = {
            let backgroundView = UIView()
            backgroundView.backgroundColor = .secondarySystemFill
            backgroundView.layer.cornerRadius = DesignConstants.radius(.large)
            backgroundView.layer.cornerCurve = .continuous

            let container = UIView()
            container.addSubview(backgroundView)
            backgroundView.pinEdges(insets: UIEdgeInsets(.horizontal, 16))
            return container
        }()
        cell.focusStyle = .custom
        cell.focusEffect = nil
    }
}

extension BlogDetailsTableViewModel: UITableViewDelegate {
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.section < sections.count else { return }
        let section = sections[indexPath.section]

        guard indexPath.row < section.rows.count else { return }
        let row = section.rows[indexPath.row]

        row.action?([:])

        if row.showsSelectionState {
            restorableSelectedRow = row.kind
        } else {
            if !isSplitViewDisplayed {
                tableView.deselectRow(at: indexPath, animated: true)
            } else if let indexPath = restorableSelectedIndexPath {
                tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
            }
        }
    }

    public func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        let isNewSelection = (indexPath != tableView.indexPathForSelectedRow)
        return isNewSelection ? indexPath : nil
    }

    public func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        guard section < sections.count else { return 0 }
        let detailSection = sections[section]
        let isLastSection = section == sections.count - 1
        let hasTitle = !(detailSection.footerTitle?.isEmpty ?? true)

        if hasTitle {
            return UITableView.automaticDimension
        }
        if isLastSection {
            return 40.0
        }
        return 0
    }

    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard section < sections.count else { return 0 }
        let detailSection = sections[section]
        let hasTitle = !(detailSection.title?.isEmpty ?? true)

        if useSiteMenuStyle {
            return hasTitle ? 48 : 0
        }

        return hasTitle ? 40.0 : 20.0
    }

    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard useSiteMenuStyle else { return nil }

        guard let title = self.tableView(tableView, titleForHeaderInSection: section) else { return nil }

        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .headline)
        label.text = title

        let headerView = UIView()
        headerView.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 20),
            label.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -8),
            label.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: 20)
        ])
        return headerView
    }

    public func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard section < sections.count,
              let footerTitle = sections[section].footerTitle,
              !footerTitle.isEmpty else {
            return nil
        }

        guard let footerView = tableView.dequeueReusableHeaderFooterView(
            withIdentifier: CellIdentifiers.sectionFooterIdentifier
        ) as? BlogDetailsSectionFooterView else {
            return nil
        }

        let shouldShowExtraSpacing = (section + 1 < sections.count) && (sections[section + 1].title != nil)
        footerView.updateUI(title: footerTitle, shouldShowExtraSpacing: shouldShowExtraSpacing)
        return footerView
    }
}

private extension BlogDetailsTableViewModel {
    func configureStandardCell(
        tableView: UITableView,
        indexPath: IndexPath,
        row: Row
    ) -> UITableViewCell {
        let identifier = switch row.kind {
        case .removeSite:
            CellIdentifiers.removeSite
        case .jetpackSettings, .siteSettings, .domain:
            CellIdentifiers.settings
        default:
            CellIdentifiers.standard
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath)

        cell.accessibilityHint = row.accessibilityHint
        cell.accessoryView = nil
        cell.textLabel?.textAlignment = .natural

        if row.kind == .removeSite {
            cell.accessoryType = .none
            WPStyleGuide.configureTableViewDestructiveActionCell(cell)
        } else {
            if row.showsDisclosureIndicator {
                cell.accessoryType = isSplitViewDisplayed ? .none : .disclosureIndicator
            } else {
                cell.accessoryType = .none
            }
            WPStyleGuide.configureTableViewCell(cell)
        }

        cell.textLabel?.text = row.title
        cell.accessibilityIdentifier = row.accessibilityIdentifier ?? identifier
        cell.detailTextLabel?.text = row.detail
        cell.imageView?.image = row.image
        cell.imageView?.tintColor = row.imageColor

        if let accessoryView = row.accessoryView {
            cell.accessoryView = accessoryView
        }

        return cell
    }

    func configureSotWCell(tableView: UITableView) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: CellIdentifiers.sotWCard
        ) as? SotWTableViewCell else {
            return UITableViewCell()
        }

        cell.configure { [weak viewController] in
            viewController?.configureTableViewData()
            viewController?.reloadTableViewPreservingSelection()
        }

        return cell
    }

    func configureJetpackInstallCell(tableView: UITableView) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: CellIdentifiers.jetpackInstall
        ) as? JetpackRemoteInstallTableViewCell,
              let viewController else {
            return UITableViewCell()
        }

        cell.configure(blog: blog, viewController: viewController)
        return cell
    }

    func configureMigrationSuccessCell(tableView: UITableView) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: CellIdentifiers.migrationSuccess
        ) as? MigrationSuccessCell,
              let viewController else {
            return UITableViewCell()
        }

        if viewController.isSidebarModeEnabled {
            cell.configureForSidebarMode()
        }
        cell.configure(with: viewController)
        return cell
    }

    func configureJetpackBrandingCell(tableView: UITableView) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: CellIdentifiers.jetpackBrandingCard
        ) as? JetpackBrandingMenuCardCell,
              let viewController else {
            return UITableViewCell()
        }

        cell.configure(with: viewController)
        return cell
    }
}

private extension BlogDetailsTableViewModel {
    func buildHomeSection() -> Section {
        return Section(rows: [Row.home(viewController: viewController)], category: .home)
    }

    func buildContentSection() -> Section {
        var rows: [Row] = []

        rows.append(Row.posts(viewController: viewController))

        if blog.supports(.pages) {
            rows.append(Row.pages(viewController: viewController))
        }

        rows.append(Row.media(viewController: viewController))
        rows.append(Row.comments(viewController: viewController))

        let title = isSplitViewDisplayed ? nil : Strings.contentSectionTitle
        return Section(title: title, rows: rows, category: .content)
    }

    func buildRemoveSiteSection() -> Section {
        return Section(rows: [Row.removeSite(viewController: viewController)], category: .removeSite)
    }

    func buildJetpackSection() -> Section {
        var rows: [Row] = []

        if blog.isViewingStatsAllowed() {
            rows.append(Row.stats(viewController: viewController))
        }

        if blog.supports(.activity) && !blog.isWPForTeams() {
            rows.append(Row.activityLog(viewController: viewController))
        }

        if blog.isBackupsAllowed() {
            rows.append(Row.backup(viewController: viewController))
        }

        if blog.isScanAllowed() {
            rows.append(Row.scan(viewController: viewController))
        }

        if blog.supports(.jetpackSettings) {
            rows.append(Row.jetpackSettings(viewController: viewController))
        }

        if viewController?.shouldShowBlaze() == true {
            rows.append(Row.blaze(viewController: viewController))
        }

        let title = if blog.supports(.jetpackSettings) {
            Strings.jetpackSection
        } else {
            ""
        }

        return Section(title: title, rows: rows, category: .jetpack)
    }

    func buildGeneralSection() -> Section {
        var rows: [Row] = []

        if blog.isViewingStatsAllowed() {
            rows.append(Row.stats(viewController: viewController))
        }

        if blog.supports(.activity) && !blog.isWPForTeams() {
            rows.append(Row.activity(viewController: viewController))
        }

        if viewController?.shouldShowBlaze() == true {
            rows.append(Row.blaze(viewController: viewController))
        }

        return Section(rows: rows, category: .general)
    }

    func buildPublishTypeSection() -> Section {
        var rows: [Row] = []

        rows.append(Row.posts(viewController: viewController))
        rows.append(Row.media(viewController: viewController))

        if blog.supports(.pages) {
            rows.append(Row.pages(viewController: viewController))
        }

        rows.append(Row.comments(viewController: viewController))

        let title = Strings.publishSection
        return Section(title: title, rows: rows, category: .content)
    }

    func buildPersonalizeSection() -> Section {
        var rows: [Row] = []

        if blog.supports(.themeBrowsing) && !blog.isWPForTeams() {
            rows.append(Row.themes(viewController: viewController))
        }

        if blog.supports(.menus) {
            rows.append(Row.menus(viewController: viewController))
        }

        let title = Strings.personalizeSection
        return Section(title: title, rows: rows, category: .personalize)
    }

    func buildConfigurationSection() -> Section {
        guard let viewController else {
            return Section(title: "Configure", rows: [], category: .configure)
        }

        var rows: [Row] = []

        // Me row
        if viewController.shouldAddMeRow() {
            rows.append(Row.me(icon: gravatarIcon, viewController: viewController))
            // Note: Gravatar image download would be handled by viewController
        }

        // Sharing row
        if viewController.shouldAddSharingRow() {
            rows.append(Row.sharing(viewController: viewController))
        }

        // People row
        if viewController.shouldAddPeopleRow() {
            rows.append(Row.people(viewController: viewController))
        }

        // Users row
        if viewController.shouldAddUsersRow() {
            rows.append(Row.users(viewController: viewController))
        }

        // Plugins row
        if viewController.shouldAddPluginsRow() {
            rows.append(Row.plugins(viewController: viewController))
        }

        // Site Settings row (always included)
        rows.append(Row.siteSettings(viewController: viewController))

        // Domains row
        if viewController.shouldAddDomainRegistrationRow() {
            rows.append(Row.domains(viewController: viewController))
        }

        let title = Strings.configureSection
        return Section(title: title, rows: rows, category: .configure)
    }

    func buildExternalSection() -> Section {
        guard let viewController else {
            return Section(title: Strings.externalSection, rows: [], category: .external)
        }

        var rows: [Row] = []

        rows.append(Row.viewSite(viewController: viewController))

        if shouldDisplayLinkToWPAdmin(for: blog) {
            rows.append(Row.admin(viewController: viewController, blog: blog))
        }

        let title = Strings.externalSection
        return Section(title: title, rows: rows, category: .external)
    }

    func buildTrafficSection() -> Section? {
        guard let viewController else { return nil }

        var rows: [Row] = []

        if blog.isViewingStatsAllowed() {
            rows.append(Row.stats(viewController: viewController))
        }

        if viewController.shouldShowSubscribersRow {
            rows.append(Row.subscribers(viewController: viewController))
        }

        if viewController.shouldAddSharingRow() {
            rows.append(Row.social(viewController: viewController))
        }

        if viewController.shouldShowBlaze() {
            rows.append(Row.blaze(viewController: viewController))
        }

        if rows.isEmpty {
            return nil
        }

        let title = Strings.trafficSectionTitle
        return Section(title: title, rows: rows, category: .traffic)
    }

    func buildMaintenanceSections() -> [Section] {
        guard let viewController else { return [] }

        var sections: [Section] = []
        var firstSectionRows: [Row] = []
        var secondSectionRows: [Row] = []
        var thirdSectionRows: [Row] = []

        // First section: Activity, Backup, Scan, Site Monitoring
        if blog.supports(.activity) && !blog.isWPForTeams() {
            firstSectionRows.append(Row.activityLog(viewController: viewController))
        }

        if blog.isBackupsAllowed() {
            firstSectionRows.append(Row.backup(viewController: viewController))
        }

        if blog.isScanAllowed() {
            firstSectionRows.append(Row.scan(viewController: viewController))
        }

        if RemoteFeatureFlag.siteMonitoring.enabled() && blog.supports(.siteMonitoring) {
            firstSectionRows.append(Row.siteMonitoring(viewController: viewController))
        }

        // Second section: People, Users, Plugins, Themes, Menus, Domains, Application Passwords, Site Settings
        if viewController.shouldAddPeopleRow() {
            secondSectionRows.append(Row.people(viewController: viewController))
        }

        if viewController.shouldAddUsersRow() {
            secondSectionRows.append(Row.users(viewController: viewController))
        }

        if viewController.shouldAddPluginsRow() {
            secondSectionRows.append(Row.plugins(viewController: viewController))
        }

        if blog.supports(.themeBrowsing) && !blog.isWPForTeams() {
            secondSectionRows.append(Row.themes(viewController: viewController))
        }

        if blog.supports(.menus) {
            secondSectionRows.append(Row.menus(viewController: viewController))
        }

        if viewController.shouldAddDomainRegistrationRow() {
            secondSectionRows.append(Row.domains(viewController: viewController))
        }

        if FeatureFlag.allowApplicationPasswords.enabled {
            secondSectionRows.append(Row.applicationPasswords(viewController: viewController))
        }

        // Site Settings (always included)
        secondSectionRows.append(Row.siteSettings(viewController: viewController))

        // Third section: WP Admin
        if shouldDisplayLinkToWPAdmin(for: blog) {
            thirdSectionRows.append(Row.admin(viewController: viewController, blog: blog))
        }

        // Build sections with proper titles
        let sectionTitle = Strings.maintenanceSectionTitle
        var shouldAddSectionTitle = true

        if !firstSectionRows.isEmpty {
            sections.append(Section(
                title: sectionTitle,
                rows: firstSectionRows,
                category: .maintenance
            ))
            shouldAddSectionTitle = false
        }

        if !secondSectionRows.isEmpty {
            sections.append(Section(
                title: shouldAddSectionTitle ? sectionTitle : nil,
                rows: secondSectionRows,
                category: .maintenance
            ))
            shouldAddSectionTitle = false
        }

        if !thirdSectionRows.isEmpty {
            sections.append(Section(
                title: shouldAddSectionTitle ? sectionTitle : nil,
                rows: thirdSectionRows,
                category: .maintenance
            ))
        }

        return sections
    }

    // MARK: - Helper Methods

    private func shouldDisplayLinkToWPAdmin(for blog: Blog) -> Bool {
        if !blog.isHostedAtWPcom {
            return true
        }
        // For .com users, check if account was created before HideWPAdminDate
        let hideWPAdminDateString = "2015-09-07T00:00:00Z"
        guard let hideWPAdminDate = ISO8601DateFormatter().date(from: hideWPAdminDateString) else {
            return false
        }
        let context = ContextManager.shared.mainContext
        guard let defaultAccount = try? WPAccount.lookupDefaultWordPressComAccount(in: context),
              let dateCreated = defaultAccount.dateCreated else {
            return false
        }
        return dateCreated < hideWPAdminDate
    }
}

enum BlogDetailsUserInfoKeys {
    static let source = "source"
    static let showPicker = "show-picker"
    static let showManagePlugins = "show-manage-plugins"
    static let siteMonitoringTab = "site-monitoring-tab"
}

// MARK: - Table view content

private enum SectionCategory {
    case reminders
    case domainCredit
    case home
    case general
    case jetpack
    case personalize
    case configure
    case external
    case removeSite
    case migrationSuccess
    case jetpackBrandingCard
    case jetpackInstallCard
    case sotW2023Card
    case content
    case traffic
    case maintenance
}

enum BlogDetailsRowKind {
    case reminders
    case domain
    case stats
    case posts
    case customize
    case themes
    case media
    case pages
    case activity
    case backup
    case scan
    case jetpackSettings
    case me
    case comments
    case sharing
    case people
    case subscribers
    case plugins
    case home
    case migrationSuccess
    case jetpackBrandingCard
    case blaze
    case menu
    case applicationPasswords
    case siteMonitoring
    case viewSite
    case admin
    case siteSettings
    case removeSite
}

private struct Row {
    let kind: BlogDetailsRowKind
    let title: String
    let accessibilityIdentifier: String?
    let accessibilityHint: String?
    let image: UIImage?
    let imageColor: UIColor?
    let accessoryView: UIView?
    let detail: String?
    let showsSelectionState: Bool
    let showsDisclosureIndicator: Bool
    let action: (([String: Any]) -> Void)?

    init(
        kind: BlogDetailsRowKind,
        title: String,
        accessibilityIdentifier: String? = nil,
        accessibilityHint: String? = nil,
        image: UIImage?,
        imageColor: UIColor? = .label,
        accessoryView: UIView? = nil,
        detail: String? = nil,
        showsSelectionState: Bool = true,
        showsDisclosureIndicator: Bool = true,
        action: (([String: Any]) -> Void)? = nil,
    ) {
        self.title = title
        self.accessibilityIdentifier = accessibilityIdentifier
        self.accessibilityHint = accessibilityHint
        self.image = imageColor == nil ? image : image?.withRenderingMode(.alwaysTemplate)
        self.imageColor = imageColor
        self.accessoryView = accessoryView
        self.detail = detail
        self.showsSelectionState = showsSelectionState
        self.showsDisclosureIndicator = showsDisclosureIndicator
        self.action = action
        self.kind = kind
    }
}

extension Row {
    static func home(viewController: BlogDetailsViewController?) -> Row {
        Row(
            kind: .home,
            title: Strings.home,
            accessibilityIdentifier: "Home Row",
            image: UIImage(named: "site-menu-home"),
            action: { [weak viewController] _ in
                viewController?.showDashboard()
            }
        )
    }

    static func posts(viewController: BlogDetailsViewController?) -> Row {
        Row(
            kind: .posts,
            title: Strings.posts,
            accessibilityIdentifier: "Blog Post Row",
            image: (UIImage(named: "site-menu-posts"))?.imageFlippedForRightToLeftLayoutDirection(),
            action: { [weak viewController] userInfo in
                // When called from showDetailView, use .link as source (matching Objective-C behavior)
                // When called from direct tap, use .row (default behavior)
                let source: BlogDetailsNavigationSource = userInfo.isEmpty ? .row : .link
                viewController?.showPostList(from: source)
            }
        )
    }

    static func pages(viewController: BlogDetailsViewController?) -> Row {
        Row(
            kind: .pages,
            title: Strings.pages,
            accessibilityIdentifier: "Site Pages Row",
            image: UIImage(named: "site-menu-pages"),
            action: { [weak viewController] userInfo in
                // When called from showDetailView, use .link as source (matching Objective-C behavior)
                // When called from direct tap, use .row (default behavior)
                let source: BlogDetailsNavigationSource = userInfo.isEmpty ? .row : .link
                viewController?.showPageList(from: source)
            }
        )
    }

    static func media(viewController: BlogDetailsViewController?) -> Row {
        Row(
            kind: .media,
            title: Strings.media,
            accessibilityIdentifier: "Media Row",
            image: UIImage(named: "site-menu-media"),
            action: { [weak viewController] userInfo in
                let showPicker = (userInfo[BlogDetailsUserInfoKeys.showPicker] as? NSNumber)?.boolValue ?? false
                viewController?.showMediaLibrary(from: .link, showPicker: showPicker)
            }
        )
    }

    static func comments(viewController: BlogDetailsViewController?) -> Row {
        Row(
            kind: .comments,
            title: Strings.comments,
            image: (UIImage(named: "site-menu-comments"))?.imageFlippedForRightToLeftLayoutDirection(),
            action: { [weak viewController] userInfo in
                // When called from showDetailView, use .link as source (matching Objective-C behavior)
                // When called from direct tap, use .row (default behavior)
                let source: BlogDetailsNavigationSource = userInfo.isEmpty ? .row : .link
                viewController?.showComments(from: source)
            }
        )
    }

    static func removeSite(viewController: BlogDetailsViewController?) -> Row {
        Row(
            kind: .removeSite,
            title: Strings.removeSite,
            image: nil,
            showsSelectionState: false,
            action: { [weak viewController] _ in
                viewController?.tableView?.deselectSelectedRowWithAnimation(true)
                viewController?.showRemoveSiteAlert()
            }
        )
    }

    static func stats(viewController: BlogDetailsViewController?) -> Row {
        Row(
            kind: .stats,
            title: Strings.stats,
            accessibilityIdentifier: "Stats Row",
            image: UIImage(named: "site-menu-stats"),
            action: { [weak viewController] userInfo in
                let sourceValue = userInfo[BlogDetailsUserInfoKeys.source] as? NSNumber
                let source = sourceValue.map { BlogDetailsNavigationSource(rawValue: $0.intValue) ?? .link } ?? .link
                viewController?.showStats(from: source)
            }
        )
    }

    static func activityLog(viewController: BlogDetailsViewController?) -> Row {
        Row(
            kind: .activity,
            title: Strings.activityLog,
            accessibilityIdentifier: "Activity Log Row",
            image: UIImage(named: "site-menu-activity"),
            action: { [weak viewController] _ in
                viewController?.showActivity()
            }
        )
    }

    static func activity(viewController: BlogDetailsViewController?) -> Row {
        Row(
            kind: .activity,
            title: Strings.activity,
            image: UIImage(named: "site-menu-activity"),
            action: { [weak viewController] _ in
                viewController?.showActivity()
            }
        )
    }

    static func backup(viewController: BlogDetailsViewController?) -> Row {
        Row(
            kind: .backup,
            title: Strings.backup,
            accessibilityIdentifier: "Backup Row",
            image: UIImage.gridicon(.cloudOutline),
            action: { [weak viewController] _ in
                viewController?.showBackup()
            }
        )
    }

    static func scan(viewController: BlogDetailsViewController?) -> Row {
        Row(
            kind: .scan,
            title: Strings.scan,
            accessibilityIdentifier: "Scan Row",
            image: UIImage(named: "jetpack-scan-menu-icon"),
            action: { [weak viewController] _ in
                viewController?.showScan()
            }
        )
    }

    static func jetpackSettings(viewController: BlogDetailsViewController?) -> Row {
        Row(
            kind: .jetpackSettings,
            title: Strings.jetpackSettings,
            accessibilityIdentifier: "Jetpack Settings Row",
            image: UIImage(named: "site-menu-settings"),
            action: { [weak viewController] _ in
                viewController?.showJetpackSettings()
            }
        )
    }

    static func blaze(viewController: BlogDetailsViewController?) -> Row {
        let iconSize = CGSize(width: 24.0, height: 24.0)
        let blazeIcon = UIImage(named: "icon-blaze")?.resized(to: iconSize, format: .scaleAspectFit)
        return Row(
            kind: .blaze,
            title: Strings.blaze,
            accessibilityIdentifier: "Blaze Row",
            image: blazeIcon?.imageFlippedForRightToLeftLayoutDirection(),
            imageColor: nil,
            showsSelectionState: RemoteFeatureFlag.blazeManageCampaigns.enabled(),
            action: { [weak viewController] _ in
                viewController?.showBlaze()
            }
        )
    }

    static func themes(viewController: BlogDetailsViewController?) -> Row {
        Row(
            kind: .themes,
            title: Strings.themes,
            image: UIImage(named: "site-menu-themes"),
            action: { [weak viewController] _ in
                viewController?.showThemes()
            }
        )
    }

    static func menus(viewController: BlogDetailsViewController?) -> Row {
        Row(
            kind: .menu,
            title: Strings.menus,
            image: UIImage.gridicon(.menus).imageFlippedForRightToLeftLayoutDirection(),
            action: { [weak viewController] _ in
                viewController?.showMenus()
            }
        )
    }

    static func me(icon: UIImage?, viewController: BlogDetailsViewController?) -> Row {
        Row(
            kind: .me,
            title: Strings.me,
            image: icon ?? UIImage.gridicon(.userCircle),
            action: { [weak viewController] _ in
                viewController?.showMe()
            }
        )
    }

    static func sharing(viewController: BlogDetailsViewController?) -> Row {
        let sharingTitle = AppConfiguration.isWordPress
            ? Strings.sharing
            : Strings.socialRowTitle
        return Row(
            kind: .sharing,
            title: sharingTitle,
            image: UIImage(named: "site-menu-social"),
            action: { [weak viewController] userInfo in
                // When called from showDetailView, use .link as source (matching Objective-C behavior)
                // When called from direct tap, use .row (default behavior)
                let source: BlogDetailsNavigationSource = userInfo.isEmpty ? .row : .link
                viewController?.showSharing(from: source)
            }
        )
    }

    static func people(viewController: BlogDetailsViewController?) -> Row {
        let title = viewController?.shouldShowSubscribersRow == true
            ? Strings.users
            : Strings.people
        return Row(
            kind: .people,
            title: title,
            accessibilityIdentifier: "Users Row",
            image: UIImage(named: "site-menu-people"),
            action: { [weak viewController] _ in
                viewController?.showPeople()
            }
        )
    }

    static func subscribers(viewController: BlogDetailsViewController?) -> Row {
        Row(
            kind: .subscribers,
            title: Strings.subscribers,
            image: UIImage(named: "wpl-mail"),
            action: { [weak viewController] _ in
                MainActor.assumeIsolated {
                    guard let viewController else { return }
                    guard let blog = SubscribersBlog(blog: viewController.blog) else {
                        return wpAssertionFailure("incompatible blog")
                    }
                    let vc = SubscribersViewController(blog: blog)
                    viewController.presentationDelegate?.presentBlogDetailsViewController(vc)
                }
            }
        )
    }

    static func users(viewController: BlogDetailsViewController?) -> Row {
        Row(
            kind: .people,
            title: Strings.users,
            accessibilityIdentifier: "Users Row",
            image: UIImage(named: "site-menu-people"),
            action: { [weak viewController] _ in
                viewController?.showUsers()
            }
        )
    }

    static func plugins(viewController: BlogDetailsViewController?) -> Row {
        Row(
            kind: .plugins,
            title: Strings.plugins,
            image: UIImage(named: "site-menu-plugins"),
            action: { [weak viewController] userInfo in
                let showManagement = (userInfo[BlogDetailsUserInfoKeys.showManagePlugins] as? NSNumber)?.boolValue ?? false
                if showManagement {
                    viewController?.showManagePluginsScreen()
                } else {
                    viewController?.showPlugins()
                }
            }
        )
    }

    static func siteSettings(viewController: BlogDetailsViewController?) -> Row {
        Row(
            kind: .siteSettings,
            title: Strings.siteSettings,
            accessibilityIdentifier: "Settings Row",
            image: UIImage(named: "site-menu-settings"),
            action: { [weak viewController] _ in
                viewController?.showSettings(from: .row)
            }
        )
    }

    static func domains(viewController: BlogDetailsViewController?) -> Row {
        Row(
            kind: .domain,
            title: Strings.domains,
            accessibilityIdentifier: "Domains Row",
            image: UIImage(named: "site-menu-domains"),
            action: { [weak viewController] _ in
                viewController?.showDomains(from: .row)
            }
        )
    }

    static func viewSite(viewController: BlogDetailsViewController?) -> Row {
        Row(
            kind: .viewSite,
            title: Strings.viewSite,
            image: UIImage.gridicon(.globe),
            showsSelectionState: false,
            action: { [weak viewController] _ in
                viewController?.showViewSite(from: .row)
            }
        )
    }

    static func admin(viewController: BlogDetailsViewController?, blog: Blog) -> Row {
        let adminTitle = blog.isHostedAtWPcom ? Strings.dashboard : Strings.wpAdmin

        let iconSize = CGSize(width: 17.0, height: 17.0)
        let accessoryImage = UIImage.gridicon(.external, size: iconSize).imageFlippedForRightToLeftLayoutDirection()
        let accessoryView = UIImageView(image: accessoryImage)
        accessoryView.tintColor = WPStyleGuide.cellGridiconAccessoryColor()

        return Row(
            kind: .admin,
            title: adminTitle,
            image: UIImage.gridicon(.mySites),
            accessoryView: accessoryView,
            showsSelectionState: false,
            action: { [weak viewController] _ in
                viewController?.showViewAdmin()
                viewController?.tableView?.deselectSelectedRowWithAnimation(true)
            }
        )
    }

    static func social(viewController: BlogDetailsViewController?) -> Row {
        Row(
            kind: .sharing,
            title: Strings.socialRowTitle,
            image: UIImage(named: "site-menu-social"),
            action: { [weak viewController] userInfo in
                // When called from showDetailView, use .link as source (matching Objective-C behavior)
                // When called from direct tap, use .row (default behavior)
                let source: BlogDetailsNavigationSource = userInfo.isEmpty ? .row : .link
                viewController?.showSharing(from: source)
            }
        )
    }

    static func siteMonitoring(viewController: BlogDetailsViewController?) -> Row {
        Row(
            kind: .siteMonitoring,
            title: Strings.siteMonitoringRowTitle,
            accessibilityIdentifier: "Site Monitoring Row",
            image: UIImage(named: "tool"),
            action: { [weak viewController] userInfo in
                let selectedTab = userInfo[BlogDetailsUserInfoKeys.siteMonitoringTab] as? NSNumber
                viewController?.showSiteMonitoring(selectedTab: selectedTab)
            }
        )
    }

    static func applicationPasswords(viewController: BlogDetailsViewController?) -> Row {
        Row(
            kind: .applicationPasswords,
            title: Strings.applicationPasswords,
            accessibilityIdentifier: "Application Passwords Row",
            image: UIImage(systemName: "key"),
            action: { [weak viewController] _ in
                viewController?.showApplicationPasswords()
            }
        )
    }
}

private enum Strings {
    static let home = NSLocalizedString(
        "mySite.menu.home",
        value: "Home",
        comment: "Noun. Links to a blog's dashboard screen."
    )
    static let posts = NSLocalizedString(
        "mySite.menu.posts",
        value: "Posts",
        comment: "Noun. Title. Links to the blog's Posts screen."
    )
    static let pages = NSLocalizedString(
        "mySite.menu.pages",
        value: "Pages",
        comment: "Noun. Title. Links to the blog's Pages screen."
    )
    static let media = NSLocalizedString(
        "mySite.menu.media",
        value: "Media",
        comment: "Noun. Title. Links to the blog's Media library."
    )
    static let comments = NSLocalizedString(
        "mySite.menu.comments",
        value: "Comments",
        comment: "Noun. Title. Links to the blog's Comments screen."
    )
    static let removeSite = NSLocalizedString(
        "mySite.menu.removeSite",
        value: "Remove Site",
        comment: "Button to remove a site from the app"
    )
    static let stats = NSLocalizedString(
        "mySite.menu.stats",
        value: "Stats",
        comment: "Noun. Abbv. of Statistics. Links to a blog's Stats screen."
    )
    static let activityLog = NSLocalizedString(
        "mySite.menu.activityLog",
        value: "Activity Log",
        comment: "Noun. Links to a blog's Activity screen."
    )
    static let activity = NSLocalizedString(
        "mySite.menu.activity",
        value: "Activity",
        comment: "Noun. Links to a blog's Activity screen."
    )
    static let backup = NSLocalizedString(
        "mySite.menu.backup",
        value: "Backup",
        comment: "Noun. Links to a blog's Jetpack Backups screen."
    )
    static let scan = NSLocalizedString(
        "mySite.menu.scan",
        value: "Scan",
        comment: "Noun. Links to a blog's Jetpack Scan screen."
    )
    static let jetpackSettings = NSLocalizedString(
        "mySite.menu.jetpackSettings",
        value: "Jetpack Settings",
        comment: "Noun. Title. Links to the blog's Settings screen."
    )
    static let blaze = NSLocalizedString(
        "mySite.menu.blaze",
        value: "Blaze",
        comment: "Noun. Links to a blog's Blaze screen."
    )
    static let themes = NSLocalizedString(
        "mySite.menu.themes",
        value: "Themes",
        comment: "Themes option in the blog details"
    )
    static let menus = NSLocalizedString(
        "mySite.menu.menus",
        value: "Menus",
        comment: "Menus option in the blog details"
    )
    static let me = NSLocalizedString(
        "mySite.menu.me",
        value: "Me",
        comment: "Noun. Title. Links to the Me screen."
    )
    static let sharing = NSLocalizedString(
        "mySite.menu.sharing",
        value: "Sharing",
        comment: "Noun. Title. Links to a blog's sharing options."
    )
    static let people = NSLocalizedString(
        "mySite.menu.people",
        value: "People",
        comment: "Noun. Title. Links to the people management feature."
    )
    static let users = NSLocalizedString(
        "mySite.menu.users",
        value: "Users",
        comment: "Noun. Title. Links to the user management feature."
    )
    static let plugins = NSLocalizedString(
        "mySite.menu.plugins",
        value: "Plugins",
        comment: "Noun. Title. Links to the plugin management feature."
    )
    static let siteSettings = NSLocalizedString(
        "mySite.menu.siteSettings",
        value: "Site Settings",
        comment: "Noun. Title. Links to the blog's Settings screen."
    )
    static let domains = NSLocalizedString(
        "mySite.menu.domains",
        value: "Domains",
        comment: "Noun. Title. Links to the Domains screen."
    )
    static let viewSite = NSLocalizedString(
        "mySite.menu.viewSite",
        value: "View Site",
        comment: "Action title. Opens the user's site in an in-app browser"
    )
    static let dashboard = NSLocalizedString(
        "mySite.menu.dashboard",
        value: "Dashboard",
        comment: "Action title. Noun. Opens the user's WordPress.com dashboard in an external browser."
    )
    static let wpAdmin = NSLocalizedString(
        "mySite.menu.wpAdmin",
        value: "WP Admin",
        comment: "Action title. Noun. Opens the user's WordPress Admin in an external browser."
    )
    static let applicationPasswords = NSLocalizedString(
        "mySite.menu.applicationPasswords",
        value: "Application Passwords",
        comment: "Link to Application Passwords section"
    )
    static let jetpackSection = NSLocalizedString(
        "mySite.menu.jetpackSection",
        value: "Jetpack",
        comment: "Section title for the jetpack table section in the blog details screen"
    )
    static let publishSection = NSLocalizedString(
        "mySite.menu.publishSection",
        value: "Publish",
        comment: "Section title for the publish table section in the blog details screen"
    )
    static let personalizeSection = NSLocalizedString(
        "mySite.menu.personalizeSection",
        value: "Personalize",
        comment: "Section title for the personalize table section in the blog details screen"
    )
    static let configureSection = NSLocalizedString(
        "mySite.menu.configureSection",
        value: "Configure",
        comment: "Section title for the configure table section in the blog details screen"
    )
    static let externalSection = NSLocalizedString(
        "mySite.menu.externalSection",
        value: "External",
        comment: "Section title for the external table section in the blog details screen"
    )
    static let contentSectionTitle = NSLocalizedString(
        "mySite.menu.content.section.title",
        value: "Content",
        comment: "Section title for the content table section in the blog details screen"
    )
    static let trafficSectionTitle = NSLocalizedString(
        "mySite.menu.traffic.section.title",
        value: "Traffic",
        comment: "Section title for the traffic table section in the blog details screen"
    )
    static let maintenanceSectionTitle = NSLocalizedString(
        "mySite.menu.maintenance.section.title",
        value: "Maintenance",
        comment: "Section title for the maintenance table section in the blog details screen"
    )
    static let socialRowTitle = NSLocalizedString(
        "mySite.menu.social.row.title",
        value: "Social",
        comment: "Title for the social row in the blog details screen"
    )
    static let siteMonitoringRowTitle = NSLocalizedString(
        "mySite.menu.site-monitoring.row.title",
        value: "Site Monitoring",
        comment: "Title for the site monitoring row in the blog details screen"
    )
    static let subscribers = NSLocalizedString(
        "mySite.menu.subscribers",
        value: "Subscribers",
        comment: "Title for the menu item"
    )
}

private enum CellIdentifiers {
    static let standard = "BlogDetailsCell"
    static let plan = "BlogDetailsPlanCell"
    static let settings = "BlogDetailsSettingsCell"
    static let removeSite = "BlogDetailsRemoveSiteCell"
    static let sectionFooter = "BlogDetailsSectionFooterView"
    static let sectionFooterIdentifier = "BlogDetailsSectionFooterIdentifier"
    static let migrationSuccess = "BlogDetailsMigrationSuccessCellIdentifier"
    static let jetpackBrandingCard = "BlogDetailsJetpackBrandingCardCellIdentifier"
    static let jetpackInstall = "BlogDetailsJetpackInstallCardCellIdentifier"
    static let sotWCard = "BlogDetailsSotWCardCellIdentifier"
}
