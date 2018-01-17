import Foundation
import WordPressFlux

class PluginViewModel: Observable {
    var plugin: Plugin {
        didSet {
            changeDispatcher.dispatch()
        }
    }
    let capabilities: SitePluginCapabilities
    let site: JetpackSiteRef
    var storeReceipt: Receipt?
    let changeDispatcher = Dispatcher<Void>()

    init(plugin: Plugin, capabilities: SitePluginCapabilities, site: JetpackSiteRef, store: PluginStore = StoreContainer.shared.plugin) {
        self.plugin = plugin
        self.capabilities = capabilities
        self.site = site
        storeReceipt = store.onChange { [weak self] in
            guard let plugin = store.getPlugin(id: plugin.id, site: site) else {
                self?.dismiss?()
                return
            }
            self?.plugin = plugin
        }
    }

    var present: ((UIViewController) -> Void)?
    var dismiss: (() -> Void)?

    var tableViewModel: ImmuTable {

        var header: ImmuTableRow?
        if let directory = plugin.directoryEntry {
            header = PluginHeaderRow(
                directoryEntry: directory,
                onLinkTap: { [unowned self] in
                    guard let url = directory.authorURL else { return }
                    self.presentBrowser(for: url)
            })
        }

        var versionRow: ImmuTableRow?
        switch (plugin.state.version, plugin.state.updateState) {
            case (let version?, .updated):
                versionRow = TextRow(
                    title: NSLocalizedString("Version \(version)", comment: "Version of an installed plugin"),
                    value: NSLocalizedString("Installed", comment: "Indicates the state of the plugin")
                )
            case (let version?, .available(let newVersion)):
                let message = String(format: NSLocalizedString("Version %@ is available", comment: "Message to show when a new plugin version is available"), newVersion)
                let subtitle = String(format: NSLocalizedString("Version %@ installed", comment: "Message to show what version is currently installed when a new plugin version is available"), version)

                versionRow = TextWithButtonRow(
                    title: message,
                    subtitle: subtitle,
                    actionLabel: NSLocalizedString("Update", comment: "Button label to update a plugin"),
                    action: { [unowned self] (_) in
                        ActionDispatcher.dispatch(PluginAction.update(id: self.plugin.id, site: self.site))
                    }
                )
            case (let version?, .updating(let newVersion)):
                let message = String(format: NSLocalizedString("Version %@ is available", comment: "Message to show when a new plugin version is available"), newVersion)
                let subtitle = String(format: NSLocalizedString("Version %@ installed", comment: "Message to show what version is currently installed when a new plugin version is available"), version)

                versionRow = TextWithButtonIndicatingActivityRow(
                    title: message,
                    subtitle: subtitle
            )

            case (nil, _):
                versionRow = nil
        }

        var activeRow: ImmuTableRow?
        if plugin.state.deactivateAllowed {
            activeRow = SwitchRow(
                title: NSLocalizedString("Active", comment: "Whether a plugin is active on a site"),
                value: plugin.state.active,
                onChange: { [unowned self] (active) in
                    self.setActive(active)
                }
            )
        }

        var autoupdatesRow: ImmuTableRow?
        if capabilities.autoupdate && !plugin.state.automanaged {
            autoupdatesRow = SwitchRow(
                title: NSLocalizedString("Autoupdates", comment: "Whether a plugin has enabled automatic updates"),
                value: plugin.state.autoupdate,
                onChange: { [unowned self] (autoupdate) in
                    self.setAutoupdate(autoupdate)
                }
            )
        }

        var removeRow: ImmuTableRow?
        if capabilities.modify && plugin.state.deactivateAllowed {
            removeRow = DestructiveButtonRow(
                title: NSLocalizedString("Remove Plugin", comment: "Button to remove a plugin from a site"),
                action: { [unowned self] _ in
                    let alert = self.confirmRemovalAlert(plugin: self.plugin)
                    self.present?(alert)
                },
                accessibilityIdentifier: "remove-plugin")
        }

        var settingsLink: ImmuTableRow?
        if let settingsURL = plugin.state.settingsURL, plugin.state.deactivateAllowed == true{
            settingsLink = LinkRow(
                title: NSLocalizedString("Settings", comment: "Link to plugin's Settings"),
                action: { [unowned self] _ in
                    self.presentBrowser(for: settingsURL)

            })
        }

        var wpOrgPluginLink: ImmuTableRow?
        if plugin.directoryEntry != nil {
            wpOrgPluginLink = LinkRow(
                title: NSLocalizedString("WordPress.org Plugin Page", comment: "Link to a WordPress.org page for the plugin"),
                action: { [unowned self] _ in
                  self.presentBrowser(for: self.plugin.state.directoryURL)
            })
        }

        var homeLink: ImmuTableRow?
        if let homeURL = plugin.state.homeURL {
            homeLink = LinkRow(
                title: NSLocalizedString("Plugin Homepage", comment: "Link to a plugin's home page"),
                action: { [unowned self] _ in
                    self.presentBrowser(for: homeURL)
            })
        }

        var descriptionRow: ExpandableRow?
        if let description = plugin.directoryEntry?.descriptionText {
            descriptionRow = ExpandableRow(
                title: NSLocalizedString("Description", comment: "Title of section that contains plugins' description"),
                expandedText: setHTMLTextAttributes(description),
                expanded: descriptionExpandedStatus,
                action: { [unowned self] _ in
                    self.descriptionExpandedStatus = !self.descriptionExpandedStatus
                    descriptionRow?.expanded = self.descriptionExpandedStatus
                },
                onLinkTap: { [unowned self] url in
                    self.presentBrowser(for: url)
            })
        }

        var installationRow: ExpandableRow?
        if let installation = plugin.directoryEntry?.installationText {
            installationRow = ExpandableRow(
                title: NSLocalizedString("Installation", comment: "Title of section that contains plugins' installation instruction"),
                expandedText: setHTMLTextAttributes(installation),
                expanded: installationExpandedStatus,
                action: { [unowned self] _ in
                    self.installationExpandedStatus = !self.installationExpandedStatus
                    installationRow?.expanded = self.installationExpandedStatus
                },
                onLinkTap: { [unowned self] url in
                    self.presentBrowser(for: url)
            })
        }

        var changelogRow: ExpandableRow?
        if let changelog = plugin.directoryEntry?.changelogText {
            changelogRow = ExpandableRow(
                title: NSLocalizedString("What's New", comment: "Title of section that contains plugins' change log"),
                expandedText: setHTMLTextAttributes(changelog),
                expanded: changeLogExpandedStatus,
                action: { [unowned self] _ in
                    self.changeLogExpandedStatus = !self.changeLogExpandedStatus
                    changelogRow?.expanded = self.changeLogExpandedStatus
                },
                onLinkTap: { [unowned self] url in
                    self.presentBrowser(for: url)
            })
        }

        var faqRow: ExpandableRow?
        if let faq = plugin.directoryEntry?.faqText {
            faqRow = ExpandableRow(
                title: NSLocalizedString("Frequently Asked Questions", comment: "Title of section that contains plugins' FAQ"),
                expandedText: setHTMLTextAttributes(faq),
                expanded: faqExpandedStatus,
                action: { [unowned self] _ in
                    self.faqExpandedStatus = !self.faqExpandedStatus
                    faqRow?.expanded = self.faqExpandedStatus
                },
                onLinkTap: { [unowned self] url in
                    self.presentBrowser(for: url)
            })
        }

        return ImmuTable(optionalSections: [
            ImmuTableSection(optionalRows: [
                header,
                versionRow
                ]),
            ImmuTableSection(optionalRows: [
                activeRow,
                autoupdatesRow
                ]),
            ImmuTableSection(optionalRows: [
                settingsLink,
                wpOrgPluginLink,
                homeLink
                ]),
            ImmuTableSection(optionalRows: [
                descriptionRow,
                installationRow,
                changelogRow,
                faqRow
                ]),
            ImmuTableSection(optionalRows: [
                removeRow
                ])
            ])
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
                ActionDispatcher.dispatch(PluginAction.remove(id: self.plugin.id, site: self.site))
            }
        )
        return alert
    }

    private func presentBrowser(`for` url: URL) {
        let controller = WebViewControllerFactory.controller(url: url)
        let navigationController = UINavigationController(rootViewController: controller)
        self.present?(navigationController)
    }

    private func setActive(_ active: Bool) {
        if active {
            ActionDispatcher.dispatch(PluginAction.activate(id: plugin.id, site: site))
        } else {
            ActionDispatcher.dispatch(PluginAction.deactivate(id: plugin.id, site: site))
        }
    }

    private func setAutoupdate(_ autoupdate: Bool) {
        if autoupdate {
            ActionDispatcher.dispatch(PluginAction.enableAutoupdates(id: plugin.id, site: site))
        } else {
            ActionDispatcher.dispatch(PluginAction.disableAutoupdates(id: plugin.id, site: site))
        }
    }

    private func getSiteTitle() -> String? {
        let context = ContextManager.sharedInstance().mainContext
        let service = BlogService(managedObjectContext: context)
        let blog = service.blog(byBlogId: site.siteID as NSNumber)
        return blog?.settings?.name?.nonEmptyString()
    }

    private func setHTMLTextAttributes(_ htmlText: NSAttributedString) -> NSAttributedString {
        guard let copy = htmlText.mutableCopy() as? NSMutableAttributedString else { return htmlText }

        let nonOptions = [NSTextTab.OptionKey: Any]()
        let fixedTabStops = [NSTextTab(textAlignment: .left, location: 0, options: nonOptions)]

        copy.enumerateAttribute(NSAttributedStringKey.font, in: NSMakeRange(0, copy.length), options: NSAttributedString.EnumerationOptions(rawValue: 0)) { (value, range, stop) in
            guard let font = value as? UIFont, font.familyName == "Times New Roman" else { return }

            copy.addAttribute(.font, value: WPStyleGuide.subtitleFont(), range: range)
            copy.addAttribute(.foregroundColor, value: WPStyleGuide.darkGrey(), range: range)
        }

        copy.enumerateAttribute(NSAttributedStringKey.paragraphStyle, in: NSMakeRange(0, copy.length), options: NSAttributedString.EnumerationOptions(rawValue: 0)) { (value, range, stop) in
            guard let paragraphStyle = value as? NSParagraphStyle else { return }

            var mutableParagraphStyle: NSMutableParagraphStyle?

            if paragraphStyle.tabStops.isEmpty == false {
                // this means it's a list. we need to fix up the tab stops.

                mutableParagraphStyle = mutableParagraphStyle ?? paragraphStyle.mutableCopy() as! NSMutableParagraphStyle
                mutableParagraphStyle?.tabStops = fixedTabStops
                mutableParagraphStyle?.defaultTabInterval = 5
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
        return plugin.name
    }

    private var descriptionExpandedStatus: Bool = true
    private var installationExpandedStatus: Bool = false
    private var changeLogExpandedStatus: Bool = false
    private var faqExpandedStatus: Bool = false

    static var immutableRows: [ImmuTableRow.Type] {
        return [SwitchRow.self, DestructiveButtonRow.self, NavigationItemRow.self, TextRow.self, TextWithButtonRow.self, PluginHeaderRow.self, LinkRow.self, ExpandableRow.self]
    }
}
