import Foundation
import AFNetworking
import NSObject_SafeExpectations


/// SharingServiceRemote is responsible for wrangling the REST API calls related to
/// publiczice services, publicize connections, and keyring connections.
///
public class SharingServiceRemote : ServiceRemoteREST
{

    /// Fetches the list of Publicize services.
    ///
    /// - Parameters:
    ///     - success: An optional success block accepting an array of `RemotePublicizeService` objects.
    ///     - failure: An optional failure block accepting an `NSError` argument.
    ///
    public func getPublicizeServices(success: ([RemotePublicizeService] -> Void)?, failure: (NSError! -> Void)?) {
        let endpoint = "meta/external-services"
        let path = self.pathForEndpoint(endpoint, withVersion: ServiceRemoteRESTApiVersion_1_1)
        let params = NSDictionary(object: "publicize", forKey: "type")

        api.GET(path,
            parameters: params,
            success: { (operation: AFHTTPRequestOperation!, response: AnyObject!) in
                guard let onSuccess = success else {
                    return
                }

                let responseString = operation.responseString! as NSString
                let responseDict = response as! NSDictionary
                let services: NSDictionary = responseDict.dictionaryForKey(ServiceDictionaryKeys.services)

                let publicizeServices: [RemotePublicizeService] = services.allKeys.map { (key) -> RemotePublicizeService in
                    let dict: NSDictionary = services.dictionaryForKey(key)
                    let pub = RemotePublicizeService()

                    pub.connectURL = dict.stringForKey(ServiceDictionaryKeys.connectURL)
                    pub.detail = dict.stringForKey(ServiceDictionaryKeys.description)
                    pub.icon = dict.stringForKey(ServiceDictionaryKeys.icon);
                    pub.serviceID = dict.stringForKey(ServiceDictionaryKeys.ID)
                    pub.jetpackModuleRequired = dict.stringForKey(ServiceDictionaryKeys.jetpackModuleRequired)
                    pub.jetpackSupport = dict.numberForKey(ServiceDictionaryKeys.jetpackSupport).boolValue
                    pub.label = dict.stringForKey(ServiceDictionaryKeys.label)
                    pub.multipleExternalUserIDSupport = dict.numberForKey(ServiceDictionaryKeys.multipleExternalUserIDSupport).boolValue
                    pub.type = dict.stringForKey(ServiceDictionaryKeys.type)

                    // We're not guarenteed to get the right order by inspecting the
                    // response dictionary's keys. Instead, we can check the index
                    // of each service in the response string.
                    pub.order = responseString.rangeOfString(pub.serviceID).location

                    return pub
                }

                onSuccess(publicizeServices)

            },
            failure: { (operation: AFHTTPRequestOperation?, error: NSError) in
                failure?(error)
            })
    }


