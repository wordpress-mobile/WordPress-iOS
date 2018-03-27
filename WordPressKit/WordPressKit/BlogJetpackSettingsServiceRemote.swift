import Foundation
import WordPressShared
import CocoaLumberjack

public class BlogJetpackSettingsServiceRemote: ServiceRemoteWordPressComREST {

    public enum ResponseError: Error {
        case decodingFailure
    }

    /// Fetches the Jetpack settings for the specified site
    ///
    public func getJetpackSettingsForSite(_ siteID: Int, success: @escaping (RemoteBlogJetpackSettings) -> Void, failure: @escaping (Error) -> Void) {
        
        let endpoint = "jetpack-blogs/\(siteID)/rest-api"
        let path = self.path(forEndpoint: endpoint, withVersion: ._1_1)
        let parameters = ["path": "/jetpack/v4/settings"]

        wordPressComRestApi.GET(path!,
                                parameters: parameters as [String : AnyObject]?,
                                success: {
                                    response, _ in
                                    guard let results = response["data"] as? [String: AnyObject],
                                        let remoteSettings = try? self.remoteJetpackSettingsFromDictionary(results) else {
                                        failure(ResponseError.decodingFailure)
                                        return
                                    }
                                    success(remoteSettings)
                                }, failure: {
                                    error, _ in
                                    failure(error)
                                })
    }

    /// Fetches the Jetpack Monitor settings for the specified site
    ///
    public func getJetpackMonitorSettingsForSite(_ siteID: Int, success: @escaping (RemoteBlogJetpackMonitorSettings) -> Void, failure: @escaping (Error) -> Void) {

        let endpoint = "jetpack-blogs/\(siteID)"
        let path = self.path(forEndpoint: endpoint, withVersion: ._1_1)

        wordPressComRestApi.GET(path!,
                                parameters: nil,
                                success: {
                                    response, _ in
                                    guard let results = response["settings"] as? [String: AnyObject],
                                        let remoteMonitorSettings = try? self.remoteJetpackMonitorSettingsFromDictionary(results) else {
                                        failure(ResponseError.decodingFailure)
                                        return
                                    }
                                    success(remoteMonitorSettings)
                                }, failure: {
                                    error, _ in
                                    failure(error)
                                })
    }

    /// Fetches the Jetpack Modules settings for the specified site
    ///
    public func getJetpackModulesSettingsForSite(_ siteID: Int, success: @escaping (RemoteBlogJetpackModulesSettings) -> Void, failure: @escaping (Error) -> Void) {

        let endpoint = "sites/\(siteID)/jetpack/modules"
        let path = self.path(forEndpoint: endpoint, withVersion: ._1_1)

        wordPressComRestApi.GET(path!,
                                parameters: nil,
                                success: {
                                    response, _ in
                                    guard let modules = response["modules"] as? [[String: AnyObject]],
                                        let remoteModulesSettings = try? self.remoteJetpackModulesSettingsFromArray(modules) else {
                                        failure(ResponseError.decodingFailure)
                                        return
                                    }
                                    success(remoteModulesSettings)
                                }, failure: {
                                    error, _ in
                                    failure(error)
                                })
    }

    /// Saves the Jetpack settings for the specified site
    ///
    public func updateJetpackSettingsForSite(_ siteID: Int, settings: RemoteBlogJetpackSettings, success: @escaping () -> Void, failure: @escaping (Error?) -> Void) {

        let dictionary = dictionaryFromJetpackSettings(settings)
        guard let jSONData = try? JSONSerialization.data(withJSONObject: dictionary, options: []),
            let jSONBody = String(data: jSONData, encoding: .ascii) else {
                failure(nil)
                return
        }

        let endpoint = "jetpack-blogs/\(siteID)/rest-api"
        let path = self.path(forEndpoint: endpoint, withVersion: ._1_1)
        let parameters = ["path": "/jetpack/v4/settings",
                          "body": jSONBody,
                          "json": true] as [String : AnyObject]

        wordPressComRestApi.POST(path!,
                                 parameters: parameters,
                                 success: {
                                     _,_  in
                                     success()
                                 }, failure: {
                                     error, _ in
                                     failure(error)
                                 })
    }

    /// Saves the Jetpack Monitor settings for the specified site
    ///
    public func updateJetpackMonitorSettingsForSite(_ siteID: Int, settings: RemoteBlogJetpackMonitorSettings, success: @escaping () -> Void, failure: @escaping (Error) -> Void) {

        let endpoint = "jetpack-blogs/\(siteID)"
        let path = self.path(forEndpoint: endpoint, withVersion: ._1_1)
        let parameters = dictionaryFromJetpackMonitorSettings(settings)

        wordPressComRestApi.POST(path!,
                                 parameters: parameters,
                                 success: {
                                    _,_  in
                                    success()
                                 }, failure: {
                                    error, _ in
                                    failure(error)
                                })
    }

    /// Saves the Jetpack Module active setting for the specified site
    ///
    public func updateJetpackModuleActiveSettingForSite(_ siteID: Int, module: String, active: Bool, success: @escaping () -> Void, failure: @escaping (Error) -> Void) {
        let endpoint = "sites/\(siteID)/jetpack/modules/\(module)"
        let path = self.path(forEndpoint: endpoint, withVersion: ._1_1)
        let parameters = [ModuleOptionKeys.active: active]

        wordPressComRestApi.POST(path!,
                                 parameters: parameters as [String : AnyObject],
                                 success: {
                                     _,_  in
                                     success()
                                 }, failure: {
                                     error, _ in
                                     failure(error)
                                 })
    }

