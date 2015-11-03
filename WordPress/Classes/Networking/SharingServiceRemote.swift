import Foundation

/**
 SharingServiceRemote is responsible for wrangling the REST API calls related to 
 publiczice services, publicize connections, and keyring connections.
*/

@objc public class SharingServiceRemote : ServiceRemoteREST
{

    /**
    *  @brief      Fetches the list of Publicize services.
    *
    *  @param      success     An optional success block accepting an array of `RemotePublicizeService` objects.
    *  @param      failure     An optional failure block accepting an `NSError` argument.
    */
    public func getPublicizeServices(success: ([RemotePublicizeService] -> Void)?, failure: (NSError! -> Void)?) {
        let endpoint = "meta/publicize"
        let path = self.pathForEndpoint(endpoint, withVersion: ServiceRemoteRESTApiVersion_1_1)

        api.GET(path,
            parameters: nil,
            success: { (operation:AFHTTPRequestOperation!, response:AnyObject!) -> Void in
                guard let onSuccess = success else {
                    return
                }

                let responseDict = response as! NSDictionary
                let services:NSDictionary = responseDict.dictionaryForKey(ServiceDictionaryKeys.services)
                var order = 0
                let publicizeServices:[RemotePublicizeService] = services.allKeys.map { (let key) -> RemotePublicizeService in
                    let dict:NSDictionary = services.dictionaryForKey(key)
                    let pub = RemotePublicizeService()

                    pub.order = order
                    pub.connectURL = dict.stringForKey(ServiceDictionaryKeys.connect)
                    pub.detail = dict.stringForKey(ServiceDictionaryKeys.description)
                    pub.icon = dict.stringForKey(ServiceDictionaryKeys.icon)
                    pub.label = dict.stringForKey(ServiceDictionaryKeys.label)
                    pub.noticon = dict.stringForKey(ServiceDictionaryKeys.noticon)
                    pub.service = key as! String

                    order++
                    return pub
                }

                onSuccess(publicizeServices)

            },
            failure: { (operation: AFHTTPRequestOperation!, error: NSError!) -> Void in
                failure?(error)
            })
    }


    /**
    *  @brief      Fetches the current user's list of keyring connections.
    *
    *  @param      success     An optional success block accepting an array of `KeyringConnection` objects.
    *  @param      failure     An optional failure block accepting an `NSError` argument.
    */
    public func getKeyringConnections(success: ([KeyringConnection] -> Void)?, failure: (NSError! -> Void)?) {
        let endpoint = "me/keyring-connections"
        let path = self.pathForEndpoint(endpoint, withVersion: ServiceRemoteRESTApiVersion_1_1)

        api.GET(path,
            parameters: nil,
            success: { (operation:AFHTTPRequestOperation!, response:AnyObject!) -> Void in
                guard let onSuccess = success else {
                    return
                }

                let responseDict = response as! NSDictionary
                let connections:Array = responseDict.arrayForKey(ConnectionDictionaryKeys.connections)
                let keyringConnections:[KeyringConnection] = connections.map { (let dict) -> KeyringConnection in
                    let conn = KeyringConnection()
                    // TODO: Need to see how this guy is formatted.
                    // conn.additionalExternalUsers = dict.arrayForKey(ConnectionDictionaryKeys.additionalExternalUsers)
                    conn.dateExpires = dict.objectForKey(ConnectionDictionaryKeys.expires) as! NSDate
                    conn.dateIssued = dict.objectForKey(ConnectionDictionaryKeys.issued) as! NSDate
                    conn.exteranlDisplay = dict.stringForKey(ConnectionDictionaryKeys.externalDisplay)
                    conn.externalID = dict.stringForKey(ConnectionDictionaryKeys.externalID)
                    conn.externalName = dict.stringForKey(ConnectionDictionaryKeys.externalName)
                    conn.externalProfilePicture = dict.stringForKey(ConnectionDictionaryKeys.externalProfilePicture)
                    conn.keyringID = dict.numberForKey(ConnectionDictionaryKeys.ID)
                    conn.label = dict.stringForKey(ConnectionDictionaryKeys.label)
                    conn.refreshURL = dict.stringForKey(ConnectionDictionaryKeys.refreshURL)
                    conn.status = dict.stringForKey(ConnectionDictionaryKeys.status)
                    conn.service = dict.stringForKey(ConnectionDictionaryKeys.service)
                    conn.type = dict.stringForKey(ConnectionDictionaryKeys.type)
                    conn.userID = dict.numberForKey(ConnectionDictionaryKeys.userID)

                    return conn
                }

                onSuccess(keyringConnections)
            },
            failure: { (operation: AFHTTPRequestOperation!, error: NSError!) -> Void in
                failure?(error)
        })
    }


