import Foundation
import AFNetworking
import UIDeviceIdentifier

/**
*  @class           NotificationsServiceRemote
*  @brief           The purpose of this class is to encapsulate all of the interaction with the Notifications
*                   REST endpoints. Note that Notification Sync'ing itself is handled via Simperium, and
*                   here we'll deal mostly with the Settings / Push Notifications API.
*/

public class NotificationsServiceRemote : ServiceRemoteREST
{
    /**
    *  @details     Designated Initializer. Fails if the remoteApi is nil.
    *  @param       remoteApi   A Reference to the WordPressComApi that should be used to interact with WordPress.com
    */
    public override init?(api: WordPressComApi!) {
        super.init(api: api)
        if api == nil {
            return nil
        }
    }

    
    /**
    *  @details     Retrieves all of the Notification Settings
    *  @param       deviceId    The ID of the current device. Can be nil.
    *  @param       success     A closure to be called on success, which will receive the parsed settings entities.
    *  @param       failure     Optional closure to be called on failure. Will receive the error that was encountered.
    */
    public func getAllSettings(deviceId: String, success: ([RemoteNotificationSettings] -> Void)?, failure: (NSError! -> Void)?) {
        let path = String(format: "me/notifications/settings/?device_id=%@", deviceId)
        let requestUrl = self.pathForEndpoint(path, withVersion: ServiceRemoteRESTApiVersion_1_1)

        api.GET(requestUrl,
            parameters: nil,
            success: { (operation: AFHTTPRequestOperation, response: AnyObject) -> Void in
                let settings = RemoteNotificationSettings.fromDictionary(response as? NSDictionary)
                success?(settings)
            },
            failure: { (operation: AFHTTPRequestOperation?, error: NSError) -> Void in
                failure?(error)
            })
    }
    
    
    /**
    *  @details     Updates the specified Notification Settings
    *  @param       settings    The complete (or partial) dictionary of settings to be updated.
    *  @param       success     Optional closure to be called on success.
    *  @param       failure     Optional closure to be called on failure.
    */
    public func updateSettings(settings: [String: AnyObject], success: (() -> ())?, failure: (NSError! -> Void)?) {
        let path = String(format: "me/notifications/settings/")
        let requestUrl = self.pathForEndpoint(path, withVersion: ServiceRemoteRESTApiVersion_1_1)
        
        let parameters = settings as NSDictionary
        
        api.POST(requestUrl,
            parameters: parameters,
            success: { (operation: AFHTTPRequestOperation, response: AnyObject) -> Void in
                success?()
            },
            failure: { (operation: AFHTTPRequestOperation?, error: NSError) -> Void in
                failure?(error)
            })
    }
    
    
    
    /**
     *  @details     Registers a given Apple Push Token in the WordPress.com Backend.
     *  @param       deviceId    The ID of the device to be registered.
     *  @param       success     Optional closure to be called on success.
     *  @param       failure     Optional closure to be called on failure.
     */
    public func registerDeviceForPushNotifications(token: String, success: ((deviceId: String) -> ())?, failure: (NSError -> Void)?) {
        let endpoint = "devices/new"
        let requestUrl = pathForEndpoint(endpoint, withVersion: ServiceRemoteRESTApiVersion_1_1)

        let device = UIDevice.currentDevice()
        let parameters = [
            "device_token"    : token,
            "device_family"   : "apple",
            "app_secret_key"  : WordPressComApiPushAppId,
            "device_name"     : device.name,
            "device_model"    : UIDeviceHardware.platform(),
            "os_version"      : device.systemVersion,
            "app_version"     : NSBundle.mainBundle().bundleVersion(),
            "device_uuid"     : device.wordPressIdentifier()
        ]
        
        api.POST(requestUrl,
            parameters: parameters,
            success: { (operation: AFHTTPRequestOperation, response: AnyObject) -> Void in
                if let responseDict = response as? NSDictionary,
                    let rawDeviceId = responseDict.objectForKey("ID")
                {
                    // Failsafe: Make sure deviceId is always a string
                    let deviceId = String(format: "\(rawDeviceId)")
                    success?(deviceId: deviceId)
                } else {
                    let innerError = Error.InvalidResponse
                    let outerError = NSError(domain: innerError.domain, code: innerError.code, userInfo: nil)
                    
                    failure?(outerError)
                }
            },
            failure: { (operation: AFHTTPRequestOperation?, error: NSError) -> Void in
                failure?(error)
            })
    }
    
        
    /**
     *  @details     Unregisters a given DeviceID for Push Notifications
     *  @param       deviceId    The ID of the device to be unregistered.
     *  @param       success     Optional closure to be called on success.
     *  @param       failure     Optional closure to be called on failure.
     */
    public func unregisterDeviceForPushNotifications(deviceId: String, success: (() -> ())?, failure: (NSError -> Void)?) {
        let endpoint = String(format: "devices/%@/delete", deviceId)
        let requestUrl = pathForEndpoint(endpoint, withVersion: ServiceRemoteRESTApiVersion_1_1)

        api.POST(requestUrl,
            parameters: nil,
            cancellable: false,
            success: { (operation: AFHTTPRequestOperation!, response: AnyObject!) -> Void in
                success?()
            },
            failure: { (operation: AFHTTPRequestOperation!, error: NSError!) -> Void in
                failure?(error)
            })
    }
    
    
    
    /**
     *  @enum       Describes all of the possible errors that might be generated by this class.
     */
    public enum Error : Int {
        case InvalidResponse = -1
        
        var code : Int {
            return rawValue
        }
        
        var domain : String {
            return "NotificationsServiceRemote"
        }
    }
}
