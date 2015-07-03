import Foundation


/**
*  @class           NotificationsService
*  @brief           This service encapsulates the Restful API related to WordPress Notifications.
*/

public class NotificationsService : NSObject, LocalCoreDataService
{
    // MARK: - Aliases
    public typealias Channel    = NotificationSettings.Channel
    public typealias Stream     = NotificationSettings.Stream
    
    
    /**
    *  @details     Designated Initializer
    *  @param       managedObjectContext    A Reference to the MOC that should be used to interact with the Core Data Stack.
    */
    public required init(managedObjectContext context: NSManagedObjectContext) {
        managedObjectContext = context
        super.init()
    }
    

    /**
    *  @details     This method will retrieve all of the Notification Settings for the default WordPress.com account
    *  @param       success Closure to be called on success.
    *  @param       failure Closure to be called on failure, with the associated error.
    */
    public func getAllSettings(success: ([NotificationSettings] -> Void)?, failure: (NSError! -> Void)?) {
        let deviceId = NotificationsManager.registeredPushNotificationsDeviceId() ?? String()
        
        notificationsServiceRemote?.getAllSettings(deviceId,
            success: {
                (remote: [RemoteNotificationSettings]) in
                let parsed = self.settingsFromRemote(remote)
                success?(parsed)
            },
            failure: { (error: NSError!) in
                failure?(error)
            })
    }
    
    
    /**
    *  @details     Updates the specified NotificationSettings's Stream, with a collection of new values.
    *  @param       settings    The NotificationSettings to be updated.
    *  @param       stream      Reference to the specific Settings Stream to update.
    *  @param       newValues   The collection of new values to be submited.
    *  @param       success     Closure to be called on success.
    *  @param       failure     Closure to be called on failure, with the associated error.
    */
    public func updateSettings(settings: NotificationSettings, stream: Stream, newValues: [String: Bool], success: (() -> ())?, failure: (NSError! -> Void)?) {
        let remote = remoteFromSettings(newValues, channel: settings.channel, stream: stream)
        
        notificationsServiceRemote?.updateSettings(remote,
            success: {
                success?()
            },
            failure: { (error: NSError!) in
                failure?(error)
            })
    }

    
    /**
    *  @details     Static Helper that will parse RemoteNotificationSettings instances into a collection of
    *               NotificationSettings instances.
    *  @param       remoteSettings  Array of RemoteNotificationSettings
    *  @returns                     An array of NotificationSettings objects
    */
    private func settingsFromRemote(remoteSettings: [RemoteNotificationSettings]) -> [NotificationSettings] {
        var parsed       = [NotificationSettings]()
        let blogMap      = blogService.blogsForAllAccountsById() as? [Int: Blog]
        
        for remoteSetting in remoteSettings {
            let channel  = channelFromRemote(remoteSetting.channel)
            let streams  = streamsFromRemote(remoteSetting.streams)
            let blog     = blogForChannel(channel, blogMap: blogMap)
            let settings = NotificationSettings(channel: channel, streams: streams, blog: blog)
            
            parsed.append(settings)
        }
        
        return parsed
    }
    
    
    /**
    *  @details Helper method to convert RemoteNotificationSettings.Channel into a NotificationSettings.Channel enum.
    *  @param   remote      An instance of the RemoteNotificationSettings.Channel enum
    *  @returns             Instance of NotificationSettings.Channel Enum
    */
    private func channelFromRemote(remote: RemoteNotificationSettings.Channel) -> NotificationSettings.Channel {
        switch remote {
        case let .Site(siteId):
            return .Site(siteId: siteId)
        case .Other:
            return .Other
        case .WordPressCom:
            return .WordPressCom
        }
    }
    
    
    /**
    *  @details Helper method that will parse RemoteNotificationSettings.Stream instances into a collection of
    *           NotificationSettings.Stream instances.
    *  @param   remote      Array of RemoteNotificationSettings.Stream
    *  @returns             An array of NotificationSettings.Stream
    */
    private func streamsFromRemote(remote: [RemoteNotificationSettings.Stream]) -> [NotificationSettings.Stream] {
        var parsed = Array<NotificationSettings.Stream>()
        
        for remoteStream in remote {
            let kind    = remoteStream.kind.rawValue
            let stream  = NotificationSettings.Stream(kind: kind, preferences: remoteStream.preferences)
            parsed.append(stream)
        }
        
        return parsed
    }
    
    
    /**
    *  @details Helper method that filters the Blog associated with a specific Channel, if any.
    *  @param   channel     An instance of the RemoteNotificationSettings.Channel enum
    *  @param   blogMap     A Map of Blog entities, with their BlogID's as keys
    *  @returns             Instance of the associated Blog, if any
    */
    private func blogForChannel(channel: NotificationSettings.Channel, blogMap: [Int : Blog]?) -> Blog? {
        // We reuse a Blog Map by ID, since it's actually one order of magnitude faster than fetching
        // each time.
        switch channel {
        case let .Site(siteId):
            return blogMap?[siteId]
        default:
            return nil
        }
    }
    
    
    /**
    *  @details Transforms a collection of Settings into a format that's the one expected by the backend,
    *           depending on whether the channel is a Site (will post the Site ID), Other or WordPress.com
    *  @param   settings    A collection of the settings that need to be updated
    *  @param   channel     A reference to the Chanel that must be updated
    *  @param   stream      A reference to the Stream that must be updated
    *  @returns             Dictionary of values, as expected by the Backend, for the specified Channel and Stream.
    */
    private func remoteFromSettings(settings: [String: Bool], channel: Channel, stream: Stream) -> [String: AnyObject] {
        // First:
        // Inject the Device Id, if needd, into the Settings Dictionary. Since that's where the backend expects it.
        var updatedSettings = settings as [String: AnyObject]
        
        switch stream.kind {
        case .Device:
            updatedSettings["device_id"] = NotificationsManager.registeredPushNotificationsDeviceId() ?? String()
        default:
            break
        }
        
        // Second:
        // Prepare the Remote Settings Dictionary
        switch channel {
        case let .Site(siteId):
            return [
                "sites": [
                    [   "site_id"               : siteId,
                        stream.kind.rawValue    : updatedSettings
                    ]
                ]
            ]
        case .Other:
            return [
                "other": [
                    stream.kind.rawValue : updatedSettings
                ]
            ]
        case .WordPressCom:
            return [ "wpcom": updatedSettings ]
        }
    }
    
    
    // MARK: - Private Computed Properties
    private var remoteApi : WordPressComApi? {
        let accountService = AccountService(managedObjectContext: managedObjectContext)
        let unwrappedRestApi = accountService.defaultWordPressComAccount()?.restApi
        
        return unwrappedRestApi?.hasCredentials() == true ? unwrappedRestApi! : nil
    }

    private var notificationsServiceRemote : NotificationsServiceRemote? {
        return NotificationsServiceRemote(api: remoteApi)
    }

    private var blogService : BlogService {
        return BlogService(managedObjectContext: managedObjectContext)
    }
    
    // MARK: - Private Internal Properties
    private var managedObjectContext : NSManagedObjectContext
}