    /**
     *  @brief      Fetches the current user's list of Publicize connections for the specified site's ID.
     *
     *  @param      siteID      The WordPress.com ID of the site.
     *  @param      success     An optional success block accepting an array of `RemotePublicizeConnection` objects.
     *  @param      failure     An optional failure block accepting an `NSError` argument.
     */
    public func getPublicizeConnections(siteID:NSNumber, success: ([RemotePublicizeConnection] -> Void)?, failure: (NSError! -> Void)?) {
        let endpoint = "sites/\(siteID)/publicize-connections"
        let path = self.pathForEndpoint(endpoint, withVersion: ServiceRemoteRESTApiVersion_1_1)

        api.GET(path,
            parameters: nil,
            success: {[weak self] (operation:AFHTTPRequestOperation!, response:AnyObject!) -> Void in
                guard let strongSelf = self else {
                    return
                }
                guard let onSuccess = success else {
                    return
                }

                let responseDict = response as! NSDictionary
                let connections:Array = responseDict.arrayForKey(ConnectionDictionaryKeys.connections)
                let publicizeConnections:[RemotePublicizeConnection] = connections.map { (let dict) -> RemotePublicizeConnection in
                    let conn = strongSelf.remotePublicizeConnectionFromDictionary(dict as! NSDictionary)
                    return conn
                }

                onSuccess(publicizeConnections)
            },
            failure: { (operation: AFHTTPRequestOperation!, error: NSError!) -> Void in
                failure?(error)
        })
    }


    /**
     *  @brief      Create a new Publicize connection bweteen the specified blog and
     *              the third-pary service represented by the keyring.
     *
     *  @param      siteID                  The WordPress.com ID of the site.
     *  @param      keyringConnectionID     The ID of the third-party site's keyring connection.
     *  @param      success     An optional success block accepting a `RemotePublicizeConnection` object.
     *  @param      failure     An optional failure block accepting an `NSError` argument.
     */
    public func createPublicizeConnection(siteID:NSNumber,
        keyringConnectionID:NSNumber,
        externalUserID:String?,
        success: (RemotePublicizeConnection -> Void)?, failure: (NSError! -> Void)?) {

            let endpoint = "sites/\(siteID)/publicize-connections/new"
            let path = self.pathForEndpoint(endpoint, withVersion: ServiceRemoteRESTApiVersion_1_1)

            let parameters = NSMutableDictionary()
            parameters.setObject(keyringConnectionID, forKey: PublicizeConnectionParams.keyringConnectionID)
            if let userID = externalUserID {
                parameters.setObject(userID, forKey: PublicizeConnectionParams.externalUserID)
            }

            api.POST(path,
                parameters: NSDictionary(dictionary:parameters),
                success: {[weak self] (operation:AFHTTPRequestOperation!, response:AnyObject!) -> Void in
                    guard let strongSelf = self else {
                        return
                    }
                    guard let onSuccess = success else {
                        return
                    }

                    let dict = response as! NSDictionary
                    let conn = strongSelf.remotePublicizeConnectionFromDictionary(dict)

                    onSuccess(conn)
                },
                failure: { (operation: AFHTTPRequestOperation!, error: NSError!) -> Void in
                    failure?(error)
            })
    }