    /// Disconnects Jetpack from a site
    ///
    @objc public func disconnectJetpackFromSite(_ siteID: Int, success: @escaping () -> Void, failure: @escaping (Error) -> Void) {
        let endpoint = "jetpack-blogs/\(siteID)/mine/delete"
        let path = self.path(forEndpoint: endpoint, withVersion: ._1_1)

        wordPressComRestApi.POST(path!,
                                 parameters: nil,
                                 success: {
                                     _,_  in
                                     success()
                                 }, failure: {
                                     error, _ in
                                     failure(error)
                                 })
    }

}

private extension BlogJetpackSettingsServiceRemote {

    func remoteJetpackSettingsFromDictionary(_ dictionary: [String: AnyObject]) throws -> RemoteBlogJetpackSettings {

        guard let monitorEnabled = dictionary[Keys.monitorEnabled] as? Bool,
            let blockMaliciousLoginAttempts = dictionary[Keys.blockMaliciousLoginAttempts] as? Bool,
            let whitelistedIPs = dictionary[Keys.whiteListedIPAddresses]?[Keys.whiteListedIPsLocal] as? Array<String>,
            let ssoEnabled = dictionary[Keys.ssoEnabled] as? Bool,
            let ssoMatchAccountsByEmail = dictionary[Keys.ssoMatchAccountsByEmail] as? Bool,
            let ssoRequireTwoStepAuthentication = dictionary[Keys.ssoRequireTwoStepAuthentication] as? Bool else {
                throw ResponseError.decodingFailure
        }

        return RemoteBlogJetpackSettings(monitorEnabled: monitorEnabled,
                                         blockMaliciousLoginAttempts: blockMaliciousLoginAttempts,
                                         loginWhiteListedIPAddresses: Set(whitelistedIPs),
                                         ssoEnabled: ssoEnabled,
                                         ssoMatchAccountsByEmail: ssoMatchAccountsByEmail,
                                         ssoRequireTwoStepAuthentication: ssoRequireTwoStepAuthentication)
    }

    func remoteJetpackMonitorSettingsFromDictionary(_ dictionary: [String: AnyObject]) throws -> RemoteBlogJetpackMonitorSettings {

        guard let monitorEmailNotifications = dictionary[Keys.monitorEmailNotifications] as? Bool,
            let monitorPushNotifications = dictionary[Keys.monitorPushNotifications] as? Bool else {
                throw ResponseError.decodingFailure
        }
        
        return RemoteBlogJetpackMonitorSettings(monitorEmailNotifications: monitorEmailNotifications,
                                                monitorPushNotifications: monitorPushNotifications)
    }

    func remoteJetpackModulesSettingsFromArray(_ modules: [[String: AnyObject]]) throws -> RemoteBlogJetpackModulesSettings {
        let dictionary = modules.reduce(into: [String: [String: AnyObject]]()) {
            guard let key = $1.valueAsString(forKey: "id") else {
                return
            }
            $0[key] = $1
        }

        guard let lazyLoadImagesValue = dictionary[Keys.lazyLoadImages]?[ModuleOptionKeys.active] as? Bool,
            let serveImagesFromOurServersValue = dictionary[Keys.serveImagesFromOurServers]?[ModuleOptionKeys.active] as? Bool else {
            throw ResponseError.decodingFailure
        }

        return RemoteBlogJetpackModulesSettings(lazyLoadImages: lazyLoadImagesValue,
                                                serveImagesFromOurServers: serveImagesFromOurServersValue)
    }

    func dictionaryFromJetpackSettings(_ settings: RemoteBlogJetpackSettings) -> [String: AnyObject] {
        let joinedIPs = settings.loginWhiteListedIPAddresses.joined(separator: ", ")
        return [Keys.monitorEnabled: settings.monitorEnabled as AnyObject,
                Keys.blockMaliciousLoginAttempts: settings.blockMaliciousLoginAttempts as AnyObject,
                Keys.whiteListedIPAddresses: joinedIPs as AnyObject,
                Keys.ssoEnabled: settings.ssoEnabled as AnyObject,
                Keys.ssoMatchAccountsByEmail: settings.ssoMatchAccountsByEmail as AnyObject,
                Keys.ssoRequireTwoStepAuthentication: settings.ssoRequireTwoStepAuthentication as AnyObject]

    }

    func dictionaryFromJetpackMonitorSettings(_ settings: RemoteBlogJetpackMonitorSettings) -> [String: AnyObject] {

        return [Keys.monitorEmailNotifications: settings.monitorEmailNotifications as AnyObject,
                Keys.monitorPushNotifications: settings.monitorPushNotifications as AnyObject]
    }
}

public extension BlogJetpackSettingsServiceRemote {

    public enum Keys {

        // RemoteBlogJetpackSettings keys
        public static let monitorEnabled = "monitor"
        public static let blockMaliciousLoginAttempts  = "protect"
        public static let whiteListedIPAddresses = "jetpack_protect_global_whitelist"
        public static let whiteListedIPsLocal = "local"
        public static let ssoEnabled = "sso"
        public static let ssoMatchAccountsByEmail = "jetpack_sso_match_by_email"
        public static let ssoRequireTwoStepAuthentication = "jetpack_sso_require_two_step"

        // RemoteBlogJetpackMonitorSettings keys
        static let monitorEmailNotifications = "email_notifications"
        static let monitorPushNotifications = "wp_note_notifications"

        // RemoteBlogJetpackModuleSettings keys
        public static let lazyLoadImages = "lazy-images"
        public static let serveImagesFromOurServers  = "photon"

    }

    public enum ModuleOptionKeys {

        // Whether or not the module is currently active
        public static let active = "active"

    }
}
