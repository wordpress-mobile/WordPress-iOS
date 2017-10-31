import Foundation

class PluginViewModel {
    var plugin: PluginState {
        didSet {
            onModelChange?()
        }
    }
    let capabilities: SitePluginCapabilities
    let service: PluginServiceRemote
    let siteID: Int

    init(plugin: PluginState, capabilities: SitePluginCapabilities, siteID: Int, service: PluginServiceRemote) {
        self.plugin = plugin
        self.capabilities = capabilities
        self.siteID = siteID
        self.service = service
    }

    var onModelChange: (() -> Void)?
    var present: ((UIViewController) -> Void)?
    var dismiss: (() -> Void)?

    var tableViewModel: ImmuTable {
        var versionRow: ImmuTableRow?
        if let version = plugin.version {
            versionRow = TextRow(
                title: NSLocalizedString("Plugin version", comment: "Version of an installed plugin"),
                value: version)
        }

        var activeRow: ImmuTableRow?
        if plugin.deactivateAllowed {
            activeRow = SwitchRow(
                title: NSLocalizedString("Active", comment: "Whether a plugin is active on a site"),
                value: plugin.active,
                onChange: { [unowned self] (active) in
                    self.setActive(active)
                }
            )
        }

        var autoupdatesRow: ImmuTableRow?
        if capabilities.autoupdate {
            autoupdatesRow = SwitchRow(
                title: NSLocalizedString("Autoupdates", comment: "Whether a plugin has enabled automatic updates"),
                value: plugin.autoupdate,
                onChange: { [unowned self] (autoupdate) in
                    self.setAutoupdate(autoupdate)
                }
            )
        }

        var removeRow: ImmuTableRow?
        if capabilities.modify && plugin.deactivateAllowed {
            removeRow = DestructiveButtonRow(
                title: NSLocalizedString("Remove Plugin", comment: "Button to remove a plugin from a site"),
                action: { [unowned self] _ in
                    let alert = self.confirmRemovalAlert(plugin: self.plugin)
                    self.present?(alert)
                },
                accessibilityIdentifier: "remove-plugin")
        }

        var homeLink: ImmuTableRow?
        if let homeURL = plugin.homeURL {
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
                versionRow
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

    private func confirmRemovalAlert(plugin: PluginState) -> UIAlertController {
        let message: String
        if let siteTitle = getSiteTitle() {
            let messageTemplate = NSLocalizedString("Are you sure you want to remove %1$@ from %2$@? This will deactivate the plugin and delete all associated files and data.", comment: "Text for the alert to confirm a plugin removal. %1$@ is the plugin name, %2$@ is the site title.")
            message = String(format: messageTemplate, plugin.name, siteTitle)
        } else {
            let messageTemplate = NSLocalizedString("Are you sure you want to remove %1$@? This will deactivate the plugin and delete all associated files and data.", comment: "Text for the alert to confirm a plugin removal. %1$@ is the plugin name.")
            message = String(format: messageTemplate, plugin.name)
        }
        let alert = UIAlertController(
            title: NSLocalizedString("Remove Plugin?", comment: "Title for the alert to confirm a plugin removal"),
            message: message, preferredStyle: .alert)
        alert.addCancelActionWithTitle(NSLocalizedString("Cancel", comment: "Cancel removing a plugin"))
        alert.addDestructiveActionWithTitle(
            NSLocalizedString("Remove", comment: "Alert button to confirm a plugin to be removed"),
            handler: { [unowned self] _ in
                self.dismiss?()
                self.service.remove(
                    pluginID: self.plugin.id,
                    siteID: self.siteID,
                    success: {},
                    failure: { error in
                        DDLogError("Error removing plugin: \(error)")
                    })
            }
        )
        return alert
    }

    private func setActive(_ active: Bool) {
        plugin.active = active
        if active {
            service.activatePlugin(
                pluginID: plugin.id,
                siteID: siteID,
                success: { _ in },
                failure: { [weak self] (error) in
                    DDLogError("Error activating plugin: \(error)")
                    self?.plugin.active = !active
            })
        } else {
            service.deactivatePlugin(
                pluginID: plugin.id,
                siteID: siteID,
                success: { _ in },
                failure: { [weak self] (error) in
                    DDLogError("Error deactivating plugin: \(error)")
                    self?.plugin.active = !active
            })
        }
    }

    private func setAutoupdate(_ autoupdate: Bool) {
        plugin.autoupdate = autoupdate
        if autoupdate {
            service.enableAutoupdates(
                pluginID: plugin.id,
                siteID: siteID,
                success: { _ in },
                failure: { [weak self] (error) in
                    DDLogError("Error enabling autoupdates for plugin: \(error)")
                    self?.plugin.autoupdate = !autoupdate
            })
        } else {
            service.disableAutoupdates(
                pluginID: plugin.id,
                siteID: siteID,
                success: { _ in },
                failure: { [weak self] (error) in
                    DDLogError("Error disabling autoupdates for plugin: \(error)")
                    self?.plugin.autoupdate = !autoupdate
            })
        }
    }

    private func getSiteTitle() -> String? {
        let context = ContextManager.sharedInstance().mainContext
        let service = BlogService(managedObjectContext: context)
        let blog = service.blog(byBlogId: siteID as NSNumber)
        return blog?.settings?.name?.nonEmptyString()
    }

    var title: String {
        return plugin.name
    }

    static var immutableRows: [ImmuTableRow.Type] {
        return [SwitchRow.self, DestructiveButtonRow.self, NavigationItemRow.self, TextRow.self]
    }
}