    /**
     *  @brief      Disconnect's (deletes) the specified publicize connection
     *
     *  @param      siteID       The WordPress.com ID of the site.
     *  @param      connectionID The ID of the publicize connection.
     *  @param      success      An optional success block accepting no arguments.
     *  @param      failure      An optional failure block accepting an `NSError` argument.
     */
    public func deletePublicizeConnection(siteID:NSNumber, connectionID:NSNumber, success: (() -> Void)?, failure: (NSError! -> Void)?) {
        let endpoint = "sites/\(siteID)/publicize-connections/\(connectionID)/delete"
        let path = self.pathForEndpoint(endpoint, withVersion: ServiceRemoteRESTApiVersion_1_1)

        api.POST(path,
            parameters: nil,
            success: { (operation:AFHTTPRequestOperation!, response:AnyObject!) -> Void in
                success?()
            },
            failure: { (operation: AFHTTPRequestOperation!, error: NSError!) -> Void in
                failure?(error)
        })
    }

    /**
     *  @brief      Composees a `RemotePublicizeConnection` populated with values from the passed `NSDictionary`
     *
     *  @param      dict    An `NSDictionary` representing a `RemotePublicizeConnection`.
     *
     *  @return     A `RemotePublicizeConnection` object.
     */
    private func remotePublicizeConnectionFromDictionary(dict:NSDictionary) -> RemotePublicizeConnection {
        let conn = RemotePublicizeConnection()

        conn.connectionID = dict.numberForKey(ConnectionDictionaryKeys.ID)
        conn.dateExpires = dict.objectForKey(ConnectionDictionaryKeys.expires) as! NSDate
        conn.dateIssued = dict.objectForKey(ConnectionDictionaryKeys.issued) as! NSDate
        conn.exteranlDisplay = dict.stringForKey(ConnectionDictionaryKeys.externalDisplay)
        conn.externalID = dict.stringForKey(ConnectionDictionaryKeys.externalID)
        conn.externalName = dict.stringForKey(ConnectionDictionaryKeys.externalName)
        conn.externalProfilePicture = dict.stringForKey(ConnectionDictionaryKeys.externalProfilePicture)
        conn.externalProfileURL = dict.stringForKey(ConnectionDictionaryKeys.externalProfileURL)
        conn.keyringConnectionID = dict.numberForKey(ConnectionDictionaryKeys.keyringConnectionID)
        conn.keyringConnectionUserID = dict.numberForKey(ConnectionDictionaryKeys.keyringConnectionUserID)
        conn.label = dict.stringForKey(ConnectionDictionaryKeys.label)
        conn.refreshURL = dict.stringForKey(ConnectionDictionaryKeys.refreshURL)
        conn.status = dict.stringForKey(ConnectionDictionaryKeys.status)
        conn.service = dict.stringForKey(ConnectionDictionaryKeys.service)
        conn.shared = dict.numberForKey(ConnectionDictionaryKeys.shared).boolValue
        conn.siteID = dict.numberForKey(ConnectionDictionaryKeys.siteID)
        conn.userID = dict.numberForKey(ConnectionDictionaryKeys.userID)

        return conn
    }

}


// Keys for PublicizeService dictionaries
struct ServiceDictionaryKeys
{
    static let connect = "connect"
    static let description = "description"
    static let icon = "icon"
    static let label = "label"
    static let noticon = "noticon"
    static let services = "services"
}


// Keys for both KeyringConnection and PublicizeConnection dictionaries
struct ConnectionDictionaryKeys
{
    // shared keys
    static let connections = "connections"
    static let expires = "expires"
    static let externalID = "external_ID"
    static let externalName = "external_name"
    static let externalDisplay = "external_display"
    static let externalProfilePicture = "external_profile_picture"
    static let issued = "issued"
    static let ID = "ID"
    static let label = "label"
    static let refreshURL = "refresh_URL"
    static let service = "service"
    static let sites = "sites"
    static let status = "status"
    static let userID = "user_ID"

    // only KeyringConnections
    static let additionalExternalUsers = "additional_external_users"
    static let type = "type"

    // only PublicizeConnections
    static let externalFollowerCount = "external_follower_count"
    static let externalProfileURL = "external_profile_URL"
    static let keyringConnectionID = "keyring_connection_ID"
    static let keyringConnectionUserID = "keyring_connection_user_ID"
    static let shared = "shared"
    static let siteID = "site_ID"
}


// Names of parameters passed when creating a new publicize connection
struct PublicizeConnectionParams
{
    static let keyringConnectionID = "keyring_connection_ID"
    static let externalUserID = "external_user_ID"
}