    /// Fetches the current user's list of keyring connections.
    ///
    /// - Parameters:
    ///     - success: An optional success block accepting an array of `KeyringConnection` objects.
    ///     - failure: An optional failure block accepting an `NSError` argument.
    ///
    public func getKeyringConnections(success: ([KeyringConnection] -> Void)?, failure: (NSError! -> Void)?) {
        let endpoint = "me/keyring-connections"
        let path = self.pathForEndpoint(endpoint, withVersion: ServiceRemoteRESTApiVersion_1_1)

        api.GET(path,
            parameters: nil,
            success: { (operation: AFHTTPRequestOperation!, response: AnyObject!) in
                guard let onSuccess = success else {
                    return
                }

                let responseDict = response as! NSDictionary
                let connections: Array = responseDict.arrayForKey(ConnectionDictionaryKeys.connections)
                let keyringConnections: [KeyringConnection] = connections.map { (let dict) -> KeyringConnection in
                    let conn = KeyringConnection()
                    let externalUsers = dict.arrayForKey(ConnectionDictionaryKeys.additionalExternalUsers) ?? []
                    conn.additionalExternalUsers = self.externalUsersForKeyringConnection(externalUsers)
                    conn.dateExpires = DateUtils.dateFromISOString(dict.stringForKey(ConnectionDictionaryKeys.expires))
                    conn.dateIssued = DateUtils.dateFromISOString(dict.stringForKey(ConnectionDictionaryKeys.issued))
                    conn.externalDisplay = dict.stringForKey(ConnectionDictionaryKeys.externalDisplay) ?? conn.externalDisplay
                    conn.externalID = dict.stringForKey(ConnectionDictionaryKeys.externalID) ?? conn.externalID
                    conn.externalName = dict.stringForKey(ConnectionDictionaryKeys.externalName) ?? conn.externalName
                    conn.externalProfilePicture = dict.stringForKey(ConnectionDictionaryKeys.externalProfilePicture) ?? conn.externalProfilePicture
                    conn.keyringID = dict.numberForKey(ConnectionDictionaryKeys.ID) ?? conn.keyringID
                    conn.label = dict.stringForKey(ConnectionDictionaryKeys.label) ?? conn.label
                    conn.refreshURL = dict.stringForKey(ConnectionDictionaryKeys.refreshURL) ?? conn.refreshURL
                    conn.status = dict.stringForKey(ConnectionDictionaryKeys.status) ?? conn.status
                    conn.service = dict.stringForKey(ConnectionDictionaryKeys.service) ?? conn.service
                    conn.type = dict.stringForKey(ConnectionDictionaryKeys.type) ?? conn.type
                    conn.userID = dict.numberForKey(ConnectionDictionaryKeys.userID) ?? conn.userID

                    return conn
                }

                onSuccess(keyringConnections)
            },
            failure: { (operation: AFHTTPRequestOperation?, error: NSError) in
                failure?(error)
        })
    }


    /// Creates KeyringConnectionExternalUser instances from the past array of 
    /// external user dictionaries.
    ///
    /// - Parameters:
    ///     - externalUsers: An array of NSDictionaries where each NSDictionary represents a KeyringConnectionExternalUser
    ///
    /// - Returns: An array of KeyringConnectionExternalUser instances.
    ///
    private func externalUsersForKeyringConnection(externalUsers: NSArray) -> [KeyringConnectionExternalUser] {
        let arr: [KeyringConnectionExternalUser] = externalUsers.map { (let dict) -> KeyringConnectionExternalUser in
            let externalUser = KeyringConnectionExternalUser()
            externalUser.externalID = dict.stringForKey(ConnectionDictionaryKeys.externalID) ?? externalUser.externalID
            externalUser.externalName = dict.stringForKey(ConnectionDictionaryKeys.externalName) ?? externalUser.externalName
            externalUser.externalProfilePicture = dict.stringForKey(ConnectionDictionaryKeys.externalProfilePicture) ?? externalUser.externalProfilePicture
            externalUser.externalCategory = dict.stringForKey(ConnectionDictionaryKeys.externalCategory) ?? externalUser.externalCategory

            return externalUser
        }
        return arr
    }


    /// Fetches the current user's list of Publicize connections for the specified site's ID.
    ///
    /// - Parameters:
    ///     - siteID: The WordPress.com ID of the site.
    ///     - success: An optional success block accepting an array of `RemotePublicizeConnection` objects.
    ///     - failure: An optional failure block accepting an `NSError` argument.
    ///
    public func getPublicizeConnections(siteID: NSNumber, success: ([RemotePublicizeConnection] -> Void)?, failure: (NSError! -> Void)?) {
        let endpoint = "sites/\(siteID)/publicize-connections"
        let path = self.pathForEndpoint(endpoint, withVersion: ServiceRemoteRESTApiVersion_1_1)

        api.GET(path,
            parameters: nil,
            success: { (operation: AFHTTPRequestOperation!, response: AnyObject!) in
                guard let onSuccess = success else {
                    return
                }

                let responseDict = response as! NSDictionary
                let connections: Array = responseDict.arrayForKey(ConnectionDictionaryKeys.connections)
                let publicizeConnections: [RemotePublicizeConnection] = connections.map { (let dict) -> RemotePublicizeConnection in
                    let conn = self.remotePublicizeConnectionFromDictionary(dict as! NSDictionary)
                    return conn
                }

                onSuccess(publicizeConnections)
            },
            failure: { (operation: AFHTTPRequestOperation?, error: NSError) in
                failure?(error)
        })
    }


