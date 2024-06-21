import Foundation

public protocol PluginManagementClient {
    func getPlugins(success: @escaping (SitePlugins) -> Void, failure: @escaping (Error) -> Void)
    func updatePlugin(pluginID: String, success: @escaping (PluginState) -> Void, failure: @escaping (Error) -> Void)
    func activatePlugin(pluginID: String, success: @escaping () -> Void, failure: @escaping (Error) -> Void)
    func deactivatePlugin(pluginID: String, success: @escaping () -> Void, failure: @escaping (Error) -> Void)
    func enableAutoupdates(pluginID: String, success: @escaping () -> Void, failure: @escaping (Error) -> Void)
    func disableAutoupdates(pluginID: String, success: @escaping () -> Void, failure: @escaping (Error) -> Void)
    func activateAndEnableAutoupdates(pluginID: String, success: @escaping () -> Void, failure: @escaping (Error) -> Void)
    func install(pluginSlug: String, success: @escaping (PluginState) -> Void, failure: @escaping (Error) -> Void)
    func remove(pluginID: String, success: @escaping () -> Void, failure: @escaping (Error) -> Void)
}
