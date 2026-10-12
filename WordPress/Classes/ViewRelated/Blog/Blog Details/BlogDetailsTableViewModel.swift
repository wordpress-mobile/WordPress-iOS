import Foundation
import UIKit
import WordPressLegacy
import WordPressShared
import WordPressSharedObjC
import WordPressUI
import WordPressComments
import Support
import SwiftUI

private typealias Row = BlogDetailsTableViewModel.Row

extension BlogDetailsTableViewModel {
    struct Section {
        var title: String?
        let rows: [Row]
        var footerTitle: String?
        let category: SectionCategory
    }
}

@MainActor
@objc public final class BlogDetailsTableViewModel: NSObject, ObservableObject {
    var blog: Blog {
        didSet {
            if blog != oldValue { updateCommentsView() }
        }
    }
    private weak var viewController: BlogDetailsViewController?
    @Published private(set) var sections: [Section] = []
    @Published private(set) var selectedRowID: Row.ID?

    var gravatarIcon: UIImage? {
        didSet { configureTableViewData() }
    }

    var hasCustomPostTypes = false
    private var commentsView: CommentsView?

    @objc public init(blog: Blog, viewController: BlogDetailsViewController) {
        self.blog = blog
        self.viewController = viewController
        super.init()
    }

    @objc public func viewWillAppear() {
        if !isSplitViewDisplayed {
            selectedRowID = nil
        }
    }

