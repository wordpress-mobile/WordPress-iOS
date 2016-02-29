import Foundation
import AFNetworking
import NSObject_SafeExpectations


/// SharingServiceRemote is responsible for wrangling the REST API calls related to
/// publiczice services, publicize connections, and keyring connections.
///
public class SharingServiceRemote : ServiceRemoteREST
{

    // MARK: - Helper methods

    /// Returns an error message to use is the API returns an unexpected result.
    ///
    /// - Parameters: 
    ///     - operation: The AFHTTPRequestOperation that returned the unexpected result.
    ///
    /// - Returns: An `NSError` object.
    ///
    func errorForUnexpectedResponse(operation: AFHTTPRequestOperation) -> NSError {
        let failureReason = "The request returned an unexpected type."
        let domain = "org.wordpress.sharing-management"
        let code = 0
        let userInfo = [
            "requestURL": operation.request.URL!.absoluteString,
            NSLocalizedDescriptionKey: failureReason,
            NSLocalizedFailureReasonErrorKey: failureReason
        ]
        return NSError(domain: domain, code: code, userInfo: userInfo)
    }


    // MARK: - Publicize Related Methods

    /// Fetches the list of Publicize services.
    ///
    /// - Parameters:
    ///     - success: An optional success block accepting an array of `RemotePublicizeService` objects.
    ///     - failure: An optional failure block accepting an `NSError` argument.
    ///
    public func getPublicizeServices(success: ([RemotePublicizeService] -> Void)?, failure: (NSError! -> Void)?) {
        let endpoint = "meta/external-services"
        let path = pathForEndpoint(endpoint, withVersion: ServiceRemoteRESTApiVersion_1_1)
        let params = NSDictionary(object: "publicize", forKey: "type")

        api.GET(path,
            parameters: params,
            success: { (operation: AFHTTPRequestOperation!, response: AnyObject!) in
                guard let onSuccess = success else {
                    return
                }

                // For paranioa, make sure the response is the correct type.
                guard let responseDict = response as? NSDictionary else {
                    failure?(self.errorForUnexpectedResponse(operation))
                    return
                }

                let responseString = operation.responseString! as NSString
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
        let path = pathForEndpoint(endpoint, withVersion: ServiceRemoteRESTApiVersion_1_1)

        api.GET(path,
            parameters: nil,
            success: { (operation: AFHTTPRequestOperation!, response: AnyObject!) in
                guard let onSuccess = success else {
                    return
                }

                // For paranioa, make sure the response is the correct type.
                guard let responseDict = response as? NSDictionary else {
                    failure?(self.errorForUnexpectedResponse(operation))
                    return
                }

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
        let path = pathForEndpoint(endpoint, withVersion: ServiceRemoteRESTApiVersion_1_1)

        api.GET(path,
            parameters: nil,
            success: { (operation: AFHTTPRequestOperation!, response: AnyObject!) in
                guard let onSuccess = success else {
                    return
                }

                // For paranioa, make sure the response is the correct type.
                guard let responseDict = response as? NSDictionary else {
                    failure?(self.errorForUnexpectedResponse(operation))
                    return
                }

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
        success: (RemotePublicizeConnection -> Void)?,
        failure: (NSError! -> Void)?) {

            let endpoint = "sites/\(siteID)/publicize-connections/new"
            let path = pathForEndpoint(endpoint, withVersion: ServiceRemoteRESTApiVersion_1_1)

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

                    // For paranioa, make sure the response is the correct type.
                    guard let responseDict = response as? NSDictionary else {
                        failure?(self.errorForUnexpectedResponse(operation))
                        return
                    }

                    let conn = self.remotePublicizeConnectionFromDictionary(responseDict)

                    onSuccess(conn)
                },
                failure: { (operation: AFHTTPRequestOperation?, error: NSError) in
                    failure?(error)
            })
    }


    /// Update the shared status of the specified publicize connection
    ///
    /// - Parameters:
    ///     - connectionID: The ID of the publicize connection.
    ///     - externalID: The connection's externalID. Pass `nil` if the keyring
    /// connection's default external ID should be used.  Otherwise pass the external
    /// ID of one if the keyring connection's `additionalExternalUsers`.
    ///     - siteID: The WordPress.com ID of the site.
    ///      -success: An optional success block accepting no arguments.
    ///     - failure: An optional failure block accepting an `NSError` argument.
    ///
    public func updatePublicizeConnectionWithID(connectionID: NSNumber,
        externalID: String?,
        forSite siteID: NSNumber,
        success: (RemotePublicizeConnection -> Void)?,
        failure: (NSError! -> Void)?) {
            let endpoint = "sites/\(siteID)/publicize-connections/\(connectionID)"
            let path = self.pathForEndpoint(endpoint, withVersion: ServiceRemoteRESTApiVersion_1_1)
            let externalUserID = (externalID == nil) ? "false" : externalID!

            let parameters = [
                PublicizeConnectionParams.externalUserID : externalUserID
            ]

            api.POST(path,
                parameters: parameters,
                success: { (operation: AFHTTPRequestOperation!, response: AnyObject!) in
                    guard let onSuccess = success else {
                        return
                    }

                    // For paranioa, make sure the response is the correct type.
                    guard let responseDict = response as? NSDictionary else {
                        failure?(self.errorForUnexpectedResponse(operation))
                        return
                    }

                    let conn = self.remotePublicizeConnectionFromDictionary(responseDict)

                    onSuccess(conn)
                },
                failure: { (operation: AFHTTPRequestOperation?, error: NSError) in
                    failure?(error)
            })
    }


    /// Update the shared status of the specified publicize connection
    ///
    /// - Parameters:
    ///     - connectionID: The ID of the publicize connection.
    ///     - shared: True if the connection is shared with all users of the blog. False otherwise.
    ///     - siteID: The WordPress.com ID of the site.
    ///      -success: An optional success block accepting no arguments.
    ///     - failure: An optional failure block accepting an `NSError` argument.
    ///
    public func updatePublicizeConnectionWithID(connectionID: NSNumber,
        shared: Bool,
        forSite siteID: NSNumber,
        success: (RemotePublicizeConnection -> Void)?,
        failure: (NSError! -> Void)?) {
            let endpoint = "sites/\(siteID)/publicize-connections/\(connectionID)"
            let path = self.pathForEndpoint(endpoint, withVersion: ServiceRemoteRESTApiVersion_1_1)
            let parameters = [
                PublicizeConnectionParams.shared : shared
            ]

            api.POST(path,
                parameters: parameters,
                success: { (operation: AFHTTPRequestOperation!, response: AnyObject!) in
                    guard let onSuccess = success else {
                        return
                    }

                    // For paranioa, make sure the response is the correct type.
                    guard let responseDict = response as? NSDictionary else {
                        failure?(self.errorForUnexpectedResponse(operation))
                        return
                    }

                    let conn = self.remotePublicizeConnectionFromDictionary(responseDict)

                    onSuccess(conn)
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
        let path = pathForEndpoint(endpoint, withVersion: ServiceRemoteRESTApiVersion_1_1)

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


    // MARK: - Sharing Button Related Methods

    /// Fetches the list of sharing buttons for a blog.
    ///
    /// - Parameters:
    ///     - siteID: The WordPress.com ID of the site.
    ///     - success: An optional success block accepting an array of `RemoteSharingButton` objects.
    ///     - failure: An optional failure block accepting an `NSError` argument.
    ///
    public func getSharingButtonsForSite(siteID: NSNumber, success: (([RemoteSharingButton]) -> Void)?, failure: (NSError! -> Void)?) {
        let endpoint = "sites/\(siteID)/sharing-buttons"
        let path = pathForEndpoint(endpoint, withVersion: ServiceRemoteRESTApiVersion_1_1)

        api.GET(path,
            parameters: nil,
            success: { (operation: AFHTTPRequestOperation!, response: AnyObject!) in
                guard let onSuccess = success else {
                    return
                }

                // For paranioa, make sure the response is the correct type.
                guard let responseDict = response as? NSDictionary else {
                    failure?(self.errorForUnexpectedResponse(operation))
                    return
                }

                let buttons = responseDict.arrayForKey(SharingButtonsKeys.sharingButtons)
                let sharingButtons = self.remoteSharingButtonsFromDictionary(buttons)

                onSuccess(sharingButtons)
            },
            failure: { (operation: AFHTTPRequestOperation?, error: NSError) in
                failure?(error)
        })
    }


    /// Updates the list of sharing buttons for a blog.
    ///
    /// - Parameters:
    ///     - siteID: The WordPress.com ID of the site.
    ///     - sharingButtons: The list of sharing buttons to update. Should be the full list and in the desired order.
    ///     - success: An optional success block accepting an array of `RemoteSharingButton` objects.
    ///     - failure: An optional failure block accepting an `NSError` argument.
    ///
    public func updateSharingButtonsForSite(siteID: NSNumber, sharingButtons:[RemoteSharingButton], success: (([RemoteSharingButton]) -> Void)?, failure: (NSError! -> Void)?) {
        let endpoint = "sites/\(siteID)/sharing-buttons"
        let path = pathForEndpoint(endpoint, withVersion: ServiceRemoteRESTApiVersion_1_1)
        let buttons = dictionariesFromRemoteSharingButtons(sharingButtons)
        let parameters = [SharingButtonsKeys.sharingButtons : buttons]

        api.POST(path,
            parameters: parameters,
            success: { (operation: AFHTTPRequestOperation!, response: AnyObject!) in
                guard let onSuccess = success else {
                    return
                }

                // For paranioa, make sure the response is the correct type.
                guard let responseDict = response as? NSDictionary else {
                    failure?(self.errorForUnexpectedResponse(operation))
                    return
                }

                let buttons = responseDict.arrayForKey(SharingButtonsKeys.updated)
                let sharingButtons = self.remoteSharingButtonsFromDictionary(buttons)

                onSuccess(sharingButtons)
            },
            failure: { (operation: AFHTTPRequestOperation?, error: NSError) in
                failure?(error)
        })
    }


    /// Composees a `RemotePublicizeConnection` populated with values from the passed `NSDictionary`
    ///
    /// - Parameters:
    ///     - buttons: An `NSArray` of `NSDictionary`s representing `RemoteSharingButton` objects.
    ///
    /// - Returns: An array of `RemoteSharingButton` objects.
    ///
    private func remoteSharingButtonsFromDictionary(buttons: NSArray) -> [RemoteSharingButton] {
        var order = 0;
        let sharingButtons: [RemoteSharingButton] = buttons.map { (let dict) -> RemoteSharingButton in
            let btn = RemoteSharingButton()
            btn.buttonID = dict.stringForKey(SharingButtonsKeys.buttonID) ?? btn.buttonID
            btn.name = dict.stringForKey(SharingButtonsKeys.name) ?? btn.name
            btn.shortname = dict.stringForKey(SharingButtonsKeys.shortname) ?? btn.shortname
            btn.custom = dict.numberForKey(SharingButtonsKeys.custom).boolValue ?? btn.custom
            btn.enabled = dict.numberForKey(SharingButtonsKeys.enabled).boolValue ?? btn.enabled
            btn.visibility = dict.stringForKey(SharingButtonsKeys.visibility) ?? btn.visibility
            btn.order = order
            order += 1

            return btn
        }

        return sharingButtons
    }


    private func dictionariesFromRemoteSharingButtons(buttons: [RemoteSharingButton]) -> [NSDictionary] {
        return buttons.map({ (let btn) -> NSDictionary in

            let dict = NSMutableDictionary()
            dict[SharingButtonsKeys.buttonID] = btn.buttonID
            dict[SharingButtonsKeys.name] = btn.name
            dict[SharingButtonsKeys.shortname] = btn.shortname
            dict[SharingButtonsKeys.custom] = btn.custom
            dict[SharingButtonsKeys.enabled] = btn.enabled
            if let visibility = btn.visibility {
                dict[SharingButtonsKeys.visibility] = visibility
            }

            return dict
        })
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


// Names of parameters passed when creating or updating a publicize connection
private struct PublicizeConnectionParams
{
    static let keyringConnectionID = "keyring_connection_ID"
    static let externalUserID = "external_user_ID"
    static let shared = "shared"
}


// Names of parameters used in SharingButton requests
private struct SharingButtonsKeys
{
    static let sharingButtons = "sharing_buttons"
    static let buttonID = "ID"
    static let name = "name"
    static let shortname = "shortname"
    static let custom = "custom"
    static let enabled = "enabled"
    static let visibility = "visibility"
    static let updated = "updated"
}
