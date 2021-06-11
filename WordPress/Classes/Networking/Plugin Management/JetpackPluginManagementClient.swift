import Foundation
import WordPressKit

class JetpackPluginManagementClient: PluginManagementClient {
    private let siteID: Int
    private let remote: PluginServiceRemote

    required init?(with site: JetpackSiteRef) {
        guard let token = CredentialsService().getOAuthToken(site: site) else {
            return nil
        }

        siteID = site.siteID

        let api = WordPressComRestApi.defaultApi(oAuthToken: token, userAgent: WPUserAgent.wordPress())
        remote = PluginServiceRemote(wordPressComRestApi: api)
    }

    func getPlugins(success: @escaping (SitePlugins) -> Void, failure: @escaping (Error) -> Void) {
        remote.getPlugins(siteID: siteID, success: success, failure: failure)
    }

    func updatePlugin(pluginID: String, success: @escaping (PluginState) -> Void, failure: @escaping (Error) -> Void) {
        remote.updatePlugin(pluginID: pluginID, siteID: siteID, success: success, failure: failure)
    }

    func activatePlugin(pluginID: String, success: @escaping () -> Void, failure: @escaping (Error) -> Void) {
        remote.activatePlugin(pluginID: pluginID, siteID: siteID, success: success, failure: failure)
    }

    func deactivatePlugin(pluginID: String, success: @escaping () -> Void, failure: @escaping (Error) -> Void) {
        remote.deactivatePlugin(pluginID: pluginID, siteID: siteID, success: success, failure: failure)
    }

    func enableAutoupdates(pluginID: String, success: @escaping () -> Void, failure: @escaping (Error) -> Void) {
        remote.enableAutoupdates(pluginID: pluginID, siteID: siteID, success: success, failure: failure)

    }

    func disableAutoupdates(pluginID: String, success: @escaping () -> Void, failure: @escaping (Error) -> Void) {
        remote.disableAutoupdates(pluginID: pluginID, siteID: siteID, success: success, failure: failure)
    }

    func activateAndEnableAutoupdates(pluginID: String, success: @escaping () -> Void, failure: @escaping (Error) -> Void) {
        remote.activateAndEnableAutoupdates(pluginID: pluginID, siteID: siteID, success: success, failure: failure)
    }

    func install(pluginSlug: String, success: @escaping (PluginState) -> Void, failure: @escaping (Error) -> Void) {
        remote.install(pluginSlug: pluginSlug, siteID: siteID, success: success, failure: failure)
    }

    func remove(pluginID: String, success: @escaping () -> Void, failure: @escaping (Error) -> Void) {
        remote.remove(pluginID: pluginID, siteID: siteID, success: success, failure: failure)
    }
}
