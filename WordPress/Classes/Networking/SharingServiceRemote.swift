import Foundation
import NSObject_SafeExpectations


/// SharingServiceRemote is responsible for wrangling the REST API calls related to
/// publiczice services, publicize connections, and keyring connections.
///
open class SharingServiceRemote: ServiceRemoteWordPressComREST {

    // MARK: - Helper methods

    /// Returns an error message to use is the API returns an unexpected result.
    ///
    /// - Parameter operation: The NSHTTPURLResponse that returned the unexpected result.
    ///
    /// - Returns: An `NSError` object.
    ///
    func errorForUnexpectedResponse(_ httpResponse: HTTPURLResponse?) -> NSError {
        let failureReason = "The request returned an unexpected type."
        let domain = "org.wordpress.sharing-management"
        let code = 0
        var urlString = "unknown"
        if let unwrappedURL = httpResponse?.url?.absoluteString {
            urlString = unwrappedURL
        }
        let userInfo = [
            "requestURL": urlString,
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
    open func getPublicizeServices(_ success: (([RemotePublicizeService]) -> Void)?, failure: ((NSError?) -> Void)?) {
        let endpoint = "meta/external-services"
        let path = self.path(forEndpoint: endpoint, with: .version_1_1)
        let params = ["type": "publicize"]

        wordPressComRestApi.GET(path!,
            parameters: params as [String : AnyObject]?,
            success: { (responseObject: AnyObject, httpResponse: HTTPURLResponse?) in
                guard let onSuccess = success else {
                    return
                }

                guard let responseDict = responseObject as? NSDictionary else {
                    failure?(self.errorForUnexpectedResponse(httpResponse))
                    return
                }

                let responseString = responseObject.description as NSString
                let services = responseDict.forKey(ServiceDictionaryKeys.services) as NSDictionary

                let publicizeServices: [RemotePublicizeService] = services.allKeys.map { (key) -> RemotePublicizeService in
                    let dict = services.forKey(key) as NSDictionary
                    let pub = RemotePublicizeService()

                    pub.connectURL = dict.string(forKey: ServiceDictionaryKeys.connectURL)
                    pub.detail = dict.string(forKey: ServiceDictionaryKeys.description)
                    pub.icon = dict.string(forKey: ServiceDictionaryKeys.icon)
                    pub.serviceID = dict.string(forKey: ServiceDictionaryKeys.ID)
                    pub.jetpackModuleRequired = dict.string(forKey: ServiceDictionaryKeys.jetpackModuleRequired)
                    pub.jetpackSupport = dict.number(forKey: ServiceDictionaryKeys.jetpackSupport).boolValue
                    pub.label = dict.string(forKey: ServiceDictionaryKeys.label)
                    pub.multipleExternalUserIDSupport = dict.number(forKey: ServiceDictionaryKeys.multipleExternalUserIDSupport).boolValue
                    pub.type = dict.string(forKey: ServiceDictionaryKeys.type)

                    // We're not guarenteed to get the right order by inspecting the
                    // response dictionary's keys. Instead, we can check the index
                    // of each service in the response string.
                    pub.order = NSNumber(value: responseString.range(of: pub.serviceID).location)

                    return pub
                }

                onSuccess(publicizeServices)

            },
            failure: { (error: NSError, httpResponse: HTTPURLResponse?) in
                failure?(error)
            })
    }


    /// Fetches the current user's list of keyring connections.
    ///
    /// - Parameters:
    ///     - success: An optional success block accepting an array of `KeyringConnection` objects.
    ///     - failure: An optional failure block accepting an `NSError` argument.
    ///
    open func getKeyringConnections(_ success: (([KeyringConnection]) -> Void)?, failure: ((NSError?) -> Void)?) {
        let endpoint = "me/keyring-connections"
        let path = self.path(forEndpoint: endpoint, with: .version_1_1)

        wordPressComRestApi.GET(path!,
            parameters: nil,
            success: { (responseObject: AnyObject, httpResponse: HTTPURLResponse?) in
                guard let onSuccess = success else {
                    return
                }

                guard let responseDict = responseObject as? NSDictionary else {
                    failure?(self.errorForUnexpectedResponse(httpResponse))
                    return
                }

                let connections: Array = responseDict.array(forKey: ConnectionDictionaryKeys.connections)
                let keyringConnections: [KeyringConnection] = connections.map { (dict) -> KeyringConnection in
                    let conn = KeyringConnection()
                    let dict = dict as AnyObject
                    let externalUsers = dict.array(forKey: ConnectionDictionaryKeys.additionalExternalUsers) ?? []
                    conn.additionalExternalUsers = self.externalUsersForKeyringConnection(externalUsers as NSArray)
                    conn.dateExpires = DateUtils.date(fromISOString: dict.string(forKey: ConnectionDictionaryKeys.expires))
                    conn.dateIssued = DateUtils.date(fromISOString: dict.string(forKey: ConnectionDictionaryKeys.issued))
                    conn.externalDisplay = dict.string(forKey: ConnectionDictionaryKeys.externalDisplay) ?? conn.externalDisplay
                    conn.externalID = dict.string(forKey: ConnectionDictionaryKeys.externalID) ?? conn.externalID
                    conn.externalName = dict.string(forKey: ConnectionDictionaryKeys.externalName) ?? conn.externalName
                    conn.externalProfilePicture = dict.string(forKey: ConnectionDictionaryKeys.externalProfilePicture) ?? conn.externalProfilePicture
                    conn.keyringID = dict.number(forKey: ConnectionDictionaryKeys.ID) ?? conn.keyringID
                    conn.label = dict.string(forKey: ConnectionDictionaryKeys.label) ?? conn.label
                    conn.refreshURL = dict.string(forKey: ConnectionDictionaryKeys.refreshURL) ?? conn.refreshURL
                    conn.status = dict.string(forKey: ConnectionDictionaryKeys.status) ?? conn.status
                    conn.service = dict.string(forKey: ConnectionDictionaryKeys.service) ?? conn.service
                    conn.type = dict.string(forKey: ConnectionDictionaryKeys.type) ?? conn.type
                    conn.userID = dict.number(forKey: ConnectionDictionaryKeys.userID) ?? conn.userID

                    return conn
                }

                onSuccess(keyringConnections)
            },
            failure: { (error: NSError, httpResponse: HTTPURLResponse?) in
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
    fileprivate func externalUsersForKeyringConnection(_ externalUsers: NSArray) -> [KeyringConnectionExternalUser] {
        let arr: [KeyringConnectionExternalUser] = externalUsers.map { (dict) -> KeyringConnectionExternalUser in
            let externalUser = KeyringConnectionExternalUser()
            externalUser.externalID = (dict as AnyObject).string(forKey: ConnectionDictionaryKeys.externalID) ?? externalUser.externalID
            externalUser.externalName = (dict as AnyObject).string(forKey: ConnectionDictionaryKeys.externalName) ?? externalUser.externalName
            externalUser.externalProfilePicture = (dict as AnyObject).string(forKey: ConnectionDictionaryKeys.externalProfilePicture) ?? externalUser.externalProfilePicture
            externalUser.externalCategory = (dict as AnyObject).string(forKey: ConnectionDictionaryKeys.externalCategory) ?? externalUser.externalCategory

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
    open func getPublicizeConnections(_ siteID: NSNumber, success: (([RemotePublicizeConnection]) -> Void)?, failure: ((NSError?) -> Void)?) {
        let endpoint = "sites/\(siteID)/publicize-connections"
        let path = self.path(forEndpoint: endpoint, with: .version_1_1)

        wordPressComRestApi.GET(path!,
            parameters: nil,
            success: { (responseObject: AnyObject, httpResponse: HTTPURLResponse?) in
                guard let onSuccess = success else {
                    return
                }

                guard let responseDict = responseObject as? NSDictionary else {
                    failure?(self.errorForUnexpectedResponse(httpResponse))
                    return
                }

                let connections: Array = responseDict.array(forKey: ConnectionDictionaryKeys.connections)
                let publicizeConnections: [RemotePublicizeConnection] = connections.flatMap { (dict) -> RemotePublicizeConnection? in
                    let conn = self.remotePublicizeConnectionFromDictionary(dict as! NSDictionary)
                    return conn
                }

                onSuccess(publicizeConnections)
            },
            failure: { (error: NSError, httpResponse: HTTPURLResponse?) in
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
    open func createPublicizeConnection(_ siteID: NSNumber,
        keyringConnectionID: NSNumber,
        externalUserID: String?,
        success: ((RemotePublicizeConnection) -> Void)?,
        failure: ((NSError) -> Void)?) {

            let endpoint = "sites/\(siteID)/publicize-connections/new"
            let path = self.path(forEndpoint: endpoint, with: .version_1_1)

            var parameters: [String : AnyObject] = [PublicizeConnectionParams.keyringConnectionID: keyringConnectionID]
            if let userID = externalUserID {
                parameters[PublicizeConnectionParams.externalUserID] = userID as AnyObject?
            }

            wordPressComRestApi.POST(path!,
                parameters: parameters,
                success: { (responseObject: AnyObject, httpResponse: HTTPURLResponse?) in
                    guard let onSuccess = success else {
                        return
                    }

                    guard let responseDict = responseObject as? NSDictionary,
                        let conn = self.remotePublicizeConnectionFromDictionary(responseDict) else {
                        failure?(self.errorForUnexpectedResponse(httpResponse))
                        return
                    }

                    onSuccess(conn)
                },
                failure: { (error: NSError, httpResponse: HTTPURLResponse?) in
                    failure?(error)
            })
    }


    /// Update the shared status of the specified publicize connection
    ///
    /// - Parameters:
    ///     - connectionID: The ID of the publicize connection.
    ///     - externalID: The connection's externalID. Pass `nil` if the keyring
    ///                   connection's default external ID should be used.  Otherwise pass the external
    ///                   ID of one if the keyring connection's `additionalExternalUsers`.
    ///     - siteID: The WordPress.com ID of the site.
    ///     - success: An optional success block accepting no arguments.
    ///     - failure: An optional failure block accepting an `NSError` argument.
    ///
    open func updatePublicizeConnectionWithID(_ connectionID: NSNumber,
        externalID: String?,
        forSite siteID: NSNumber,
        success: ((RemotePublicizeConnection) -> Void)?,
        failure: ((NSError?) -> Void)?) {
            let endpoint = "sites/\(siteID)/publicize-connections/\(connectionID)"
            let path = self.path(forEndpoint: endpoint, with: .version_1_1)
            let externalUserID = (externalID == nil) ? "false" : externalID!

            let parameters = [
                PublicizeConnectionParams.externalUserID: externalUserID
            ]

            wordPressComRestApi.POST(path!,
                parameters: parameters as [String : AnyObject]?,
                success: { (responseObject: AnyObject, httpResponse: HTTPURLResponse?) in
                    guard let onSuccess = success else {
                        return
                    }

                    guard let responseDict = responseObject as? NSDictionary,
                        let conn = self.remotePublicizeConnectionFromDictionary(responseDict) else {
                        failure?(self.errorForUnexpectedResponse(httpResponse))
                        return
                    }

                    onSuccess(conn)
                },
                failure: { (error: NSError, httpResponse: HTTPURLResponse?) in
                    failure?(error)
            })
    }


    /// Update the shared status of the specified publicize connection
    ///
    /// - Parameters:
    ///     - connectionID: The ID of the publicize connection.
    ///     - shared: True if the connection is shared with all users of the blog. False otherwise.
    ///     - siteID: The WordPress.com ID of the site.
    ///     - success: An optional success block accepting no arguments.
    ///     - failure: An optional failure block accepting an `NSError` argument.
    ///
    open func updatePublicizeConnectionWithID(_ connectionID: NSNumber,
        shared: Bool,
        forSite siteID: NSNumber,
        success: ((RemotePublicizeConnection) -> Void)?,
        failure: ((NSError?) -> Void)?) {
            let endpoint = "sites/\(siteID)/publicize-connections/\(connectionID)"
            let path = self.path(forEndpoint: endpoint, with: .version_1_1)
            let parameters = [
                PublicizeConnectionParams.shared: shared
            ]

            wordPressComRestApi.POST(path!,
                parameters: parameters as [String : AnyObject]?,
                success: { (responseObject: AnyObject, httpResponse: HTTPURLResponse?) in
                    guard let onSuccess = success else {
                        return
                    }

                    guard let responseDict = responseObject as? NSDictionary,
                        let conn = self.remotePublicizeConnectionFromDictionary(responseDict) else {
                        failure?(self.errorForUnexpectedResponse(httpResponse))
                        return
                    }

                    onSuccess(conn)
                },
                failure: { (error: NSError, httpResponse: HTTPURLResponse?) in
                    failure?(error)
            })
    }


    /// Disconnects (deletes) the specified publicize connection
    ///
    /// - Parameters:
    ///     - siteID: The WordPress.com ID of the site.
    ///     - connectionID: The ID of the publicize connection.
    ///     - success: An optional success block accepting no arguments.
    ///     - failure: An optional failure block accepting an `NSError` argument.
    ///
    open func deletePublicizeConnection(_ siteID: NSNumber, connectionID: NSNumber, success: (() -> Void)?, failure: ((NSError?) -> Void)?) {
        let endpoint = "sites/\(siteID)/publicize-connections/\(connectionID)/delete"
        let path = self.path(forEndpoint: endpoint, with: .version_1_1)

        wordPressComRestApi.POST(path!,
            parameters: nil,
            success: { (responseObject: AnyObject, httpResponse: HTTPURLResponse?) in
                success?()
            },
            failure: { (error: NSError, httpResponse: HTTPURLResponse?) in
                failure?(error)
        })
    }


    /// Composees a `RemotePublicizeConnection` populated with values from the passed `NSDictionary`
    ///
    /// - Parameter dict: An `NSDictionary` representing a `RemotePublicizeConnection`.
    ///
    /// - Returns: A `RemotePublicizeConnection` object.
    ///
    fileprivate func remotePublicizeConnectionFromDictionary(_ dict: NSDictionary) -> RemotePublicizeConnection? {
        guard let connectionID = dict.number(forKey: ConnectionDictionaryKeys.ID) else {
            return nil
        }

        let conn = RemotePublicizeConnection()
        conn.connectionID = connectionID
        conn.externalDisplay = dict.string(forKey: ConnectionDictionaryKeys.externalDisplay) ?? conn.externalDisplay
        conn.externalID = dict.string(forKey: ConnectionDictionaryKeys.externalID) ?? conn.externalID
        conn.externalName = dict.string(forKey: ConnectionDictionaryKeys.externalName) ?? conn.externalName
        conn.externalProfilePicture = dict.string(forKey: ConnectionDictionaryKeys.externalProfilePicture) ?? conn.externalProfilePicture
        conn.externalProfileURL = dict.string(forKey: ConnectionDictionaryKeys.externalProfileURL) ?? conn.externalProfileURL
        conn.keyringConnectionID = dict.number(forKey: ConnectionDictionaryKeys.keyringConnectionID) ?? conn.keyringConnectionID
        conn.keyringConnectionUserID = dict.number(forKey: ConnectionDictionaryKeys.keyringConnectionUserID) ?? conn.keyringConnectionUserID
        conn.label = dict.string(forKey: ConnectionDictionaryKeys.label) ?? conn.label
        conn.refreshURL = dict.string(forKey: ConnectionDictionaryKeys.refreshURL) ?? conn.refreshURL
        conn.status = dict.string(forKey: ConnectionDictionaryKeys.status) ?? conn.status
        conn.service = dict.string(forKey: ConnectionDictionaryKeys.service) ?? conn.service

        if let expirationDateAsString = dict.string(forKey: ConnectionDictionaryKeys.expires) {
            conn.dateExpires = DateUtils.date(fromISOString: expirationDateAsString)
        }

        if let issueDateAsString = dict.string(forKey: ConnectionDictionaryKeys.issued) {
            conn.dateIssued = DateUtils.date(fromISOString: issueDateAsString)
        }

        if let sharedDictNumber = dict.number(forKey: ConnectionDictionaryKeys.shared) {
            conn.shared = sharedDictNumber.boolValue
        }

        if let siteIDDictNumber = dict.number(forKey: ConnectionDictionaryKeys.siteID) {
            conn.siteID = siteIDDictNumber
        }

        if let userIDDictNumber = dict.number(forKey: ConnectionDictionaryKeys.userID) {
            conn.userID = userIDDictNumber
        }

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
    open func getSharingButtonsForSite(_ siteID: NSNumber, success: (([RemoteSharingButton]) -> Void)?, failure: ((NSError?) -> Void)?) {
        let endpoint = "sites/\(siteID)/sharing-buttons"
        let path = self.path(forEndpoint: endpoint, with: .version_1_1)

        wordPressComRestApi.GET(path!,
            parameters: nil,
            success: { (responseObject: AnyObject, httpResponse: HTTPURLResponse?) in
                guard let onSuccess = success else {
                    return
                }

                guard let responseDict = responseObject as? NSDictionary else {
                    failure?(self.errorForUnexpectedResponse(httpResponse))
                    return
                }

                let buttons = responseDict.array(forKey: SharingButtonsKeys.sharingButtons) as NSArray
                let sharingButtons = self.remoteSharingButtonsFromDictionary(buttons)

                onSuccess(sharingButtons)
            },
            failure: { (error: NSError, httpResponse: HTTPURLResponse?) in
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
    open func updateSharingButtonsForSite(_ siteID: NSNumber, sharingButtons: [RemoteSharingButton], success: (([RemoteSharingButton]) -> Void)?, failure: ((NSError?) -> Void)?) {
        let endpoint = "sites/\(siteID)/sharing-buttons"
        let path = self.path(forEndpoint: endpoint, with: .version_1_1)
        let buttons = dictionariesFromRemoteSharingButtons(sharingButtons)
        let parameters = [SharingButtonsKeys.sharingButtons: buttons]

        wordPressComRestApi.POST(path!,
            parameters: parameters as [String : AnyObject]?,
            success: { (responseObject: AnyObject, httpResponse: HTTPURLResponse?) in
                guard let onSuccess = success else {
                    return
                }

                guard let responseDict = responseObject as? NSDictionary else {
                    failure?(self.errorForUnexpectedResponse(httpResponse))
                    return
                }

                let buttons = responseDict.array(forKey: SharingButtonsKeys.updated) as NSArray
                let sharingButtons = self.remoteSharingButtonsFromDictionary(buttons)

                onSuccess(sharingButtons)
            },
            failure: { (error: NSError, httpResponse: HTTPURLResponse?) in
                failure?(error)
        })
    }


    /// Composees a `RemotePublicizeConnection` populated with values from the passed `NSDictionary`
    ///
    /// - Parameter buttons: An `NSArray` of `NSDictionary`s representing `RemoteSharingButton` objects.
    ///
    /// - Returns: An array of `RemoteSharingButton` objects.
    ///
    fileprivate func remoteSharingButtonsFromDictionary(_ buttons: NSArray) -> [RemoteSharingButton] {
        var order = 0
        let sharingButtons: [RemoteSharingButton] = buttons.map { (dict) -> RemoteSharingButton in
            let btn = RemoteSharingButton()
            btn.buttonID = (dict as AnyObject).string(forKey: SharingButtonsKeys.buttonID) ?? btn.buttonID
            btn.name = (dict as AnyObject).string(forKey: SharingButtonsKeys.name) ?? btn.name
            btn.shortname = (dict as AnyObject).string(forKey: SharingButtonsKeys.shortname) ?? btn.shortname
            if let customDictNumber = (dict as AnyObject).number(forKey: SharingButtonsKeys.custom) {
                btn.custom = customDictNumber.boolValue
            }
            if let enabledDictNumber = (dict as AnyObject).number(forKey: SharingButtonsKeys.enabled) {
                btn.enabled = enabledDictNumber.boolValue
            }
            btn.visibility = (dict as AnyObject).string(forKey: SharingButtonsKeys.visibility) ?? btn.visibility
            btn.order = NSNumber(value: order)
            order += 1

            return btn
        }

        return sharingButtons
    }


    fileprivate func dictionariesFromRemoteSharingButtons(_ buttons: [RemoteSharingButton]) -> [NSDictionary] {
        return buttons.map({ (btn) -> NSDictionary in

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
private struct ServiceDictionaryKeys {
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
private struct ConnectionDictionaryKeys {
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
private struct PublicizeConnectionParams {
    static let keyringConnectionID = "keyring_connection_ID"
    static let externalUserID = "external_user_ID"
    static let shared = "shared"
}


// Names of parameters used in SharingButton requests
private struct SharingButtonsKeys {
    static let sharingButtons = "sharing_buttons"
    static let buttonID = "ID"
    static let name = "name"
    static let shortname = "shortname"
    static let custom = "custom"
    static let enabled = "enabled"
    static let visibility = "visibility"
    static let updated = "updated"
}
