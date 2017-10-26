import Foundation

class PluginViewModel {
    var plugin: PluginState {
        didSet {
            onModelChange?()
        }
    }
    let capabilities: SitePluginCapabilities
    let service: PluginServiceRemote

    init(plugin: PluginState, capabilities: SitePluginCapabilities, service: PluginServiceRemote) {
        self.plugin = plugin
        self.capabilities = capabilities
        self.service = service
    }

    var onModelChange: (() -> Void)?
    var present: ((UIViewController) -> Void)?

    var tableViewModel: ImmuTable {
        let activeRow = SwitchRow(
            title: NSLocalizedString("Active", comment: "Whether a plugin is active on a site"),
            value: plugin.active,
            onChange: { (active) in
        })
        var autoupdatesRow: ImmuTableRow?
        if capabilities.autoupdate {
            autoupdatesRow = SwitchRow(
                title: NSLocalizedString("Autoupdates", comment: "Whether a plugin has enabled automatic updates"),
                value: plugin.autoupdate,
                onChange: { (autoupdate) in
            })
        }

        var removeRow: ImmuTableRow?
        if capabilities.modify {
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
        let message = NSLocalizedString("Are you sure you want to remove \(plugin.name)?", comment: "Text for the alert to confirm a plugin removal")
        let alert = UIAlertController(
            title: NSLocalizedString("Remove Plugin?", comment: "Title for the alert to confirm a plugin removal"),
            message: message, preferredStyle: .alert)
        alert.addCancelActionWithTitle(NSLocalizedString("Cancel", comment: "Cancel removing a plugin"))
        alert.addDestructiveActionWithTitle(NSLocalizedString("Remove", comment: "Alert button to confirm a plugin to be removed"), handler: { _ in
            // TODO: Remove plugin
        })
        return alert
    }

    var title: String {
        return plugin.name
    }

    static var immutableRows: [ImmuTableRow.Type] {
        return [SwitchRow.self, DestructiveButtonRow.self, NavigationItemRow.self]
    }
}
