import Foundation
import WordPressFlux

class PluginViewModel: Observable {
    private enum State {
        case plugin(Plugin)
        case directoryEntry(PluginDirectoryEntry)
        case loading
        case error
    }

    private var state: State {
        didSet {
            changeDispatcher.dispatch()
        }
    }

    private var isInstallingPlugin: Bool {
        didSet {
            if isInstallingPlugin != oldValue {
                changeDispatcher.dispatch()
            }
        }
    }

    private var plugin: Plugin? {
        if case .plugin(let plugin) = state {
            return plugin
        }

        return nil
    }

    private var directoryEntry: PluginDirectoryEntry? {
        if let plugin = plugin {
            return plugin.directoryEntry
        }

        if case .directoryEntry(let entry) = state {
            return entry
        }

        return nil
    }

    private let noResultsLoadingModel = NoResultsViewController.Model(title: String.Loading.title)

    private let noResultsUnknownErrorModel = NoResultsViewController.Model(title: String.UnknownError.title,
                                                                           subtitle: String.UnknownError.description,
                                                                           buttonText: String.UnknownError.buttonTitle)

    private let noResultsConnectivityErrorModel = NoResultsViewController.Model(title: String.NoConnectionError.title,
                                                                                subtitle: String.NoConnectionError.description)


    let site: JetpackSiteRef
    var capabilities: SitePluginCapabilities?

    var storeReceipt: Receipt?
    let changeDispatcher = Dispatcher<Void>()
    let queryReceipt: Receipt?

    private let store: PluginStore

    init(plugin: Plugin, capabilities: SitePluginCapabilities, site: JetpackSiteRef, store: PluginStore = StoreContainer.shared.plugin) {
        self.state = .plugin(plugin)
        self.capabilities = capabilities
        self.site = site
        self.isInstallingPlugin = false
        self.store = store

        queryReceipt = nil
        storeReceipt = store.onChange { [weak self] in
            guard let plugin = store.getPlugin(id: plugin.id, site: site) else {
                self?.dismiss?()
                return
            }

            self?.state = .plugin(plugin)
        }
    }

    convenience init(directoryEntry: PluginDirectoryEntry, site: JetpackSiteRef, store: PluginStore = StoreContainer.shared.plugin) {
        let state: State
        if let plugin = store.getPlugin(slug: directoryEntry.slug, site: site) {
            state = .plugin(plugin)
        } else {
            state = .directoryEntry(directoryEntry)
        }
        self.init(with: directoryEntry.slug, state: state, site: site, store: store)
    }

    convenience init(slug: String, site: JetpackSiteRef, store: PluginStore = StoreContainer.shared.plugin) {
        let state: State
        if let plugin = store.getPlugin(slug: slug, site: site) {
            state = .plugin(plugin)
        } else {
            state = .loading
        }
        self.init(with: slug, state: state, site: site, store: store)
    }

    private init(with slug: String, state: State, site: JetpackSiteRef, store: PluginStore) {
        self.store = store
        self.state = state
        self.capabilities = self.store.getPlugins(site: site)?.capabilities
        self.site = site
        self.isInstallingPlugin = false

        queryReceipt = self.store.query(.directoryEntry(slug: slug))

        storeReceipt = self.store.onChange { [weak self] in
            guard let entry = self?.store.getPluginDirectoryEntry(slug: slug) else {
                self?.state = .error
                return
            }

            if let plugin = self?.store.getPlugin(slug: entry.slug, site: site) {
                self?.state = .plugin(plugin)
            } else {
                self?.state = .directoryEntry(entry)
            }

            self?.capabilities = self?.store.getPlugins(site: site)?.capabilities
            self?.isInstallingPlugin = self?.store.isInstallingPlugin(site: site, slug: slug) ?? false
        }
    }

    var present: ((UIViewController) -> Void)?
    var dismiss: (() -> Void)?