    @objc public func configureTableViewData() {
        guard let viewController else { return }

        var newSections: [Section] = []

        if viewController.shouldShowJetpackInstallCard() {
            newSections.append(Section(rows: [], category: .jetpackInstallCard))
        }

        if viewController.shouldShowTopJetpackBrandingMenuCard {
            newSections.append(Section(rows: [], category: .jetpackBrandingCard))
        }

        if blog.isSelfHosted, ExtensiveLogging.enabled {
            newSections.append(Section(rows: [], category: .extensiveLogging))
        }

        if blog.isSelfHosted, blog.isXMLRPCDisabled {
            newSections.append(Section(rows: [], category: .xmlrpcDisabled))
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

        updateCommentsView()
        sections = newSections
    }

    /// Resolving the Comments client reads the keychain, so cache the destination instead of building it per render.
    private func updateCommentsView() {
        commentsView = isSplitViewDisplayed ? nil : CommentsRouting.makeView(for: blog)
    }

    var isSplitViewDisplayed: Bool {
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

    func clearSelection() {
        selectedRowID = nil
    }

    func commentsDestination(for row: Row) -> CommentsView? {
        row.kind == .comments ? commentsView : nil
    }

    func trackCommentsOpened() {
        viewController?.trackCommentsV2Opened(from: .row)
    }

    func select(_ row: Row) {
        guard !isSplitViewDisplayed || selectedRowID != row.id else { return }
        row.action?([:])
        if row.showsSelectionState {
            selectedRowID = row.id
        }
    }

    @objc public func showInitialDetailsForBlog() {
        guard isSplitViewDisplayed else { return }

        let row = defaultSubsection()

        self.showDetailView(for: row)
    }

    func showDetailViewForMe(userInfo: [String: Any]) -> MeViewController {
        guard let viewController else {
            wpAssertionFailure("The view controller should not be nil")
            return MeViewController()
        }
        selectedRowID = .row(.me)
        return viewController.showMe()
    }

    func showDetailView(for row: BlogDetailsRowKind, userInfo: [String: Any] = [:]) {
        guard let item = sections.lazy.flatMap(\.rows).first(where: { $0.kind == row }) else { return }
        if item.showsSelectionState {
            selectedRowID = item.id
        }
        item.action?(userInfo)
    }

    func makeCard(for category: SectionCategory) -> UITableViewCell {
        let cell = makeConfiguredCard(for: category)
        cell.backgroundColor = .clear
        return cell
    }

    private func makeConfiguredCard(for category: SectionCategory) -> UITableViewCell {
        guard let viewController else { return UITableViewCell() }
        switch category {
        case .jetpackInstallCard:
            let cell = JetpackRemoteInstallTableViewCell()
            cell.configure(blog: blog, viewController: viewController)
            return cell
        case .migrationSuccess:
            let cell = MigrationSuccessCell()
            if isSplitViewDisplayed {
                cell.configureForSidebarMode()
            }
            cell.configure(with: viewController)
            return cell
        case .jetpackBrandingCard:
            let cell = JetpackBrandingMenuCardCell()
            cell.configure(with: viewController)
            return cell
        case .extensiveLogging:
            let cell = ExtensiveLoggingCell()
            cell.configure(with: viewController)
            return cell
        case .xmlrpcDisabled:
            let cell = XMLRPCDisabledCell()
            cell.onTapped = { [weak self] in self?.presentXMLRPCDisabledAlert() }
            return cell
        default:
            return UITableViewCell()
        }
    }

    private func presentXMLRPCDisabledAlert() {
        guard let viewController else { return }

        let alert = AlertView {
            AlertHeaderView(
                title: XMLRPCDisabledAlertStrings.title,
                description: XMLRPCDisabledAlertStrings.description
            )
        } content: {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundStyle(.orange)
        } actions: { [weak self, weak viewController] in
            Button {
                viewController?
                    .dismiss(animated: true) {
                        self?.presentJetpackConnection()
                    }
            } label: {
                Text(XMLRPCDisabledAlertStrings.connectJetpack)
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.extraLarge)

            Button { [weak viewController] in
                let url = URL(
                    string:
                        "https://apps.wordpress.com/support/mobile/login-signup/inaccessible-xml-rpc-connection-error/"
                )!
                viewController?
                    .dismiss(animated: true) {
                        UIApplication.shared.open(url)
                    }
            } label: {
                Text(XMLRPCDisabledAlertStrings.learnMore)
            }
        }

        alert.present(in: viewController)
    }

    private func presentJetpackConnection() {
        let controller = UIViewController.jetpackConnection(blog: blog)
        controller.promptType = .bypassXMLRPC
        controller.completionBlock = { [weak controller, weak self] in
            controller?
                .dismiss(animated: true) {
                    self?.viewController?.refresh()
                }
        }
        controller.navigationItem.leftBarButtonItem = UIBarButtonItem(
            systemItem: .close,
            primaryAction: UIAction { [weak controller] _ in
                controller?.dismiss(animated: true)
            }
        )
        let nav = UINavigationController(rootViewController: controller)
        viewController?.present(nav, animated: true)
    }
}

private extension BlogDetailsTableViewModel {
    func buildHomeSection() -> Section {
        Section(rows: [Row.home(viewController: viewController)], category: .home)
    }

    func buildContentSection() -> Section {
        var rows: [Row] = []

        rows.append(Row.posts(viewController: viewController))

        if blog.supports(.pages) {
            rows.append(Row.pages(viewController: viewController))
        }

        rows.append(Row.media(viewController: viewController))
        rows.append(Row.comments(viewController: viewController))

        if blog.supportsCoreRESTAPI {
            let pinned = SiteStorageAccess.pinnedPostTypes(for: TaggedManagedObjectID(blog))
                .filter { !$0.isBuiltInPostOrPage }
            for type in pinned {
                rows.append(Row.pinnedPostType(type, viewController: viewController))
            }
            if !pinned.isEmpty || hasCustomPostTypes {
                rows.append(Row.customPostTypes(viewController: viewController))
            }
        }

        let title = isSplitViewDisplayed ? nil : Strings.contentSectionTitle
        return Section(title: title, rows: rows, category: .content)
    }

    func buildRemoveSiteSection() -> Section {
        Section(rows: [Row.removeSite(viewController: viewController)], category: .removeSite)
    }

    func buildJetpackSection() -> Section {
        var rows: [Row] = []

        if blog.isViewingStatsAllowed {
            rows.append(Row.stats(viewController: viewController))
        }

        if blog.supports(.activity) && !blog.isWPForTeams {
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

        let title =
            if blog.supports(.jetpackSettings) {
                Strings.jetpackSection
            } else {
                ""
            }

        return Section(title: title, rows: rows, category: .jetpack)
    }

    func buildGeneralSection() -> Section {
        var rows: [Row] = []

        if blog.isViewingStatsAllowed {
            rows.append(Row.stats(viewController: viewController))
        }

        if blog.supports(.activity) && !blog.isWPForTeams {
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

        if blog.supportsCoreRESTAPI {
            let pinned = SiteStorageAccess.pinnedPostTypes(for: TaggedManagedObjectID(blog))
                .filter { !$0.isBuiltInPostOrPage }
            for type in pinned {
                rows.append(Row.pinnedPostType(type, viewController: viewController))
            }
            if !pinned.isEmpty || hasCustomPostTypes {
                rows.append(Row.customPostTypes(viewController: viewController))
            }
        }

        let title = Strings.publishSection
        return Section(title: title, rows: rows, category: .content)
    }

    func buildPersonalizeSection() -> Section {
        var rows: [Row] = []

        if blog.supports(.themeBrowsing) && !blog.isWPForTeams {
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

        if blog.isViewingStatsAllowed {
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
        if blog.supports(.activity) && !blog.isWPForTeams {
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

        if blog.supports(.themeBrowsing) && !blog.isWPForTeams {
            secondSectionRows.append(Row.themes(viewController: viewController))
        }

        if blog.supports(.menus) {
            secondSectionRows.append(Row.menus(viewController: viewController))
        }

        if viewController.shouldAddDomainRegistrationRow() {
            secondSectionRows.append(Row.domains(viewController: viewController))
        }

        if blog.supports(.applicationPasswords) {
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
            sections.append(
                Section(
                    title: sectionTitle,
                    rows: firstSectionRows,
                    category: .maintenance
                )
            )
            shouldAddSectionTitle = false
        }

        if !secondSectionRows.isEmpty {
            sections.append(
                Section(
                    title: shouldAddSectionTitle ? sectionTitle : nil,
                    rows: secondSectionRows,
                    category: .maintenance
                )
            )
            shouldAddSectionTitle = false
        }

        if !thirdSectionRows.isEmpty {
            sections.append(
                Section(
                    title: shouldAddSectionTitle ? sectionTitle : nil,
                    rows: thirdSectionRows,
                    category: .maintenance
                )
            )
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
            let dateCreated = defaultAccount.dateCreated
        else {
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

extension BlogDetailsTableViewModel {
    enum SectionCategory: Hashable {
        case reminders
        case domainCredit
        case extensiveLogging
        case xmlrpcDisabled
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
        case content
        case traffic
        case maintenance
    }
}

enum BlogDetailsRowKind: Hashable {
    case reminders
    case domain
    case stats
    case posts
    case customize
    case themes
    case media
    case pages
    case customPostTypes
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
    case pinnedPostType
    case removeSite
}

extension BlogDetailsTableViewModel {
    struct Row: Identifiable {
        enum ID: Hashable {
            case row(BlogDetailsRowKind)
            case pinnedPostType(String)
        }

        let id: ID
        let kind: BlogDetailsRowKind
        let title: String
        let accessibilityIdentifier: String?
        let accessibilityHint: String?
        let image: UIImage?
        let imageColor: UIColor?
        let accessoryImage: UIImage?
        let detail: String?
        let showsSelectionState: Bool
        let showsDisclosureIndicator: Bool
        let action: (@MainActor ([String: Any]) -> Void)?

        init(
            kind: BlogDetailsRowKind,
            id: ID? = nil,
            title: String,
            accessibilityIdentifier: String? = nil,
            accessibilityHint: String? = nil,
            image: UIImage?,
            imageColor: UIColor? = .label,
            accessoryImage: UIImage? = nil,
            detail: String? = nil,
            showsSelectionState: Bool = true,
            showsDisclosureIndicator: Bool = true,
            action: (@MainActor ([String: Any]) -> Void)? = nil,
        ) {
            self.title = title
            self.accessibilityIdentifier = accessibilityIdentifier
            self.accessibilityHint = accessibilityHint
            self.image = imageColor == nil ? image : image?.withRenderingMode(.alwaysTemplate)
            self.imageColor = imageColor
            self.accessoryImage = accessoryImage
            self.detail = detail
            self.showsSelectionState = showsSelectionState
            self.showsDisclosureIndicator = showsDisclosureIndicator
            self.action = action
            self.kind = kind
            self.id = id ?? .row(kind)
        }
    }
}

private extension BlogDetailsTableViewModel.Row {
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

    static func customPostTypes(viewController: BlogDetailsViewController?) -> Row {
        Row(
            kind: .customPostTypes,
            title: CustomPostTypesView.title,
            image: UIImage(systemName: "ellipsis"),
            action: { [weak viewController] _ in
                viewController?.showCustomPostTypes()
            }
        )
    }

    static func pinnedPostType(_ type: PinnedPostType, viewController: BlogDetailsViewController?) -> Row {
        Row(
            kind: .pinnedPostType,
            id: .pinnedPostType(type.slug),
            title: type.name,
            image: UIImage(dashicon: type.icon),
            action: { [weak viewController] _ in
                viewController?.showPinnedPostType(type)
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
        let sharingTitle =
            AppConfiguration.isWordPress
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
        let title =
            viewController?.shouldShowSubscribersRow == true
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
                let showManagement =
                    (userInfo[BlogDetailsUserInfoKeys.showManagePlugins] as? NSNumber)?.boolValue ?? false
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

        return Row(
            kind: .admin,
            title: adminTitle,
            image: UIImage.gridicon(.mySites),
            accessoryImage: accessoryImage,
            showsSelectionState: false,
            action: { [weak viewController] _ in
                viewController?.showViewAdmin()
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

private enum XMLRPCDisabledAlertStrings {
    static let title = NSLocalizedString(
        "blogDetails.xmlrpcDisabled.alert.title",
        value: "XML-RPC Disabled",
        comment: "Title for the XML-RPC disabled alert"
    )
    static let description = NSLocalizedString(
        "blogDetails.xmlrpcDisabled.alert.description",
        value:
            "XML-RPC is disabled on your site. Some features in the app currently require XML-RPC. Connect Jetpack or enable XML-RPC to access all features.",
        comment: "Description explaining options to restore functionality when XML-RPC is disabled"
    )
    static let connectJetpack = NSLocalizedString(
        "blogDetails.xmlrpcDisabled.alert.connectJetpack",
        value: "Connect Jetpack",
        comment: "Button title to connect Jetpack in XML-RPC disabled alert"
    )
    static let learnMore = NSLocalizedString(
        "blogDetails.xmlrpcDisabled.alert.learnMore",
        value: "Learn more",
        comment: "Button title to learn more about XML-RPC being disabled"
    )
}
