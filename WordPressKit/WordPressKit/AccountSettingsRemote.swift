import Foundation
import WordPressShared
import CocoaLumberjack

public class AccountSettingsRemote: ServiceRemoteWordPressComREST {
    @objc public static let remotes = NSMapTable<AnyObject, AnyObject>(keyOptions: NSPointerFunctions.Options(), valueOptions: NSPointerFunctions.Options.weakMemory)

    /// Returns an AccountSettingsRemote with the given api, reusing a previous
    /// remote if it exists.
    @objc public static func remoteWithApi(_ api: WordPressComRestApi) -> AccountSettingsRemote {
        // We're hashing on the authToken because we don't want duplicate api
        // objects for the same account.
        //
        // In theory this would be taken care of by the fact that the api comes
        // from a WPAccount, and since WPAccount is a managed object Core Data
        // guarantees there's only one of it.
        //
        // However it might be possible that the account gets deallocated and
        // when it's fetched again it would create a different api object.
        // FIXME: not thread safe
        // @koke 2016-01-21
        if let remote = remotes.object(forKey: api) as? AccountSettingsRemote {
            return remote
        } else {
            let remote = AccountSettingsRemote(wordPressComRestApi: api)
            remotes.setObject(remote, forKey: api)
            return remote
        }
    }

    public func getSettings(success: @escaping (AccountSettings) -> Void, failure: @escaping (Error) -> Void) {
        let endpoint = "me/settings"
        let parameters = ["context": "edit"]
        let path = self.path(forEndpoint: endpoint, withVersion: ._1_1)

        wordPressComRestApi.GET(path,
                parameters: parameters as [String : AnyObject]?,
                success: {
                    responseObject, httpResponse in

                    do {
                        let settings = try self.settingsFromResponse(responseObject)
                        success(settings)
                    } catch {
                        failure(error)
                    }
            },
                failure: { error, httpResponse in
                    failure(error)
        })
    }

    public func updateSetting(_ change: AccountSettingsChange, success: @escaping () -> Void, failure: @escaping (Error) -> Void) {
        let endpoint = "me/settings"
        let path = self.path(forEndpoint: endpoint, withVersion: ._1_1)
        let parameters = [fieldNameForChange(change): change.stringValue]

        wordPressComRestApi.POST(path,
            parameters: parameters as [String : AnyObject]?,
            success: {
                responseObject, httpResponse in

                success()
            },
            failure: { error, httpResponse in
                failure(error)
        })
    }

    /// Change the current user's username
    ///
    /// - Parameters:
    ///   - username: the new username
    ///   - success: block for success
    ///   - failure: block for failure
    public func changeUsername(to username: String, success: @escaping () -> Void, failure: @escaping () -> Void) {
        let endpoint = "me/username"
        let action = "none"
        let parameters = ["username": username, "action": action]

        let path = self.path(forEndpoint: endpoint, withVersion: ._1_1)

        wordPressComRestApi.POST(path,
                                 parameters: parameters as [String : AnyObject]?,
                                 success: { responseObject, httpResponse in
                                    success()
                                 },
                                 failure: { error, httpResponse in
                                    failure()
                                 })
    }

    public func suggestUsernames(base: String, finished: @escaping ([String]) -> Void) {
        let endpoint = "wpcom/v2/users/username/suggestions"
        let parameters = ["name": base]

        wordPressComRestApi.GET(endpoint, parameters: parameters as [String: AnyObject]?, success: { (responseObject, httpResponse) in
            guard let response = responseObject as? [String: AnyObject],
                let suggestions = response["suggestions"] as? [String] else {
                finished([])
                return
            }

            finished(suggestions)
        }) { (error, httpResponse) in
            finished([])
        }
    }

    public func updatePassword(_ password: String, success: @escaping () -> Void, failure: @escaping (Error) -> Void) {
        let endpoint = "me/settings"
        let path = self.path(forEndpoint: endpoint, withVersion: ._1_1)
        let parameters = ["password": password]
        
        wordPressComRestApi.POST(path,
                                 parameters: parameters as [String : AnyObject]?,
                                 success: {
                                    responseObject, httpResponse in
                                    success()
        },
                                 failure: { error, httpResponse in
                                    failure(error)
        })
    }
    
    fileprivate func settingsFromResponse(_ responseObject: AnyObject) throws -> AccountSettings {
        guard let
            response = responseObject as? [String: AnyObject],
            let firstName = response["first_name"] as? String,
            let lastName = response["last_name"] as? String,
            let displayName = response["display_name"] as? String,
            let aboutMe = response["description"] as? String,
            let username = response["user_login"] as? String,
            let email = response["user_email"] as? String,
            let emailPendingAddress = response["new_user_email"] as? String?,
            let emailPendingChange = response["user_email_change_pending"] as? Bool,
            let primarySiteID = response["primary_site_ID"] as? Int,
            let webAddress = response["user_URL"] as? String,
            let language = response["language"] as? String else {
                DDLogError("Error decoding me/settings response: \(responseObject)")
                throw ResponseError.decodingFailure
            }

        let aboutMeText = aboutMe.decodingXMLCharacters()

        return AccountSettings(firstName: firstName,
                               lastName: lastName,
                               displayName: displayName,
                               aboutMe: aboutMeText!,
                               username: username,
                               email: email,
                               emailPendingAddress: emailPendingAddress,
                               emailPendingChange: emailPendingChange,
                               primarySiteID: primarySiteID,
                               webAddress: webAddress,
                               language: language)
    }

    fileprivate func fieldNameForChange(_ change: AccountSettingsChange) -> String {
        switch change {
        case .firstName:
            return "first_name"
        case .lastName:
            return "last_name"
        case .displayName:
            return "display_name"
        case .aboutMe:
            return "description"
        case .email:
            return "user_email"
        case .emailRevertPendingChange:
            return "user_email_change_pending"
        case .primarySite:
            return "primary_site_ID"
        case .webAddress:
            return "user_URL"
        case .language:
            return "language"
        }
    }

    enum ResponseError: Error {
        case decodingFailure
    }
}