    var versionRow: ImmuTableRow? {
        let versionString: String?

        if plugin?.state.version != nil {
            versionString = plugin?.state.version
        } else {
            versionString = directoryEntry?.version
        }

        guard let version = versionString else {
            // If there's neither `Plugin` nor `PluginDirectoryEntry` that has a `version`, we don't show this row.

            return nil
        }

        let blog = BlogService.blog(with: site)
        let isHostedAtWPCom = blog?.isHostedAtWPcom ?? false
        let hasDomainCredits = blog?.hasDomainCredit ?? false
        let hasCustomDomain = blog?.url?.hasSuffix("wordpress.com") == false

        guard isHostedAtWPCom || capabilities?.modify == true else {
            // If we know about versions, but we can't update/install the plugin, just show the version number.
            return TextRow(title: NSLocalizedString("Plugin version", comment: "Version of an installed plugin"),
                           value: version)
        }

        guard let plugin = plugin else {
            // This means we have capabilities to update a Plugin, but we're not looking at an already-installed plugin.
            // We're gonna show a "install plugin" button.
            guard let directoryEntry = directoryEntry else {
                return nil
            }

            let message = String(format: NSLocalizedString("Version %@", comment: "Version of a plugin to install"), version)

            guard !isInstallingPlugin else {
                return TextWithButtonIndicatingActivityRow(
                    title: message,
                    subtitle: nil)
            }

            return TextWithButtonRow(
                title: message,
                subtitle: nil,
                actionLabel: NSLocalizedString("Install", comment: "Button label to install a plugin"),
                onButtonTap: { [unowned self] _ in

                    // If the site isn't hosted at .com, then we have a straight-forward process on how to handle it.
                    // Let's just install the plugin and bail early here.
                    guard isHostedAtWPCom else {
                        ActionDispatcher.dispatch(PluginAction.install(plugin: directoryEntry, site: self.site))
                        return
                    }

                    if !hasCustomDomain && hasDomainCredits {
                        let alert = self.confirmRegisterDomainAlert(for: directoryEntry)
                        WPAnalytics.track(.automatedTransferCustomDomainDialogShown)
                        self.present?(alert)
                    } else {

                        guard let atHelper = AutomatedTransferHelper(site: self.site, plugin: directoryEntry) else {
                            ActionDispatcher.dispatch(NoticeAction.post(Notice(title: String(format: NSLocalizedString("Error installing %@.", comment: "Notice displayed after attempt to install a plugin fails."), directoryEntry.name))))
                            return
                        }

                        WPAnalytics.track(.automatedTransferDialogShown)

                        let alertController = atHelper.automatedTransferConfirmationPrompt()
                        self.present?(alertController)
                    }
                }
            )
        }

        let versionRow: ImmuTableRow

        switch plugin.state.updateState {
        case .updated:
            versionRow = TextRow(
                title: String(format: NSLocalizedString("Version %@", comment: "Version of an installed plugin"), version),
                value: NSLocalizedString("Installed", comment: "Indicates the state of the plugin")
            )
        case .available(let newVersion):
            let message = String(format: NSLocalizedString("Version %@ is available", comment: "Message to show when a new plugin version is available"), newVersion)
            let subtitle = String(format: NSLocalizedString("Version %@ installed", comment: "Message to show what version is currently installed when a new plugin version is available"), version)

            versionRow = TextWithButtonRow(
                title: message,
                subtitle: subtitle,
                actionLabel: NSLocalizedString("Update", comment: "Button label to update a plugin"),
                onButtonTap: { [unowned self] (_) in
                    ActionDispatcher.dispatch(PluginAction.update(id: plugin.id, site: self.site))
                }
            )
        case .updating(let newVersion):
            let message = String(format: NSLocalizedString("Version %@ is available", comment: "Message to show when a new plugin version is available"), newVersion)
            let subtitle = String(format: NSLocalizedString("Version %@ installed", comment: "Message to show what version is currently installed when a new plugin version is available"), version)

            versionRow = TextWithButtonIndicatingActivityRow(
                title: message,
                subtitle: subtitle
            )
        }

        return versionRow
    }

    func noResultsViewModel() -> NoResultsViewController.Model? {
        switch state {
        case .loading:
            return noResultsLoadingModel
        case .error:
            return getNoResultsErrorModel()
        default:
            return nil
        }
    }

    private func getNoResultsErrorModel() -> NoResultsViewController.Model {
        let appDelegate = WordPressAppDelegate.shared
        let hasConnection = appDelegate?.connectionAvailable ?? true //defaults to unknown error.
        if hasConnection {
            return noResultsUnknownErrorModel
        } else {
            return noResultsConnectivityErrorModel
        }
    }

