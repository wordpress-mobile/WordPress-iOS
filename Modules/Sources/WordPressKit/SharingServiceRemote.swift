import Foundation
import NSObject_SafeExpectations

/// SharingServiceRemote is responsible for wrangling the REST API calls related to
/// sharing buttons.
///
open class SharingServiceRemote: ServiceRemoteWordPressComREST {

    // MARK: - Helper methods

    /// Returns an error message to use is the API returns an unexpected result.
    ///
    /// - Parameter operation: The NSHTTPURLResponse that returned the unexpected result.
    ///
    /// - Returns: An `NSError` object.
    ///
    @objc func errorForUnexpectedResponse(_ httpResponse: HTTPURLResponse?) -> NSError {
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

    // MARK: - Sharing Button Related Methods

    /// Fetches the list of sharing buttons for a blog.
    ///
    /// - Parameters:
    ///     - siteID: The WordPress.com ID of the site.
    ///     - success: An optional success block accepting an array of `RemoteSharingButton` objects.
    ///     - failure: An optional failure block accepting an `NSError` argument.
    ///
    @objc open func getSharingButtonsForSite(
        _ siteID: NSNumber,
        success: (([RemoteSharingButton]) -> Void)?,
        failure: ((NSError?) -> Void)?
    ) {
        let endpoint = "sites/\(siteID)/sharing-buttons"
        let path = self.path(forEndpoint: endpoint, withVersion: ._1_1)

        wordPressComRESTAPI.get(
            path,
            parameters: nil,
            success: { responseObject, httpResponse in
                guard let onSuccess = success else {
                    return
                }

                guard let responseDict = responseObject as? NSDictionary else {
                    failure?(self.errorForUnexpectedResponse(httpResponse))
                    return
                }

                let buttons = responseDict.array(forKey: SharingButtonsKeys.sharingButtons) as? NSArray ?? NSArray()
                let sharingButtons = self.remoteSharingButtonsFromDictionary(buttons)

                onSuccess(sharingButtons)
            },
            failure: { error, _ in
                failure?(error as NSError)
            }
        )
    }

    /// Updates the list of sharing buttons for a blog.
    ///
    /// - Parameters:
    ///     - siteID: The WordPress.com ID of the site.
    ///     - sharingButtons: The list of sharing buttons to update. Should be the full list and in the desired order.
    ///     - success: An optional success block accepting an array of `RemoteSharingButton` objects.
    ///     - failure: An optional failure block accepting an `NSError` argument.
    ///
    @objc open func updateSharingButtonsForSite(
        _ siteID: NSNumber,
        sharingButtons: [RemoteSharingButton],
        success: (([RemoteSharingButton]) -> Void)?,
        failure: ((NSError?) -> Void)?
    ) {
        let endpoint = "sites/\(siteID)/sharing-buttons"
        let path = self.path(forEndpoint: endpoint, withVersion: ._1_1)
        let buttons = dictionariesFromRemoteSharingButtons(sharingButtons)
        let parameters = [SharingButtonsKeys.sharingButtons: buttons]

        wordPressComRESTAPI.post(
            path,
            parameters: parameters as [String: AnyObject]?,
            success: { responseObject, httpResponse in
                guard let onSuccess = success else {
                    return
                }

                guard let responseDict = responseObject as? NSDictionary else {
                    failure?(self.errorForUnexpectedResponse(httpResponse))
                    return
                }

                let buttons = responseDict.array(forKey: SharingButtonsKeys.updated) as? NSArray ?? NSArray()
                let sharingButtons = self.remoteSharingButtonsFromDictionary(buttons)

                onSuccess(sharingButtons)
            },
            failure: { error, _ in
                failure?(error as NSError)
            }
        )
    }

    /// Composes `RemoteSharingButton` objects from the passed `NSArray` of `NSDictionary`s.
    ///
    /// - Parameter buttons: An `NSArray` of `NSDictionary`s representing `RemoteSharingButton` objects.
    ///
    /// - Returns: An array of `RemoteSharingButton` objects.
    ///
    private func remoteSharingButtonsFromDictionary(_ buttons: NSArray) -> [RemoteSharingButton] {
        var order = 0
        let sharingButtons: [RemoteSharingButton] = buttons.map { dict -> RemoteSharingButton in
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

    private func dictionariesFromRemoteSharingButtons(_ buttons: [RemoteSharingButton]) -> [NSDictionary] {
        buttons.map({ btn -> NSDictionary in

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