    /// Create a new Publicize connection bweteen the specified blog and
    /// the third-pary service represented by the keyring.
    ///
    /// - Parameters:
    ///     - siteID: The WordPress.com ID of the site.
    ///     - keyringConnectionID: The ID of the third-party site's keyring connection.
    ///     - success: An optional success block accepting a `RemotePublicizeConnection` object.
    ///     - failure: An optional failure block accepting an `NSError` argument.
    ///
    public func createPublicizeConnection(siteID: NSNumber,
        keyringConnectionID: NSNumber,
        externalUserID: String?,
        success: (RemotePublicizeConnection -> Void)?, failure: (NSError! -> Void)?)
    {

            let endpoint = "sites/\(siteID)/publicize-connections/new"
            let path = self.pathForEndpoint(endpoint, withVersion: ServiceRemoteRESTApiVersion_1_1)

            let parameters = NSMutableDictionary()
            parameters.setObject(keyringConnectionID, forKey: PublicizeConnectionParams.keyringConnectionID)
            if let userID = externalUserID {
                parameters.setObject(userID, forKey: PublicizeConnectionParams.externalUserID)
            }

            api.POST(path,
                parameters: NSDictionary(dictionary: parameters),
                success: { (operation: AFHTTPRequestOperation!, response: AnyObject!) in
                    guard let onSuccess = success else {
                        return
                    }

                    let dict = response as! NSDictionary
                    let conn = self.remotePublicizeConnectionFromDictionary(dict)

                    onSuccess(conn)
                },
                failure: { (operation: AFHTTPRequestOperation?, error: NSError) in
                    failure?(error)
            })
    }


    /// Update the shared status of the specified publicize connection
    ///
    /// - Parameters:
    ///     - shared: True if the connection is shared with all users of the blog. False otherwise.
    ///     - connectionID: The ID of the publicize connection.
    ///     - siteID: The WordPress.com ID of the site.
    ///      -success: An optional success block accepting no arguments.
    ///     - failure: An optional failure block accepting an `NSError` argument.
    ///
    public func updateShared(shared: Bool,
        forPublicizeConnectionWithID connectionID: NSNumber,
        forSite siteID: NSNumber,
        success: (() -> Void)?,
        failure: (NSError! -> Void)?) {
            let endpoint = "sites/\(siteID)/publicize-connections/\(connectionID)"
            let path = self.pathForEndpoint(endpoint, withVersion: ServiceRemoteRESTApiVersion_1_1)
            let parameters = [ConnectionDictionaryKeys.shared : shared]

            api.POST(path,
                parameters: parameters,
                success: { (operation: AFHTTPRequestOperation!, response: AnyObject!) in
                    success?()
                },
                failure: { (operation: AFHTTPRequestOperation?, error: NSError) in
                    failure?(error)
            })
    }


    /// Disconnects (deletes) the specified publicize connection
    ///
    /// - Parameters:
    ///     - siteID: The WordPress.com ID of the site.
    ///     - connectionID: The ID of the publicize connection.
    ///      -success: An optional success block accepting no arguments.
    ///     - failure: An optional failure block accepting an `NSError` argument.
    ///
    public func deletePublicizeConnection(siteID: NSNumber, connectionID: NSNumber, success: (() -> Void)?, failure: (NSError! -> Void)?) {
        let endpoint = "sites/\(siteID)/publicize-connections/\(connectionID)/delete"
        let path = self.pathForEndpoint(endpoint, withVersion: ServiceRemoteRESTApiVersion_1_1)

        api.POST(path,
            parameters: nil,
            success: { (operation: AFHTTPRequestOperation!, response: AnyObject!) in
                success?()
            },
            failure: { (operation: AFHTTPRequestOperation?, error: NSError) in
                failure?(error)
        })
    }