    private func headerRow(directoryEntry: PluginDirectoryEntry?) -> ImmuTableRow? {
        guard let entry = directoryEntry else { return nil }

        return PluginHeaderRow(
            directoryEntry: entry,
            onLinkTap: { [unowned self] in
                guard let url = entry.authorURL else { return }
                self.presentBrowser(for: url)
        })
    }

    private func activeRow(plugin: Plugin?) -> ImmuTableRow? {
        guard let activationPlugin = plugin,
            activationPlugin.state.deactivateAllowed else { return nil }

        return SwitchRow(
            title: NSLocalizedString("Active", comment: "Whether a plugin is active on a site"),
            value: activationPlugin.state.active,
            onChange: { [unowned self] (active) in
                self.setActive(active, for: activationPlugin)
            }
        )
    }

    private func autoUpdatesRow(plugin: Plugin?, capabilities: SitePluginCapabilities?) -> ImmuTableRow? {
        // Note: All plugins on atomic sites are autoupdated, so we do not want to show the switch

        guard let autoUpdatePlugin = plugin,
            let siteCapabilities = capabilities,
            BlogService.blog(with: site)?.isAutomatedTransfer() == false,
            siteCapabilities.autoupdate,
            !autoUpdatePlugin.state.automanaged else { return nil }

        return SwitchRow(
            title: NSLocalizedString("Autoupdates", comment: "Whether a plugin has enabled automatic updates"),
            value: autoUpdatePlugin.state.autoupdate,
            onChange: { [unowned self] (autoupdate) in
                self.setAutoupdate(autoupdate, for: autoUpdatePlugin)
            }
        )
    }

    private func removeRow(plugin: Plugin?, capabilities: SitePluginCapabilities?) -> ImmuTableRow? {
        guard let pluginToRemove = plugin,
            let siteCapabilities = capabilities,
            siteCapabilities.modify && pluginToRemove.state.deactivateAllowed else { return nil }

        return  DestructiveButtonRow(
            title: NSLocalizedString("Remove Plugin", comment: "Button to remove a plugin from a site"),
            action: { [unowned self] _ in
                let alert = self.confirmRemovalAlert(plugin: pluginToRemove)
                self.present?(alert)
            },
            accessibilityIdentifier: "remove-plugin")
    }

    private func settingsLinkRow(state: PluginState?) -> ImmuTableRow? {
        guard let pluginState = state,
            let settingsURL = pluginState.settingsURL,
            pluginState.deactivateAllowed == true  else {
                return nil
        }

        return LinkRow(
            title: NSLocalizedString("Settings", comment: "Link to plugin's Settings"),
            action: { [unowned self] _ in
                self.presentBrowser(for: settingsURL)
            }
        )
    }

    private func wpOrgLinkRow(directoryEntry: PluginDirectoryEntry?, state: PluginState?) -> ImmuTableRow? {
        guard let url = state?.directoryURL, directoryEntry != nil else { return nil }

        return LinkRow(
            title: NSLocalizedString("WordPress.org Plugin Page", comment: "Link to a WordPress.org page for the plugin"),
            action: { [unowned self] _ in
                self.presentBrowser(for: url)
        })
    }

    private func homeLinkRow(state: PluginState?) -> ImmuTableRow? {
        guard let homeURL = state?.homeURL else { return nil }

        return LinkRow(
            title: NSLocalizedString("Plugin Homepage", comment: "Link to a plugin's home page"),
            action: { [unowned self] _ in
                self.presentBrowser(for: homeURL)
        })
    }

    private func descriptionRow(directoryEntry: PluginDirectoryEntry?) -> ImmuTableRow? {
        guard let text = directoryEntry?.descriptionText else { return nil }

        return ExpandableRow(
            title: NSLocalizedString("Description", comment: "Title of section that contains plugins' description"),
            expandedText: setHTMLTextAttributes(text),
            expanded: descriptionExpandedStatus,
            action: { [unowned self] row in
                self.descriptionExpandedStatus = !self.descriptionExpandedStatus
                (row as? ExpandableRow)?.expanded = self.descriptionExpandedStatus
            },
            onLinkTap: { [unowned self] url in
                self.presentBrowser(for: url)
        })
    }

