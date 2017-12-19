import Foundation
import UIDeviceIdentifier
import WordPressShared

/// The purpose of this class is to encapsulate all of the interaction with the Notifications REST endpoints.
/// Here we'll deal mostly with the Settings / Push Notifications API.
///
open class NotificationSettingsServiceRemote: ServiceRemoteWordPressComREST {
    /// Designated Initializer. Fails if the remoteApi is nil.
    ///
    /// - Parameter wordPressComRestApi: A Reference to the WordPressComRestApi that should be used to interact with WordPress.com
    ///
    public override init?(wordPressComRestApi: WordPressComRestApi!) {
        super.init(wordPressComRestApi: wordPressComRestApi)
        if wordPressComRestApi == nil {
            return nil
        }
    }


    /// Retrieves all of the Notification Settings
    ///
    /// - Parameters:
    ///     - deviceId: The ID of the current device. Can be nil.
    ///     - success: A closure to be called on success, which will receive the parsed settings entities.
    ///     - failure: Optional closure to be called on failure. Will receive the error that was encountered.
    ///
    open func getAllSettings(_ deviceId: String, success: (([RemoteNotificationSettings]) -> Void)?, failure: ((NSError?) -> Void)?) {
        let path = String(format: "me/notifications/settings/?device_id=%@", deviceId)
        let requestUrl = self.path(forEndpoint: path, withVersion: ._1_1)

        wordPressComRestApi.GET(requestUrl!,
            parameters: nil,
            success: { (response: AnyObject, httpResponse: HTTPURLResponse?) -> Void in
                let settings = RemoteNotificationSettings.fromDictionary(response as? NSDictionary)
                success?(settings)
            },
            failure: { (error: NSError, httpResponse: HTTPURLResponse?) -> Void in
                failure?(error)
            })
    }


    /// Updates the specified Notification Settings
    ///
    /// - Parameters:
    ///     - settings: The complete (or partial) dictionary of settings to be updated.
    ///     - success: Optional closure to be called on success.
    ///     - failure: Optional closure to be called on failure.
    ///
    @objc open func updateSettings(_ settings: [String: AnyObject], success: (() -> ())?, failure: ((NSError?) -> Void)?) {
        let path = String(format: "me/notifications/settings/")
        let requestUrl = self.path(forEndpoint: path, withVersion: ._1_1)

        let parameters = settings

        wordPressComRestApi.POST(requestUrl!,
            parameters: parameters,
            success: { (response: AnyObject, httpResponse: HTTPURLResponse?) -> Void in
                success?()
            },
            failure: { (error: NSError, httpResponse: HTTPURLResponse?) -> Void in
                failure?(error)
            })
    }


    /// Registers a given Apple Push Token in the WordPress.com Backend.
    ///
    /// - Parameters:
    ///     - token: The token of the device to be registered.
    ///     - pushNotificationAppId: The app id to be registered.
    ///     - success: Optional closure to be called on success.
    ///     - failure: Optional closure to be called on failure.
    ///
    @objc open func registerDeviceForPushNotifications(_ token: String, pushNotificationAppId: String, success: ((_ deviceId: String) -> ())?, failure: ((NSError) -> Void)?) {
        let endpoint = "devices/new"
        let requestUrl = path(forEndpoint: endpoint, withVersion: ._1_1)

        let device = UIDevice.current
        let parameters = [
            "device_token": token,
            "device_family": "apple",
            "app_secret_key": pushNotificationAppId,
            "device_name": device.name,
            "device_model": UIDeviceHardware.platform(),
            "os_version": device.systemVersion,
            "app_version": Bundle.main.bundleVersion(),
            "device_uuid": device.wordPressIdentifier()
        ]

        wordPressComRestApi.POST(requestUrl!,
            parameters: parameters as [String : AnyObject]?,
            success: { (response: AnyObject, httpResponse: HTTPURLResponse?) -> Void in
                if let responseDict = response as? NSDictionary,
                    let rawDeviceId = responseDict.object(forKey: "ID") {
                    // Failsafe: Make sure deviceId is always a string
                    let deviceId = String(format: "\(rawDeviceId)")
                    success?(deviceId)
                } else {
                    let innerError = Error.invalidResponse
                    let outerError = NSError(domain: innerError.domain, code: innerError.code, userInfo: nil)

                    failure?(outerError)
                }
            },
            failure: { (error: NSError, httpResponse: HTTPURLResponse?) -> Void in
                failure?(error)
            })
    }


    /// Unregisters a given DeviceID for Push Notifications
    ///
    /// - Parameters:
    ///     - deviceId: The ID of the device to be unregistered.
    ///     - success: Optional closure to be called on success.
    ///     - failure: Optional closure to be called on failure.
    ///
    @objc open func unregisterDeviceForPushNotifications(_ deviceId: String, success: (() -> ())?, failure: ((NSError) -> Void)?) {
        let endpoint = String(format: "devices/%@/delete", deviceId)
        let requestUrl = path(forEndpoint: endpoint, withVersion: ._1_1)

        wordPressComRestApi.POST(requestUrl!,
            parameters: nil,
            success: { (response: AnyObject!, httpResponse: HTTPURLResponse?) -> Void in
                success?()
            },
            failure: { (error: NSError, httpResponse: HTTPURLResponse?) -> Void in
                failure?(error)
            })
    }



    /// Describes all of the possible errors that might be generated by this class.
    ///
    public enum Error: Int {
        case invalidResponse = -1

        var code: Int {
            return rawValue
        }

        var domain: String {
            return "NotificationSettingsServiceRemote"
        }
    }
}
