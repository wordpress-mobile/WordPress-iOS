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
        var versionRow: ImmuTableRow?
        if let version = plugin.state.version {
            versionRow = TextRow(
                title: NSLocalizedString("Plugin version", comment: "Version of an installed plugin"),
                value: version)
        }

        var availableUpdateRow: ImmuTableRow?
        switch plugin.state.updateState {
        case .updated:
            break
        case .available(let version):
            let message = String(format: NSLocalizedString("Version %@ is available", comment: "Message to show when a new plugin version is available"), version)
            availableUpdateRow = TextWithButtonRow(
                title: message,
                actionLabel: NSLocalizedString("Update", comment: "Button label to update a plugin"),
                action: { [unowned self] (_) in
                    ActionDispatcher.dispatch(PluginAction.update(id: self.plugin.id, site: self.site))
                }
            )
        case .updating(let version):
            let message = String(format: NSLocalizedString("Version %@ is available", comment: "Message to show when a new plugin version is available"), version)
            availableUpdateRow = TextRow(title: message,
                                         value: NSLocalizedString("Updating", comment: "Text to show when a plugin is updating."))
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

        var homeLink: ImmuTableRow?
        if let homeURL = plugin.state.homeURL {
            homeLink = NavigationItemRow(
                title: NSLocalizedString("Plugin homepage", comment: "Link to a plugin's home page"),
                action: { [unowned self] _ in
                    let controller = WebViewControllerFactory.controller(url: homeURL)
                    let navigationController = UINavigationController(rootViewController: controller)
                    self.present?(navigationController)
            })
        }

        return ImmuTable(optionalSections: [
            ImmuTableSection(optionalRows: [
                versionRow,
                availableUpdateRow
                ]),
            ImmuTableSection(optionalRows: [
                activeRow,
                autoupdatesRow
                ]),
            ImmuTableSection(optionalRows: [
                homeLink
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

    var title: String {
        return plugin.name
    }

    static var immutableRows: [ImmuTableRow.Type] {
        return [SwitchRow.self, DestructiveButtonRow.self, NavigationItemRow.self, TextRow.self, TextWithButtonRow.self]
    }
}