    private func installationRow(directoryEntry: PluginDirectoryEntry?) -> ImmuTableRow? {
        guard let text = directoryEntry?.installationText else { return nil }

        return ExpandableRow(
            title: NSLocalizedString("Installation", comment: "Title of section that contains plugins' installation instruction"),
            expandedText: setHTMLTextAttributes(text),
            expanded: installationExpandedStatus,
            action: { [unowned self] row in
                self.installationExpandedStatus = !self.installationExpandedStatus
                (row as? ExpandableRow)?.expanded = self.installationExpandedStatus
            },
            onLinkTap: { [unowned self] url in
                self.presentBrowser(for: url)
        })
    }

    private func changelogRow(directoryEntry: PluginDirectoryEntry?) -> ImmuTableRow? {
        guard let text = directoryEntry?.changelogText else { return nil }

        return ExpandableRow(
            title: NSLocalizedString("What's New", comment: "Title of section that contains plugins' change log"),
            expandedText: setHTMLTextAttributes(text),
            expanded: changeLogExpandedStatus,
            action: { [unowned self] row in
                self.changeLogExpandedStatus = !self.changeLogExpandedStatus
                (row as? ExpandableRow)?.expanded = self.changeLogExpandedStatus
            },
            onLinkTap: { [unowned self] url in
                self.presentBrowser(for: url)
        })
    }

    private func faqRow(directoryEntry: PluginDirectoryEntry?) -> ImmuTableRow? {
        guard let text = directoryEntry?.faqText else { return nil }

        return ExpandableRow(
            title: NSLocalizedString("Frequently Asked Questions", comment: "Title of section that contains plugins' FAQ"),
            expandedText: setHTMLTextAttributes(text),
            expanded: faqExpandedStatus,
            action: { [unowned self] row in
                self.faqExpandedStatus = !self.faqExpandedStatus
                (row as? ExpandableRow)?.expanded = self.faqExpandedStatus
            },
            onLinkTap: { [unowned self] url in
                self.presentBrowser(for: url)
        })
    }

    var tableViewModel: ImmuTable {

        let header = headerRow(directoryEntry: directoryEntry)

        let active = activeRow(plugin: plugin)
        let autoupdates = autoUpdatesRow(plugin: plugin, capabilities: capabilities)

        let settingsLink = settingsLinkRow(state: plugin?.state)
        let wpOrgPluginLink = wpOrgLinkRow(directoryEntry: directoryEntry, state: plugin?.state)
        let homeLink = homeLinkRow(state: plugin?.state)

        let description = descriptionRow(directoryEntry: directoryEntry)
        let installation = installationRow(directoryEntry: directoryEntry)
        let changelog = changelogRow(directoryEntry: directoryEntry)
        let faq = faqRow(directoryEntry: directoryEntry)

        let remove = removeRow(plugin: plugin, capabilities: capabilities)

        return ImmuTable(optionalSections: [
            ImmuTableSection(optionalRows: [
                header,
                versionRow
                ]),
            ImmuTableSection(optionalRows: [
                active,
                autoupdates
                ]),
            ImmuTableSection(optionalRows: [
                settingsLink,
                wpOrgPluginLink,
                homeLink
                ]),
            ImmuTableSection(optionalRows: [
                description,
                installation,
                changelog,
                faq
                ]),
            ImmuTableSection(optionalRows: [
                remove
                ])
            ])
    }

    private func confirmRegisterDomainAlert(for directoryEntry: PluginDirectoryEntry) -> UIAlertController {
        let title = NSLocalizedString("Install Plugin", comment: "Install Plugin dialog title.")
        let message = NSLocalizedString("To install plugins, you need to have a custom domain associated with your site.", comment: "Install Plugin dialog text.")
        let registerDomainActionTitle = NSLocalizedString("Register domain", comment: "Install Plugin dialog register domain button text")

        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)

        alertController.addCancelActionWithTitle(NSLocalizedString("Cancel", comment: "Cancel registering a domain")) { _ in
            WPAnalytics.track(.automatedTransferCustomDomainDialogCancelled)
        }

        let registerDomainAction = alertController.addDefaultActionWithTitle(registerDomainActionTitle) { [weak self] (action) in
            self?.presentDomainRegistration(for: directoryEntry)
        }