    /// Composees a `RemotePublicizeConnection` populated with values from the passed `NSDictionary`
    ///
    /// - Parameters:
    ///     - dict: An `NSDictionary` representing a `RemotePublicizeConnection`.
    ///
    /// - Returns: A `RemotePublicizeConnection` object.
    ///
    private func remotePublicizeConnectionFromDictionary(dict:NSDictionary) -> RemotePublicizeConnection {
        let conn = RemotePublicizeConnection()

        conn.connectionID = dict.numberForKey(ConnectionDictionaryKeys.ID) ?? conn.connectionID
        conn.dateExpires = DateUtils.dateFromISOString(dict.stringForKey(ConnectionDictionaryKeys.expires))
        conn.dateIssued = DateUtils.dateFromISOString(dict.stringForKey(ConnectionDictionaryKeys.issued))
        conn.externalDisplay = dict.stringForKey(ConnectionDictionaryKeys.externalDisplay) ?? conn.externalDisplay
        conn.externalID = dict.stringForKey(ConnectionDictionaryKeys.externalID) ?? conn.externalID
        conn.externalName = dict.stringForKey(ConnectionDictionaryKeys.externalName) ?? conn.externalName
        conn.externalProfilePicture = dict.stringForKey(ConnectionDictionaryKeys.externalProfilePicture) ?? conn.externalProfilePicture
        conn.externalProfileURL = dict.stringForKey(ConnectionDictionaryKeys.externalProfileURL) ?? conn.externalProfileURL
        conn.keyringConnectionID = dict.numberForKey(ConnectionDictionaryKeys.keyringConnectionID) ?? conn.keyringConnectionID
        conn.keyringConnectionUserID = dict.numberForKey(ConnectionDictionaryKeys.keyringConnectionUserID) ?? conn.keyringConnectionUserID
        conn.label = dict.stringForKey(ConnectionDictionaryKeys.label) ?? conn.label
        conn.refreshURL = dict.stringForKey(ConnectionDictionaryKeys.refreshURL) ?? conn.refreshURL
        conn.status = dict.stringForKey(ConnectionDictionaryKeys.status) ?? conn.status
        conn.service = dict.stringForKey(ConnectionDictionaryKeys.service) ?? conn.service
        conn.shared = dict.numberForKey(ConnectionDictionaryKeys.shared).boolValue ?? conn.shared
        conn.siteID = dict.numberForKey(ConnectionDictionaryKeys.siteID) ?? conn.siteID
        conn.userID = dict.numberForKey(ConnectionDictionaryKeys.userID) ?? conn.userID

        return conn
    }

}


// Keys for PublicizeService dictionaries
private struct ServiceDictionaryKeys
{
    static let connectURL = "connect_URL"
    static let description = "description"
    static let ID = "ID"
    static let icon = "icon"
    static let jetpackModuleRequired = "jetpack_module_required"
    static let jetpackSupport = "jetpack_support"
    static let label = "label"
    static let multipleExternalUserIDSupport = "multiple_external_user_ID_support"
    static let services = "services"
    static let type = "type"
}


// Keys for both KeyringConnection and PublicizeConnection dictionaries
private struct ConnectionDictionaryKeys
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
    static let externalCategory = "external_category"

    // only PublicizeConnections
    static let externalFollowerCount = "external_follower_count"
    static let externalProfileURL = "external_profile_URL"
    static let keyringConnectionID = "keyring_connection_ID"
    static let keyringConnectionUserID = "keyring_connection_user_ID"
    static let shared = "shared"
    static let siteID = "site_ID"
}


// Names of parameters passed when creating a new publicize connection
private struct PublicizeConnectionParams
{
    static let keyringConnectionID = "keyring_connection_ID"
    static let externalUserID = "external_user_ID"
}

