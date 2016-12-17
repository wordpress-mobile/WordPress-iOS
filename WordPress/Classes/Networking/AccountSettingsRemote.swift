import Foundation

class AccountSettingsRemote: ServiceRemoteWordPressComREST {
    static let remotes = NSMapTable<AnyObject, AnyObject>(keyOptions: NSPointerFunctions.Options(), valueOptions: NSPointerFunctions.Options.weakMemory)

    /// Returns an AccountSettingsRemote with the given api, reusing a previous
    /// remote if it exists.
    static func remoteWithApi(_ api: WordPressComRestApi) -> AccountSettingsRemote {
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
            let remote = AccountSettingsRemote(wordPressComRestApi: api)!
            remotes.setObject(remote, forKey: api)
            return remote
        }
    }

    func getSettings(success: @escaping (AccountSettings) -> Void, failure: @escaping (Error) -> Void) {
        let endpoint = "me/settings"
        let parameters = ["context": "edit"]
        let path = self.path(forEndpoint: endpoint, with: .version_1_1)

        wordPressComRestApi.GET(path!,
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

    func updateSetting(_ change: AccountSettingsChange, success: @escaping () -> Void, failure: @escaping (Error) -> Void) {
        let endpoint = "me/settings"
        let path = self.path(forEndpoint: endpoint, with: .version_1_1)
        let parameters = [fieldNameForChange(change): change.stringValue]

        wordPressComRestApi.POST(path!,
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
                DDLogSwift.logError("Error decoding me/settings response: \(responseObject)")
                throw ResponseError.decodingFailure
        }

        let aboutMeText = aboutMe.stringByDecodingXMLCharacters()

        return AccountSettings(firstName: firstName,
                               lastName: lastName,
                               displayName: displayName,
                               aboutMe: aboutMeText,
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
        case .firstName(_):
            return "first_name"
        case .lastName(_):
            return "last_name"
        case .displayName(_):
            return "display_name"
        case .aboutMe(_):
            return "description"
        case .email(_):
            return "user_email"
        case .emailRevertPendingChange(_):
            return "user_email_change_pending"
        case .primarySite(_):
            return "primary_site_ID"
        case .webAddress(_):
            return "user_URL"
        case .language(_):
            return "language"
        }
    }

    enum ResponseError: Error {
        case decodingFailure
    }
}