        alertController.preferredAction = registerDomainAction
        return alertController
    }

    private func confirmRemovalAlert(plugin: Plugin) -> UIAlertController {
        let question: String
        if let siteTitle = getSiteTitle() {
            question = String(
                format: NSLocalizedString("Are you sure you want to remove %1$@ from %2$@?", comment: "Text for the alert to confirm a plugin removal. %1$@ is the plugin name, %2$@ is the site title."),
                plugin.name,
                siteTitle)
        } else {
            question = String(
                format: NSLocalizedString("Are you sure you want to remove %1$@?", comment: "Text for the alert to confirm a plugin removal. %1$@ is the plugin name."),
                plugin.name)
        }
        let disclaimer: String
        if plugin.state.active {
            disclaimer = NSLocalizedString("This will deactivate the plugin and delete all associated files and data.", comment: "Warning when confirming to remove a plugin that's active")
        } else {
            disclaimer = NSLocalizedString("This will delete all associated files and data.", comment: "Warning when confirming to remove a plugin that's inactive")
        }
        let message = "\(question)\n\(disclaimer)"
        let alert = UIAlertController(
            title: NSLocalizedString("Remove Plugin?", comment: "Title for the alert to confirm a plugin removal"),
            message: message, preferredStyle: .alert)
        alert.addCancelActionWithTitle(NSLocalizedString("Cancel", comment: "Cancel removing a plugin"))
        alert.addDestructiveActionWithTitle(
            NSLocalizedString("Remove", comment: "Alert button to confirm a plugin to be removed"),
            handler: { [unowned self] _ in
                ActionDispatcher.dispatch(PluginAction.remove(id: plugin.id, site: self.site))
            }
        )
        return alert
    }

    private func presentDomainRegistration(for directoryEntry: PluginDirectoryEntry) {
        let controller = RegisterDomainSuggestionsViewController.instance(site: site, domainPurchasedCallback: { [weak self] domain in

            guard let strongSelf = self,
                let atHelper = AutomatedTransferHelper(site: strongSelf.site, plugin: directoryEntry) else {

                    ActionDispatcher.dispatch(NoticeAction.post(Notice(title: String(format: NSLocalizedString("Error installing %@.", comment: "Notice displayed after attempt to install a plugin fails."), directoryEntry.name))))
                return
            }

            atHelper.startAutomatedTransferProcess(retryingAfterFailure: true)
        })
        let navigationController = UINavigationController(rootViewController: controller)
        self.present?(navigationController)
    }

    private func presentBrowser(`for` url: URL) {
        let controller = WebViewControllerFactory.controller(url: url)
        let navigationController = UINavigationController(rootViewController: controller)
        self.present?(navigationController)
    }

    private func setActive(_ active: Bool, `for` plugin: Plugin) {
        if active {
            ActionDispatcher.dispatch(PluginAction.activate(id: plugin.id, site: site))
        } else {
            ActionDispatcher.dispatch(PluginAction.deactivate(id: plugin.id, site: site))
        }
    }

    private func setAutoupdate(_ autoupdate: Bool, `for` plugin: Plugin) {
        if autoupdate {
            ActionDispatcher.dispatch(PluginAction.enableAutoupdates(id: plugin.id, site: site))
        } else {
            ActionDispatcher.dispatch(PluginAction.disableAutoupdates(id: plugin.id, site: site))
        }
    }

    private func getSiteTitle() -> String? {
        return BlogService.blog(with: site)?.settings?.name?.nonEmptyString()
    }


    private func setHTMLTextAttributes(_ htmlText: NSAttributedString) -> NSAttributedString {
        guard let copy = htmlText.mutableCopy() as? NSMutableAttributedString else { return htmlText }

        let nonOptions = [NSTextTab.OptionKey: Any]()
        let fixedTabStops = [NSTextTab(textAlignment: .left, location: 0, options: nonOptions)]

        copy.enumerateAttribute(NSAttributedString.Key.font,
                                in: NSRange(location: 0, length: copy.length),
                                options: NSAttributedString.EnumerationOptions(rawValue: 0)) { (value, range, _) in
            guard let font = value as? UIFont, font.familyName == "Times New Roman" else { return }

            copy.addAttribute(.font, value: WPStyleGuide.subtitleFont(), range: range)
            copy.addAttribute(.foregroundColor, value: UIColor.text, range: range)
        }


        var paragraphAttributes: [(paragraph: NSParagraphStyle, range: NSRange)] = []

        copy.enumerateAttribute(NSAttributedString.Key.paragraphStyle,
                                in: NSRange(location: 0, length: copy.length),
                                options: [.longestEffectiveRangeNotRequired]) { (value, range, _) in
            guard let paragraphStyle = value as? NSParagraphStyle else { return }

            paragraphAttributes.append((paragraphStyle, range))
        }

        for (index, item) in paragraphAttributes.enumerated() {
            let paragraphStyle = item.paragraph
            let range = item.range

            var mutableParagraphStyle: NSMutableParagraphStyle?

            if paragraphStyle.tabStops.isEmpty == false {
                // this means it's a list. we need to fix up the tab stops.

                mutableParagraphStyle = mutableParagraphStyle ?? paragraphStyle.mutableCopy() as! NSMutableParagraphStyle
                mutableParagraphStyle?.tabStops = fixedTabStops
                mutableParagraphStyle?.defaultTabInterval = 5
                mutableParagraphStyle?.firstLineHeadIndent = 0
                mutableParagraphStyle?.headIndent = 15

                if index + 1 < paragraphAttributes.endIndex,
                    paragraphAttributes[index + 1].paragraph.tabStops.isEmpty {
                    // this means that the next paragraph is _not_ a list.
                    // we need to add paragraphSpacingBefore, so that there's a nice gap between the list and next paragraph.

                    let nextItem = paragraphAttributes[index + 1]

                    let nextMutableParagraph = nextItem.paragraph.mutableCopy() as! NSMutableParagraphStyle
                    nextMutableParagraph.paragraphSpacingBefore = 12

                    copy.addAttribute(.paragraphStyle, value: nextMutableParagraph, range: nextItem.range)
                }
            }

            if ceil(paragraphStyle.paragraphSpacing) == 16 {
                // It gets calculated by system as 15.96<something after the second significant digit>,
                // but it's a PITA to compare Doubles that precise, so let's just round it up instead.

                mutableParagraphStyle = mutableParagraphStyle ?? paragraphStyle.mutableCopy() as! NSMutableParagraphStyle
                copy.addAttribute(.font, value: WPStyleGuide.subtitleFontBold(), range: range)
                mutableParagraphStyle?.paragraphSpacing = 12
            }

            if let newParagraphStyle = mutableParagraphStyle {
                copy.addAttribute(.paragraphStyle, value: newParagraphStyle, range: range)
            }
        }

        return copy
    }

    var title: String {
        return plugin?.name ?? directoryEntry?.name ?? ""
    }

    private var descriptionExpandedStatus: Bool = true
    private var installationExpandedStatus: Bool = false
    private var changeLogExpandedStatus: Bool = false
    private var faqExpandedStatus: Bool = false

    static var immutableRows: [ImmuTableRow.Type] {
        return [SwitchRow.self, DestructiveButtonRow.self, NavigationItemRow.self, TextRow.self, TextWithButtonRow.self, PluginHeaderRow.self, LinkRow.self, ExpandableRow.self]
    }
}

private extension String {
    enum UnknownError {
        static let title = NSLocalizedString("Oops", comment: "Title for the view when there's an error loading the plugin")
        static let description = NSLocalizedString("There was an error loading this plugin", comment: "Text displayed when there is a failure loading the plugin")
        static let buttonTitle = NSLocalizedString("Contact support", comment: "Button label for contacting support")
    }

    enum NoConnectionError {
        static let title = NSLocalizedString("No connection", comment: "Title for the error view when there's no connection")
        static let description = NSLocalizedString("An active internet connection is required to view plugins", comment: "Error message when the user tries to visualize a plugin without internet connection")
    }

    enum Loading {
        static let title = NSLocalizedString("Loading Plugin...", comment: "Text displayed while loading an specific plugin")
    }
}

extension PluginViewModel {
    func networkStatusDidChange(active: Bool) {
        guard active else {
            return
        }

        switch state {
        case .error:
            store.processQueries()
            state = .loading
        case .directoryEntry(let entry):
            store.processQueries()
            state = .directoryEntry(entry)
        default:
            break
        }
    }
}
