public class JetpackPluginManagementClient: PluginManagementClient {
    private let siteID: Int
    private let remote: PluginServiceRemote

    public required init?(with siteID: Int, remote: PluginServiceRemote) {
        self.siteID = siteID
        self.remote = remote
    }

    public func getPlugins(success: @escaping (SitePlugins) -> Void, failure: @escaping (Error) -> Void) {
        remote.getPlugins(siteID: siteID, success: success, failure: failure)
    }

    public func updatePlugin(pluginID: String, success: @escaping (PluginState) -> Void, failure: @escaping (Error) -> Void) {
        remote.updatePlugin(pluginID: pluginID, siteID: siteID, success: success, failure: failure)
    }

    public func activatePlugin(pluginID: String, success: @escaping () -> Void, failure: @escaping (Error) -> Void) {
        remote.activatePlugin(pluginID: pluginID, siteID: siteID, success: success, failure: failure)
    }

    public func deactivatePlugin(pluginID: String, success: @escaping () -> Void, failure: @escaping (Error) -> Void) {
        remote.deactivatePlugin(pluginID: pluginID, siteID: siteID, success: success, failure: failure)
    }

    public func enableAutoupdates(pluginID: String, success: @escaping () -> Void, failure: @escaping (Error) -> Void) {
        remote.enableAutoupdates(pluginID: pluginID, siteID: siteID, success: success, failure: failure)

    }

    public func disableAutoupdates(pluginID: String, success: @escaping () -> Void, failure: @escaping (Error) -> Void) {
        remote.disableAutoupdates(pluginID: pluginID, siteID: siteID, success: success, failure: failure)
    }

    public func activateAndEnableAutoupdates(pluginID: String, success: @escaping () -> Void, failure: @escaping (Error) -> Void) {
        remote.activateAndEnableAutoupdates(pluginID: pluginID, siteID: siteID, success: success, failure: failure)
    }

    public func install(pluginSlug: String, success: @escaping (PluginState) -> Void, failure: @escaping (Error) -> Void) {
        remote.install(pluginSlug: pluginSlug, siteID: siteID, success: success, failure: failure)
    }

    public func remove(pluginID: String, success: @escaping () -> Void, failure: @escaping (Error) -> Void) {
        remote.remove(pluginID: pluginID, siteID: siteID, success: success, failure: failure)
    }
}
