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
        let path = self.path(forEndpoint: endpoint, with: .version_1_1)
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
        let path = self.path(forEndpoint: endpoint, with: .version_1_1)

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

    /// Saves the ONE Jetpack settings for the specified site
    /// Only one, the API would not allow us to do more than one at a time
    ///
    public func updateJetpackSetting(_ siteID: Int, key: String, value: AnyObject, success: @escaping () -> Void, failure: @escaping (Error?) -> Void) {

        let dictionary = [key: value] as [String : AnyObject]

        guard let jSONData = try? JSONSerialization.data(withJSONObject: dictionary, options: []),
            let jSONBody = String(data: jSONData, encoding: .ascii) else {
            failure(nil)
            return
        }

        let endpoint = "jetpack-blogs/\(siteID)/rest-api"
        let path = self.path(forEndpoint: endpoint, with: .version_1_1)
        let parameters = ["path": "/jetpack/v4/settings",
                          "body": jSONBody] as [String : AnyObject]

        wordPressComRestApi.POST(path!,
                                 parameters: parameters as [String : AnyObject],
                                 success: {
                                    _, _ in
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
        let path = self.path(forEndpoint: endpoint, with: .version_1_1)
        let parameters = dictionaryFromJetpackMonitorSettings(settings)

        wordPressComRestApi.POST(path!,
                                 parameters: parameters,
                                 success: {
                                    _, _ in
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

    func dictionaryFromJetpackSettings(_ settings: RemoteBlogJetpackSettings) -> [String: AnyObject] {

        return [Keys.monitorEnabled: settings.monitorEnabled as AnyObject,
                Keys.blockMaliciousLoginAttempts: settings.blockMaliciousLoginAttempts as AnyObject,
                Keys.whiteListedIPAddresses: settings.loginWhiteListedIPAddresses as AnyObject,
                Keys.ssoEnabled: settings.ssoEnabled as AnyObject,
                Keys.ssoMatchAccountsByEmail: settings.ssoEnabled as AnyObject,
                Keys.ssoRequireTwoStepAuthentication: settings.ssoEnabled as AnyObject]

    }

    func dictionaryFromJetpackMonitorSettings(_ settings: RemoteBlogJetpackMonitorSettings) -> [String: AnyObject] {

        return [Keys.monitorEmailNotifications: settings.monitorEmailNotifications as AnyObject,
                Keys.monitorPushNotifications: settings.monitorPushNotifications as AnyObject]
    }
}

public extension BlogJetpackSettingsServiceRemote {

  //  public struct Keys Enum {
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

    }
}
